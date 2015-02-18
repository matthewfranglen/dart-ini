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
        .then((lines) => new Config.fromStrings(lines))
        .then((Config config) => ...);

Write a file:

    new File("config.ini").writeAsString(config.toString());

Read options:

    // List all sections in the configuration, excluding default.
    config.sections();

    // List options within a section
    config.options("default");
    config.options("section");
    config.hasSection("section");

    // List of key value pairs for a section.
    config.items("section");

    // Read specific options.
    config.get("section", "option");
    config.hasOption("section", "option");

Write options:

    // Make sure you add sections before using them.
    config.addSection("section");

    config.set("section", "option", "value");

    config.removeSection("section");

    config.removeOption("section", "option");

There is example code in the example/ directory.
