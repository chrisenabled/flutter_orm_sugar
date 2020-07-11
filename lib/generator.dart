import 'dart:io';

import 'package:flutter_orm_sugar/models/model_metadata.dart';
import 'package:flutter_orm_sugar/tmpl_generators/entity_class_gen.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_model_gen.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_abs_classes_gen.dart';
import 'package:flutter_orm_sugar/tmpl_generators/sql_repo_gen.dart';

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
  String modelString = OrmModelGenerator(modelMetadata).generateClass();
  String path =
      '$ormFolder${modelMetadata.modelName}/${modelMetadata.modelName}.dart';
  if (File(path).existsSync()) {
    Directory('$ormFolder${modelMetadata.modelName}')
        .deleteSync(recursive: true);
  }
  createFile(path, modelString);
  updateIndexFile(modelMetadata, '${modelMetadata.modelName}.dart');
}

void generateEntityClass(ModelMetadata modelMetadata) {
  String entityString = EntityClassGenerator(modelMetadata)
      .generateClass(hasRepoDep: hasRepoDep(modelMetadata.repository));
  String path =
      '$ormFolder${modelMetadata.modelName}/${modelMetadata.modelName}Entity.dart';
  createFile(path, entityString);
  updateIndexFile(modelMetadata, '${modelMetadata.modelName}Entity.dart');
}

void generateSqlRepositoryClass(ModelMetadata modelMetadata) {
  String modelString = SqlRepositoryGenerator(modelMetadata).generateClass();
  String s = modelMetadata.modelName[modelMetadata.modelName.length - 1] != 's'
      ? 's'
      : '';
  String path =
      '$ormFolder${modelMetadata.modelName}/Sql${modelMetadata.modelName + s}Repository.dart';
  createFile(path, modelString);
  updateIndexFile(
      modelMetadata, 'Sql${modelMetadata.modelName + s}Repository.dart');
}

void generateOrmAbstractClasses(ModelMetadata modelMetadata) {
  void performCreation(path, data) {
    File(path).exists().then((value) => {
          {createFile(path, data)}
        });
  }
  String path = '$ormAbsFolder';
  final ormgen = OrmAbsClassesGenerator();
  performCreation(path + 'persistent_model.dart', ormgen.generateAbsPersistentModelClass());
  if (modelMetadata.repository != 'sqflite') {
    performCreation(path + 'firestore_model.dart', ormgen.generateAbsFirestoreModelClass());
    performCreation(ormRepoFolder + 'firestore_repository.dart', ormgen.generateFirestoreRepositoryClass());
  }
}

void createFile(path, data) {
  File(path).createSync(recursive: true);
  final File f = File(path);
  f.writeAsStringSync(data);
}

void updateIndexFile(ModelMetadata modelMetadata, classPath) {
  String path = '$ormFolder${modelMetadata.modelName}/index.dart';
  String exportStmt = 'export \'$classPath\';';
  File(path).createSync(recursive: true);
  List<String> contents = File(path).readAsLinesSync();
  if (!contents.contains(exportStmt)) {
    contents.add(exportStmt);
    File(path).writeAsStringSync(contents.join('\n'));
  }
}
