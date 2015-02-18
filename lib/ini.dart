/// This library deals with reading and writing ini files.
///
/// This implements the INI standard,
/// defined [here](https://en.wikipedia.org/wiki/INI_file).
///
/// The ini file reader will return data organized by section and option.
/// The default section will be the blank string.
///
///     new File("config.ini").readAsLines()
///       .then((lines) => new Config.fromStrings(lines))
///       .then((Config config) => ...);

library ini;

import 'dart:convert';

final RegExp _blankLinePattern = new RegExp(r"^\s*$");
final RegExp _commentPattern = new RegExp(r"^\s*[;#]");
final RegExp _lineContinuationPattern = new RegExp(r"^\s+");
final RegExp _sectionPattern = new RegExp(r"^\s*\[(.*\S.*)]\s*$");
final RegExp _entryPattern = new RegExp(r"^([^=]+)=(.*?)$");

class _Parser {
  /// The stream of unparsed data
  List<String> _strings;

  /// The parsed config object
  Config _config;

  static Iterable<String> _removeBlankLines(Iterable<String> source) =>
    source.where((String line) => ! _blankLinePattern.hasMatch(line));

  static Iterable<String> _removeComments(Iterable<String> source) =>
    source.where((String line) => ! _commentPattern.hasMatch(line));

  /// Joins the lines that have been continued over multiple lines.
  ///
  /// Sections and entries can span lines if following lines start with
  /// whitespace. See
  /// [3.1.1. LONG HEADER FIELDS](http://tools.ietf.org/html/rfc822.html#section-3.1.1)
  ///
  ///     return _joinLongHeaderFields(strings);
  static List<String> _joinLongHeaderFields(Iterable<String> source) {
    List<String> result = new List<String>();
    String line = '';

    for (String current in source) {
      if ( _lineContinuationPattern.hasMatch(current) ) {
        // The leading whitespace makes this a long header field.
        // It is not part of the value.
        line += current.replaceFirst(_lineContinuationPattern, "");
      }
      else {
        if ( line != '' ) {
          result.add(line);
        }
        line = current;
      }
    }
    if ( line != '' ) {
      result.add(line);
    }

    return result;
  }

  _Parser.fromString(String string)
    : this.fromStrings(new LineSplitter().convert(string));

  _Parser.fromStrings(List<String> strings)
    : _strings =
        _joinLongHeaderFields(
          _removeComments(
            _removeBlankLines(strings)
          )
        );

  /// The lazily evaluated parsed config.
  get config {
    if ( _config == null ) {
      _config = _parse();
    }
    return _config;
  }

  /// Returns a Config from the cleaned list of [_strings].
  Config _parse() {
    Config result = new Config();
    String section = 'default';

    for (String current in _strings) {
      Match is_section = _sectionPattern.firstMatch(current);
      if ( is_section != null ) {
        section = is_section[1].trim();
        result.addSection(section);
      }
      else {
        Match is_entry = _entryPattern.firstMatch(current);
        if ( is_entry != null ) {
          result.set(section, is_entry[1].trim(), is_entry[2].trim());
        }
        else {
          throw new Exception('Unrecognized line: "${current}"');
        }
      }
    }

    return result;
  }
}

class Config {
  /// All entries that are not within a section.
  Map<String, String> _defaults = new Map<String, String>();

  /// All entries organized by section.
  Map<String, Map<String, String>> _sections =
    new Map<String, Map<String, String>>();

  Config();

  factory Config.fromString(String string) {
    return new _Parser.fromString(string).config;
  }

  factory Config.fromStrings(List<String> strings) {
    return new _Parser.fromStrings(strings).config;
  }

  /// Return the Config content as a parseable string.
  ///
  ///     String reformatted = Config.fromString(original).toString();
  String toString() {
    StringBuffer buffer = new StringBuffer();

    buffer.writeAll(items('default').map((e) => "${e[0]} = ${e[1]}"), "\n");
    buffer.write("\n");
    for (String section in sections()) {
      buffer.write("[${section}]\n");
      buffer.writeAll(items(section).map((e) => "${e[0]} = ${e[1]}"), "\n");
      buffer.write("\n");
    }

    return buffer.toString();
  }

