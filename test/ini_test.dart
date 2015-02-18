library ini.test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ini/ini.dart';
import 'package:unittest/unittest.dart';

/// This is the path from the folder containing this file to the root of the project
final String rootFolder = '..';

void main () {
  group('', () {
    test('When I call new Config()\n\t Then I get a new blank Config',
      () => when(newConfig).then(isBlankConfig)
    );
    test('When I call new Config.fromString()\n\t Then I get a new populated Config',
      () => when(newConfigFromString).then(isPopulatedConfig)
    );
    test('When I call new Config.fromStrings()\n\t Then I get a new populated Config',
      () => when(newConfigFromStrings).then(isPopulatedConfig)
    );
  });

  group('Given a loaded Config\n\t', () {
    Future<Config> config;

    setUp(() {
      config = given(newConfigFromString);
    });
    test('Then the default options are present',
      () => config.then(defaultOptionsArePresent)
    );
    test('Then the default options are correct',
      () => config.then(defaultOptionsAreCorrect)
    );
    test('Then the sections are present',
      () => config.then(sectionsArePresent)
    );
    test('Then the sections are correct',
      () => config.then(sectionsAreCorrect)
    );
    test('Then the section options are present',
      () => config.then(sectionOptionsArePresent)
    );
    test('Then the section options are correct',
      () => config.then(sectionOptionsAreCorrect)
    );
  });

  group('Given a blank Config\n\t', () {
    Future<Config> config;

    setUp(() {
      config = given(newConfigFromString);
    });
    test('When I add a section\n\t Then the section is present',
      () => config.then(addSection).then(addedSectionIsPresent)
    );
    test('When I add an option\n\t Then the option is present',
      () => config.then(addOption).then(addedOptionIsPresent)
    );
    test('When I add an option\n\t Then the option is correct',
      () => config.then(addOption).then(addedOptionIsCorrect)
    );
    test('When I add a default option\n\t Then the default option is present',
      () => config.then(addDefaultOption).then(addedDefaultOptionIsPresent)
    );
    test('When I add a default option\n\t Then the default option is correct',
      () => config.then(addDefaultOption).then(addedDefaultOptionIsCorrect)
    );
  });

  group('Given a loaded Config\n\t', () {
    Future<Config> config;

    setUp(() {
      config = given(newConfigFromString);
    });
    test('When I create a Config from a toString() call\n\t Then the new Config matches the callee',
      () => config.then(createConfigFromConfigToString).then(bothConfigsMatch)
    );
    test('When I create a Config by passing through python\n\t Then the new Config matches the original',
      () => config.then(createConfigFromPythonEcho).then(bothConfigsMatch)
    );
  });
}

typedef dynamic Clause();

Future<dynamic> given(Clause clause) => new Future.value(clause());
Future<dynamic> when(Clause clause) => new Future.value(clause());

Config newConfig() => new Config();

Config newConfigFromString() => new Config.fromString(sampleConfig);

Config newConfigFromStrings() => new Config.fromStrings(sampleConfigLines);

void isBlankConfig(Config config) {
  expect(config.defaults(), isEmpty);
  expect(config.sections(), isEmpty);
}

void isPopulatedConfig(Config config) {
  expect(config.defaults(), hasLength(greaterThan(0)));
  expect(config.sections(), hasLength(greaterThan(0)));
}

void defaultOptionsArePresent(Config config) {
  expect(config.options('default'), hasLength(1));
  expect(config.options('default'), equals(['default']));
  expect(config.hasOption('default', 'default'), isTrue);
}

void defaultOptionsAreCorrect(Config config) {
  expect(config.get('default', 'default'), equals('value'));
}

void sectionsArePresent(Config config) {
  expect(config.sections(), hasLength(3));
}

void sectionsAreCorrect(Config config) {
  expect(config.sections(), unorderedEquals(['section', 'long section', 'մնմեմ']));
}

void sectionOptionsArePresent(Config config) {
  expect(config.options('section'), hasLength(1));
  expect(config.options('section'), equals(['section']));
  expect(config.hasOption('section', 'section'), isTrue);

  expect(config.options('long section'), hasLength(2));
  expect(config.options('long section'), unorderedEquals(['key', 'long key']));
  expect(config.hasOption('long section', 'key'), isTrue);
  expect(config.hasOption('long section', 'long key'), isTrue);

  expect(config.options('մնմեմ'), hasLength(1));
  expect(config.options('մնմեմ'), equals(['key մնմեմ']));
  expect(config.hasOption('մնմեմ', 'key մնմեմ'), isTrue);
}

void sectionOptionsAreCorrect(Config config) {
  expect(config.get('section', 'section'), equals('other'));
  expect(config.get('long section', 'key'), equals('long value'));
  expect(config.get('long section', 'long key'), equals('value'));
  expect(config.get('մնմեմ', 'key մնմեմ'), equals('value'));
}

Config addSection(Config config) {
  config.addSection("new section");
  return config;
}

Config addOption(Config config) {
  config.addSection("new section");
  config.set("new section", "new option", "new value");
  return config;
}

Config addDefaultOption(Config config) {
  config.set("default", "new default option", "new default value");
  return config;
}

void addedSectionIsPresent(Config config) {
  expect(config.hasSection("new section"), isTrue);
}

void addedOptionIsPresent(Config config) {
  expect(config.hasOption("new section", "new option"), isTrue);
}

void addedOptionIsCorrect(Config config) {
  expect(config.get("new section", "new option"), equals("new value"));
}

void addedDefaultOptionIsPresent(Config config) {
  expect(config.hasOption("default", "new default option"), isTrue);
}

void addedDefaultOptionIsCorrect(Config config) {
  expect(config.get("default", "new default option"), equals("new default value"));
}

List<Config> createConfigFromConfigToString(Config config) =>
  [config, new Config.fromString(config.toString())];

Future<List<Config>> createConfigFromPythonEcho(Config config) {
  // TODO: Resolve difference in handling of default section.
  // Python does not permit sections with no headers.
  // This does, and calls it the default section.

  config.removeSection("default");

  return invokePythonEcho(config).then((String data) => [config, new Config.fromString(data)]);
}

Future<String> invokePythonEcho(Config config) {
  Future<String> listen(stream) =>
    stream.transform(UTF8.decoder)
      .fold('', (String accumulated, String current) => accumulated + current);

  return Process.start('python', ["${rootFolder}/tool/ini_echo.py"])
    .then((Process process) {
      process.stdin.write(config.toString());
      process.stdin.close();

      listen(process.stderr).then(isNoError);
      return listen(process.stdout);
    });
}

Matcher isConfigEqual(Config expected) =>
  predicate((Config result) => result.toString() == expected.toString());

void bothConfigsMatch(List<Config> configs) {
  expect(configs[1], isConfigEqual(configs[0]));
}

void isNoError(String error) {
  expect(error, equals(''));
}

final String sampleConfig = new File("${rootFolder}/test/config.ini").readAsStringSync();
final List<String> sampleConfigLines = new LineSplitter().convert(sampleConfig);

// vim: set ai et sw=2 syntax=dart :
