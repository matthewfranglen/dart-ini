part of ini;

class _Parser {
  static final RegExp _blankLinePattern = new RegExp(r"^\s*$");
  static final RegExp _commentPattern = new RegExp(r"^\s*[;#]");
  static final RegExp _lineContinuationPattern = new RegExp(r"^\s+");
  static final RegExp _sectionPattern = new RegExp(r"^\s*\[(.*\S.*)]\s*$");
  static final RegExp _entryPattern = new RegExp(r"^([^=]+)=(.*?)$");

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

  /// The stream of unparsed data
  List<String> _strings;

  _Parser.fromString(String string)
    : this.fromStrings(new LineSplitter().convert(string));

  _Parser.fromStrings(List<String> strings)
    : _strings =
        _joinLongHeaderFields(
          _removeComments(
            _removeBlankLines(strings)
          )
        );

  /// Returns a Config from the cleaned list of [_strings].
  Config toConfig() {
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

// vim: set ai et sw=2 syntax=dart :
