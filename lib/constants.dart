const String ormFolder = '../lib/orm_module/';
const String ormClassesFolder = ormFolder + 'orm_classes/';
const String ormRepoFolder = ormFolder + 'orm_repositories/';
const String ormModelFolder = ormFolder + 'orm_models/';
const String ormConfigFile = ormFolder + 'config.json';
const String pubspecFile = '../pubspec.yaml';

/// Converts a string to snake_case.
String toSnakeCase(String camelCase) {
  RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
  return camelCase
      .replaceAllMapped(exp, (match) => ('_' + match.group(0)))
      .toLowerCase();
}

/// Converts a string to a camelCase.
String toCamelCase(String snakeCase) {
  RegExp exp = RegExp(r'(_)([a-z])');
  return snakeCase.replaceAllMapped(
      exp, (match) => match.group(2).toUpperCase());
}

/// Converts a string to a camelCase.
String toUpperCamelCase(String someCase) {
  String cc = toCamelCase(someCase);
  return cc[0].toUpperCase() + cc.substring(1);
}
