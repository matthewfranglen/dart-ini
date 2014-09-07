Dart INI
--------

This library deals with reading and writing ini files. This implements the standard as defined here:

https://en.wikipedia.org/wiki/INI_file

The ini file reader will return data organized by section and option. The default section will be the blank string.

Examples
--------

Read a file:

    import "package:ini/ini.dart";

    new File("config.ini").readAsLines()
        .then(Config.fromStrings)
        .then((Config config) => ...);

Write a file:

    new File("config.ini").writeAsString(config.toString());

Read options:

    // List all sections in the configuration, excluding default.
    config.sections();

    // List options within a section
    config.options("default");
    config.options("section");
    config.has_section("section");

    // List of key value pairs for a section.
    config.items("section");

    // Read specific options.
    config.get("section", "option");
    config.has_option("section", "option");

Write options:

    // Make sure you add sections before using them.
    config.add_section("section");

    config.set("section", "option", "value");

    config.remove_section("section");

    config.remove_option("section", "option");

There is example code in the example/ directory.
