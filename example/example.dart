import 'package:ini/ini.dart';
import 'dart:io';

File file = new File("example/config.ini");

void doConfigThings(Config config, String label) {
  print("${label}: loaded config from ${file.path}");
  print('');

  print("${label}: Read some values...");
  print("${label}: ${config.hasOption('default', 'default')}");
  print("${label}: ${config.defaults()["default"]}");
  print("${label}: ${config.get("section", "section")}");
  print('');

  print("${label}: Write some values...");
  config.addSection("new");
  config.set("new", "entry", "result");
  print("${label}: Added a new section and entry");
  print('');

  print("${label}: Write out config (to screen)");
  print("${label}: ${config.toString()}");
}

void main() {
  file.readAsLines()
    .then((lines) => new Config.fromStrings(lines))
    .then((Config config) {
      doConfigThings(config, "async");
    });

  Config config = new Config.fromStrings(file.readAsLinesSync());
  doConfigThings(config, "sync");
}

// vim: set ai et sw=2 syntax=dart :
