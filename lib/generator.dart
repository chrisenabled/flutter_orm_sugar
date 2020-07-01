import 'dart:io';

import 'package:flutter_mvvm_generator/models/model_metadata.dart';
import 'package:flutter_mvvm_generator/tmpl_generators/entity_class_gen.dart';
import 'package:flutter_mvvm_generator/tmpl_generators/firebase_repo_gen.dart';
import 'package:flutter_mvvm_generator/tmpl_generators/model_class_gen.dart';
import 'package:flutter_mvvm_generator/tmpl_generators/sql_repo_gen.dart';

import 'constants.dart';

bool hasRepoDep(String repoDep) {
  bool hasDep = false;
  if (File(pubspecFile).existsSync()) {
    String content = File(pubspecFile).readAsStringSync();
    if (content.replaceAll(new RegExp(r"\s+"), "").contains(repoDep))
      hasDep = true;
  }
  return hasDep;
}

void generateModelClass(ModelMetadata modelMetadata) {
  String modelString = ModelClassGenerator(modelMetadata).generateClass();
  String path = '$homeFolder${modelMetadata.modelName}/${modelMetadata.modelName}.dart';
  if (File(path).existsSync()) {
    Directory('$homeFolder${modelMetadata.modelName}').deleteSync(recursive: true);
  }
  createFile(path, modelString);
  updateIndexFile(modelMetadata, '${modelMetadata.modelName}.dart');
}

void generateEntityClass(ModelMetadata modelMetadata) {
  String entityString = EntityClassGenerator(modelMetadata)
      .generateClass();
  String path =
      '$homeFolder${modelMetadata.modelName}/${modelMetadata.modelName}Entity.dart';
  createFile(path, entityString);
  updateIndexFile(modelMetadata, '${modelMetadata.modelName}Entity.dart');
}

void generateFirebaseRepositoryClass(ModelMetadata modelMetadata) {
  String modelString = FirebaseRepositoryGenerator(modelMetadata)
      .generateClass();
  String s = modelMetadata.modelName[modelMetadata.modelName.length - 1] != 's'
      ? 's'
      : '';
  String path =
      '$homeFolder${modelMetadata.modelName}/Firebase${modelMetadata.modelName + s}Repository.dart';
  createFile(path, modelString);
  updateIndexFile(
      modelMetadata, 'Firebase${modelMetadata.modelName + s}Repository.dart');
}

void generateSqlRepositoryClass(ModelMetadata modelMetadata) {
  String modelString = SqlRepositoryGenerator(modelMetadata)
      .generateClass();
  String s = modelMetadata.modelName[modelMetadata.modelName.length - 1] != 's'
      ? 's'
      : '';
  String path =
      '$homeFolder${modelMetadata.modelName}/Sql${modelMetadata.modelName + s}Repository.dart';
  createFile(path, modelString);
  updateIndexFile(
      modelMetadata, 'Sql${modelMetadata.modelName + s}Repository.dart');
}

void createFile(path, data) {
  File(path).createSync(recursive: true);
  final File f = File(path);
  f.writeAsStringSync(data);
}

void updateIndexFile(ModelMetadata modelMetadata, classPath) {
  String path = '$homeFolder${modelMetadata.modelName}/index.dart';
  String exportStmt = 'export \'$classPath\';';
  File(path).createSync(recursive: true);
  List<String> contents = File(path).readAsLinesSync();
  if (!contents.contains(exportStmt)) {
    contents.add(exportStmt);
    File(path).writeAsStringSync(contents.join('\n'));
  }
}
