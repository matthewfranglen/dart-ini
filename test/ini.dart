import 'dart:async';
import 'dart:io';
import "package:ini/ini.dart";
import 'package:unittest/unittest.dart';

List<String> sample_strings = [
  'key',
  'value',
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY0123456789',
  'մնմեմիվնմխיִײַﬠﬡﬢﬣﬤﬥﬦﬧﬨ﬩שׁשׂשּׁשּׂאַאָאּבּגּדּהּוּזּטּיּךּכּלּמּנּסּףּפּצּקּרּשּתּוֹבֿכֿפֿא',
  'ͰͱͲͳʹ͵Ͷͷͻͼͽ;΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϏβθΥϓϔφπϗϘϙϚϛϜϝϞϟϠϡϢϣϤϥϦϧϨϩϪϫϬϭϮϯκρςϳΘε϶ϷϸΣϺϻϼϽϾϿ',
];

/*
   Compares two lists in a consistent way. Needed when there is more than one
   entry in a section, as there is no fixed order for the entries.
*/
void _compare_list (Iterable<T> one, Iterable<T> two, [var compare = null]) {
  expect(
      new List.from(one)..sort(compare),
      equals(new List.from(two)..sort(compare))
    );
}
/*
   Compares the configs based on the getter methods available.
*/
void compare_configs (Config one, Config two) {
  _compare_list(one.sections(), two.sections());
  for (String section in one.sections()) {
    _compare_list(one.items(section), two.items(section));
    _compare_list(one.options(section), two.options(section));

    for (String option in one.options(section)) {
      expect(one.get(section, option), equals(two.get(section, option)));
    }
  }
}

/*
   Returns the process stream as a list of lines. If there is zero output on a
   stream then an empty list will be returned.
*/
Future<String> listen (stream) =>
  stream.transform(new StringDecoder())
        .transform(new LineTransformer())
        .toList();

/*
   Passes the config object through a python script that just reads the config
   from standard in and re-writes it to standard out. This allows compatibility
   with the python version to be checked.
*/
Future<List> compare_python (Config config) =>
  Process.start('python', ['test/ini.py'])
    .then((Process process) {
      process.stdin.write(config.toString());

      return Future.wait([
        process.stdin.close(),
        listen(process.stdout).then((List<String> data) => compare_configs(new Config.fromStrings(data), config)),
        listen(process.stderr).then((List<String> error) => expect(error, equals([])))
      ]);
    });

/*
   This checks that toString and fromString work as advertised
*/
test_self_parsing () {
  var e = (Config config) { compare_configs(new Config.fromString(config.toString()), config); };
  test( 'Test empty', () {
    Config config = new Config();
    e(config);
  });
  test( 'Test default only', () {
    Config config = new Config();

    for (String current in sample_strings) {
      config.set('default', current, current);
    }
    e(config);
  });
  test( 'Test section only', () {
    Config config = new Config();

    for (String current in sample_strings) {
      config.add_section(current);
      config.set(current, current, current);
    }
    e(config);
  });
  test( 'Test all', () {
    Config config = new Config();

    for (String current in sample_strings) {
      config.set('default', current, current);

      config.add_section(current);
      config.set(current, current, current);
    }
    e(config);
  });
}

/*
   This checks that the code conforms with the python implementation.

   Current differences:
    * The handling of the default section is different.
*/
test_python_compliance () {
  var e = (Config config) => compare_python(config);
  test( 'Test empty', () {
    Config config = new Config();
    return e(config);
  });
  test( 'Test section only', () {
    Config config = new Config();

    for (String current in sample_strings) {
      config.add_section(current);
      config.set(current, current.toLowerCase(), current);
    }
    return e(config);
  });

  // TODO: Python does not agree with default section handling
}

main () {
  group( 'Self Parsing', test_self_parsing );
  group( 'Python Parsing', test_python_compliance );
}
