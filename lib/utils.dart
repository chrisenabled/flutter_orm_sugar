import 'dart:convert';
import 'dart:io';

const String ormFolder = '../lib/orm_module/';
const String ormClassesFolder = ormFolder + 'orm_classes/';
const String ormClassesFile = ormFolder + 'orm_classes/orm_classes.dart';
const String firestoreQueryFile =
    ormClassesFolder + 'firestore_query_executor.dart';
const String ormRepoFolder = ormFolder + 'orm_repositories/';
const String ormModelFolder = ormFolder + 'orm_models/';
const String ormConfigFile = ormFolder + 'config.json';
const String pubspecFile = '../pubspec.yaml';

const String belongsTo = 'BelongsTo';
const String hasOne = 'HasOne';
const String hasMany = 'HasMany';

const String sqlite = 'sqlite';
const String firestore = 'firestore';

const String create = 'Create';
const String edit = 'Edit';
const String delete = 'Delete';
const String buildConf = 'Build Config';

const String addProp = 'Add a Property';
const String deleteProp = 'Delete a Property';
const String addRel = 'Add a Relationship';
const String deleteRel = 'Remove a Relationship';

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

List<String> getModelFiles() {
  if (!Directory(ormModelFolder).existsSync()) return null;
  return Directory(ormModelFolder)
      .listSync()
      .map((e) => e.path.split('/').last)
      .toList();
}

Map getConfigJson() {
  File(ormConfigFile).createSync(recursive: true);
  final config = File(ormConfigFile).readAsStringSync();
  if (['', null].contains(config)) return null;
  return jsonDecode(config) as Map;
}

void saveConfig(String config) {
  File(ormConfigFile).writeAsStringSync(config);
}

Future<void> createFile(path, data, {overwrite: false}) {
  if (!overwrite) {
    return File(path).exists().then((exist) {
      if (!exist)
        return File(path)
            .create(recursive: true)
            .then((file) => file.writeAsString(data));
    });
  }
  return File(path)
      .create(recursive: true)
      .then((file) => file.writeAsString(data));
}

void deleteDir(String path, {onEmptyOnly = true}) {
  if (onEmptyOnly) {
    if (Directory(path).listSync().length == 0)
      return Directory(path).deleteSync();
  } else
    return Directory(path).deleteSync();
  return null;
}

void insertImports(List<String> lines, String import) {
  if (lines.firstWhere((element) => element.contains(import),
          orElse: () => null) ==
      null) {
    lines.insert(2, import);
  }
}
