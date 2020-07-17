import 'dart:convert';
import 'dart:io';

import 'package:flutter_orm_sugar/constants.dart';
import 'package:flutter_orm_sugar/models/models.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_model_gen.dart';
import 'package:flutter_orm_sugar/tmpl_generators/orm_classes.dart';
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
  String modelFileName = toSnakeCase(modelMetadata.modelName);
  String path = '$ormModelFolder$modelFileName/';
  String modelFilePath = path + modelFileName + '.dart';
  if (File(path).existsSync()) {
    Directory('$ormModelFolder$modelFileName').deleteSync(recursive: true);
  }
  final config = Config.fromJson(getConfigJson()) ?? Config({});
  final models = config.models;
  models[modelFileName] = modelMetadata;
  modelMetadata.relationships.forEach((model, rel) {
    final m = models[model];
    if (m != null) {
      switch (rel) {
        case 'HasMany':
        case 'HasOne':
          {
            m.relationships.remove(modelFileName);
            m.relationships
                .addEntries([MapEntry(modelFileName, 'BelongsTo')]);
            String name = '${toCamelCase(modelFileName)}Id';
            String type =
                modelMetadata.repository == 'Firestore' ? 'String' : 'int';
            final mf = ModelField(name, type, true, null);
            m.modelFields.remove(mf);
            m.modelFields.add(mf);
            print(mf.toString());
            models[model] = m;
          }
          break;
      }
      String mFileName = toSnakeCase(model);
      String mFilePath = '$ormModelFolder$mFileName/$mFileName.dart';
      String mString = OrmModelGenerator(m).generateClass();
      createFile(mFilePath, mString);
    }
  });
  createFile(modelFilePath, modelString);
  saveConfig(config.toString());
  // updateIndexFile(modelMetadata, '${modelMetadata.modelName}.dart');
}

void generateSqlRepositoryClass(ModelMetadata modelMetadata) {
  String modelString = SqlSchemaGenerator(modelMetadata).generateClass();
  String s = modelMetadata.modelName[modelMetadata.modelName.length - 1] != 's'
      ? 's'
      : '';
  String path =
      '$ormFolder${modelMetadata.modelName}/Sql${modelMetadata.modelName + s}Repository.dart';
  createFile(path, modelString);
  // updateIndexFile(
  //     modelMetadata, 'Sql${modelMetadata.modelName + s}Repository.dart');
}

void generateOrmClasses(ModelMetadata modelMetadata) {
  void performCreation(path, data) {
    File(path).exists().then((value) => {
          {createFile(path, data)}
        });
  }

  String path = '$ormClassesFolder';
  final ormgen = OrmAbsClassesGenerator();
  performCreation(path + 'orm_classes.dart', ormgen.generateOrmClasses());
  if (modelMetadata.repository != 'sqflite') {
    performCreation(ormRepoFolder + 'firestore_repository.dart',
        ormgen.generateFirestoreRepositoryClass());
  }
}

void createFile(path, data) {
  File(path).create(recursive: true).then((file) => file.writeAsString(data));
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

Map getConfigJson() {
  File(ormConfigFile).createSync(recursive: true);
  final config = File(ormConfigFile).readAsStringSync();
  if (['', null].contains(config)) return {};
  return jsonDecode(config) as Map;
}

void saveConfig(String config) {
  File(ormConfigFile).writeAsStringSync(config);
}
