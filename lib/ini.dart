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

part 'src/model.dart';
part 'src/parser.dart';

abstract class Config implements BackwardsCompatibilityMixin {

  factory Config() {
    return new _ConfigImpl();
  }

  factory Config.fromString(String string) {
    return new _Parser.fromString(string).toConfig();
  }

  factory Config.fromStrings(List<String> strings) {
    return new _Parser.fromStrings(strings).toConfig();
  }

  /// Return the Config content as a parseable string.
  ///
  ///     String reformatted = Config.fromString(original).toString();
  String toString();

  /// Return a dictionary containing the instance-wide defaults.
  ///
  ///     print(config.defaults()["version"]);
  Map<String, String> defaults();

  /// Return a list of the sections available.
  ///
  /// DEFAULT is not included in the list.
  ///
  ///     print(config.sections().first);
  Iterable<String> sections();

  /// Add a new section to the config.
  ///
  /// If a section matching the [name] already exists then a
  /// [DuplicateSectionError] is raised.
  /// If the [name] is DEFAULT (case insensitive) then a [ValueError] is raised.
  ///
  ///     config.addSection("updates");
  void addSection(String name);

  /// Returns true if there is an existing section called [name].
  ///
  /// The DEFAULT section is not acknowledged.
  ///
  ///     if (config.hasSection("updates")) { ... }
  bool hasSection(String name);

  /// Returns a list of options available in the section called [name].
  ///
  ///     print(config.options("updates").first);
  Iterable<String> options(String name);

  /// Returns true if [option] exists within the section called [name].
  ///
  ///     if (config.hasOption("updates", "automatic")) { ... }
  bool hasOption(String name, String option);

  /// Returns the value associated with [option] in the section called [name].
  ///
  ///     print(config.get("updates", "automatic"));
  String get(String name, String option);

  /// Returns a list of option (name, value) pairs in the section called [name].
  ///
  ///     print(config.get("updates").first.first);
  List<List<String>> items(String name);

  /// Sets the [option] to [value] in the section called [name].
  ///
  /// If no section called [name] exists this will raise a [NoSectionError].
  ///
  ///     config.set("updates", "automatic", "true");
  void set(String name, String option, String value);

  /// Remove the [option] from the section called [name].
  ///
  /// If the option existed this will return true.
  /// If no section called [name] exists this will raise a [NoSectionError].
  ///
  ///     config.removeOption("updates", "automatic");
  bool removeOption(String section, String option);

  /// Remove the section called [name].
  ///
  /// If the section existed this will return true.
  ///
  ///     config.removeSection("updates");
  bool removeSection(String section);
}

abstract class BackwardsCompatibilityMixin {

  /// _Deprecated: Use [addSection] instead._
  @Deprecated("2015-03-20")
  void add_section(String section) {
    addSection(section);
  }
  void addSection(String name);

  /// _Deprecated: Use [hasSection] instead._
  @Deprecated("2015-03-20")
  bool has_section(String section) => hasSection(section);
  bool hasSection(String name);

  /// _Deprecated: Use [hasOption] instead._
  @Deprecated("2015-03-20")
  bool has_option(String section, option) => hasOption(section, option);
  bool hasOption(String name, String option);

  /// _Deprecated: Use [removeOption] instead._
  @Deprecated("2015-03-20")
  bool remove_option(String section, option) => removeOption(section, option);
  bool removeOption(String section, String option);

  /// _Deprecated: Use [removeSection] instead._
  @Deprecated("2015-03-20")
  bool remove_section(String section) => removeSection(section);
  bool removeSection(String section);
}

// vim: set ai et sw=2 syntax=dart :
