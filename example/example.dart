import 'package:ini/ini.dart';
import 'dart:io';

main() {
  File file = new File("example/config.ini");
  Config config = Config.readFile(file)
    .then((Config config) {
      print("loaded config from ${file.path}");
      print('');

      print("Read some values...");
      print(config.has_option("default", "default"));
      print(config.defaults()["default"]);
      print(config.get("section", "section"));
      print('');

      print("Write some values...");
      config.add_section("new");
      config.set("new", "entry", "result");
      print("Added a new section and entry");
      print('');

      print("Write out config (to screen)");
      print(config.toString());
    });
}
