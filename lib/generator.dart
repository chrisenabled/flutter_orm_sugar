import 'dart:convert';
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

Future<void> generateOrmClasses(List<String> repos) async {
  return createFile(
    ormClassesFile, OrmAbsClassesGenerator()
    .generateOrmClasses(repos), overwrite: true);
}

void generateRepository(ModelMetadata mm) {
  final ormgen = OrmAbsClassesGenerator();
  final repo = mm.repository;
  createFile(ormRepoFolder + '${repo}_repository.dart',
    repo == 'firestore'? ormgen.generateFirestoreRepositoryClass()
      : ormgen.generateSqliteRepositoryClass());
  // File(ormClassesFile).readAsLines()
  // .then((lines) {
  //   insertImports(lines, "import '../orm_repositories/${repo}_repository.dart';");
  //   File(ormClassesFile).writeAsString(lines.join('\n'));
  // });
  // createFile(ormClassesFolder + 'query_executor.dart',
  //   ormgen.generateQueryExecutor());
  
}