  /// Return a dictionary containing the instance-wide defaults.
  ///
  ///     print(config.defaults()["version"]);
  Map<String, String> defaults() => _defaults;

  /// Return a list of the sections available.
  ///
  /// DEFAULT is not included in the list.
  ///
  ///     print(config.sections().first);
  Iterable<String> sections() => _sections.keys;

  /// Add a new section to the config.
  ///
  /// If a section matching the [name] already exists then a
  /// [DuplicateSectionError] is raised.
  /// If the [name] is DEFAULT (case insensitive) then a [ValueError] is raised.
  ///
  ///     config.addSection("updates");
  void addSection(String name) {
    if ( name.toLowerCase() == 'default' ) {
      throw new Exception('ValueError');
    }
    if ( _sections.containsKey(name) ) {
      throw new Exception('DuplicateSectionError');
    }
    _sections[name] = new Map<String, String>();
  }

  /// Returns true if there is an existing section called [name].
  ///
  /// The DEFAULT section is not acknowledged.
  ///
  ///     if (config.hasSection("updates")) { ... }
  bool hasSection(String name) => _sections.containsKey(name);

  /// Returns a list of options available in the section called [name].
  ///
  ///     print(config.options("updates").first);
  Iterable<String> options(String name) {
    Map<String,String> s = this._getSection(name);
    return s != null ? s.keys : null;
  }

  /// Returns true if [option] exists within the section called [name].
  ///
  ///     if (config.hasOption("updates", "automatic")) { ... }
  bool hasOption(String name, String option) {
    Map<String,String> s = this._getSection(name);
    return s != null ? s.containsKey(option) : false;
  }

  /// Returns the value associated with [option] in the section called [name].
  ///
  ///     print(config.get("updates", "automatic"));
  String get(String name, option) {
    Map<String,String> s = this._getSection(name);
    return s != null ? s[option] : null;
  }

  /// Returns a list of option (name, value) pairs in the section called [name].
  ///
  ///     print(config.get("updates").first.first);
  List<List<String>> items(String name) {
    Map<String,String> s = this._getSection(name);
    return s != null
      ? s.keys.map((String key) => [key, s[key]]).toList()
      : null;
  }

  /// Sets the [option] to [value] in the section called [name].
  ///
  /// If no section called [name] exists this will raise a [NoSectionError].
  ///
  ///     config.set("updates", "automatic", "true");
  void set(String name, String option, String value) {
    Map<String,String> s = this._getSection(name);
    if ( s == null ) {
      throw new Exception('NoSectionError');
    }
    s[option] = value;
  }

  /// Remove the [option] from the section called [name].
  ///
  /// If the option existed this will return true.
  /// If no section called [name] exists this will raise a [NoSectionError].
  ///
  ///     config.removeOption("updates", "automatic");
  bool removeOption(String section, String option) {
    Map<String,String> s = this._getSection(section);
    if ( s != null ) {
      if ( s.containsKey(option) ) {
        s.remove(option);
        return true;
      }
      return false;
    }
    throw new Exception('NoSectionError');
  }

  /// Remove the section called [name].
  ///
  /// If the section existed this will return true.
  ///
  ///     config.removeSection("updates");
  bool removeSection(String section) {
    if ( section.toLowerCase() == 'default' ) {
      // Can't add the default section, so removing is just clearing.
      _defaults.clear();
    }
    if ( _sections.containsKey(section) ) {
      _sections.remove(section);
      return true;
    }
    return false;
  }

  /// Returns the section or null if the section does not exist.
  ///
  /// The string 'default' (case insensitive) will return the default section.
  ///
  ///     print(config._getSection("updates").keys.first);
  Map<String, String> _getSection(String section) {
    if ( section.toLowerCase() == 'default' ) {
      return _defaults;
    }
    if ( _sections.containsKey(section) ) {
      return _sections[section];
    }
    return null;
  }
}

// vim: set ai et sw=2 syntax=dart :
