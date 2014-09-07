import 'package:ini/ini.dart';
import 'dart:io';

File file = new File("example/config.ini");

void do_config_things (Config config, String label) {
  print("${label}: loaded config from ${file.path}");
  print('');

  print("${label}: Read some values...");
  print("${label}: ${config.has_option('default', 'default')}");
  print("${label}: ${config.defaults()["default"]}");
  print("${label}: ${config.get("section", "section")}");
  print('');

  print("${label}: Write some values...");
  config.add_section("new");
  config.set("new", "entry", "result");
  print("${label}: Added a new section and entry");
  print('');

  print("${label}: Write out config (to screen)");
  print("${label}: ${config.toString()}");
}

main() {
  file.readAsLines()
    .then(Config.fromStrings)
    .then((Config config) {
      do_config_things(config, "async");
    });

  Config config = Config.fromStrings(file.readAsLinesSync());
  do_config_things(config, "sync");
}
