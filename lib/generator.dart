import 'dart:io';

import 'package:flutter_orm_sugar/utils.dart';
import 'package:flutter_orm_sugar/models/models.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_model_gen.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_classes.dart';
import 'package:flutter_orm_sugar/tmpl_generators/sql_repo_gen.dart';
import 'utils.dart';

void generateModelClass(ModelMetadata modelMetadata, Config config) {
  String modelString = OrmModelGenerator(modelMetadata).generateClass();
  String modelFileName = toSnakeCase(modelMetadata.modelName);
  String path = '$ormModelFolder$modelFileName/';
  String modelFilePath = path + modelFileName + '.dart';

  final models = config.models;
  models[modelFileName] = modelMetadata;
  modelMetadata.relationships.forEach((model, rel) {
    if (rel == belongsTo) return;
    bool shouldRebuildModel = false;
    final m = models[model];
    if (m != null) {
      switch (rel) {
        case hasMany:
        case hasOne:
          {
            if (m.relationships[modelFileName] == null ||
                m.relationships[modelFileName] != belongsTo) {
              shouldRebuildModel = true;
              m.relationships.remove(modelFileName);
              m.relationships.addEntries([MapEntry(modelFileName, belongsTo)]);
              String name = '${toCamelCase(modelFileName)}Id';
              String type =
                  modelMetadata.repository == firestore ? 'String' : 'int';
              final mf = ModelField(name, type, true, null);
              m.modelFields.removeWhere((mf) => mf.name == name);
              m.modelFields.add(mf);
              models[model] = m;
            }
          }
          break;
      }
      if (shouldRebuildModel) {
        String mFileName = toSnakeCase(model);
        String mFilePath = '$ormModelFolder$mFileName/$mFileName.dart';
        String mString = OrmModelGenerator(m).generateClass();
        createFile(mFilePath, mString, overwrite: true);
      }
    }
  });
  createFile(modelFilePath, modelString, overwrite: true);
  saveConfig(config.toString());
}

void generateSqlRepositoryClass(ModelMetadata modelMetadata) {
  String modelString = SqlSchemaGenerator(modelMetadata).generateClass();
  String s = modelMetadata.modelName[modelMetadata.modelName.length - 1] != 's'
      ? 's'
      : '';
  String path =
      '$ormFolder${modelMetadata.modelName}/Sql${modelMetadata.modelName + s}Repository.dart';
  createFile(path, modelString);
}

Future<void> generateOrmClasses(List<String> dbs) async {
  final fos = File(fosFile).readAsLinesSync();
  final ormClassesExp = fos.firstWhere((line) => line.contains(expOrmClasses),
      orElse: () => null);
  if (dbs.length == 0) {
    fos.removeWhere((line) => line.contains(ormClassesExp));
    File(fosFile).writeAsString(fos.join('\n'));
    return Directory(ormFolder).delete(recursive: true);
  }
  return createFile(
          ormClassesFile, OrmAbsClassesGenerator().generateOrmClasses(dbs),
          overwrite: true)
      .then((value) {
    if (['', null].contains(ormClassesExp)) {
      fos.insert(1, expOrmClasses);
      File(fosFile).writeAsString(fos.join('\n'));
    }
  });
}

void generateRepository(String dbType) {
  final ormgen = OrmAbsClassesGenerator();
  createFile(
      ormRepoFolder + '${dbType}_repository.dart',
      dbType == firestore
          ? ormgen.generateFirestoreRepositoryClass()
          : ormgen.generateSqliteRepositoryClass());
}
