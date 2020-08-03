import 'dart:io';

import 'package:flutter_orm_sugar/generator.dart';
import 'package:flutter_orm_sugar/utils.dart';

import 'models/models.dart';

class FosServices {
  final Config config;

  FosServices(this.config);

  Future addDb(String dbType, DatabaseMetadata db) async {
    try {
      config.databases[dbType] = db;
      await generateOrmClasses(config.databases.keys.toList());
      generateRepository(dbType);
      saveConfig(config.toString());
      return Future.value(200);
    } catch (e) {
      return Future.error(e);
    }
  }

  editDb(String dbToEdit, DatabaseMetadata db) {
    config.databases[dbToEdit] = db;
    saveConfig(config.toString());
  }

  String deleteDb(String dbToDel) {
    final models =
        config.models.values.skipWhile((model) => model.repository != dbToDel);
    if (models != null && models.length > 0) {
      String ms = models.map((m) => m.modelName).toList().join(', ');
      return 'These models: [$ms] use $dbToDel. First delete them before deleting $dbToDel';
    } else {
      config.databases.remove(dbToDel);
      File(ormRepoFolder + '${dbToDel}_repository.dart').delete();
      saveConfig(config.toString());
      generateOrmClasses(config.databases.keys.toList());
    }
    return '';
  }

  createModel(ModelMetadata mm) async {
    await generateOrmClasses(config.databases.keys.toList());
    generateModelClass(mm, config);
  }

  deleteModel(String modelFileName) {
    File('$ormModelFolder$modelFileName/$modelFileName.dart').deleteSync();
    deleteDir('$ormModelFolder$modelFileName');
    deleteDir(ormModelFolder);

    final model = config.models.remove(modelFileName);

    config.models.forEach((key, m) {
      if (m.relationships[modelFileName] != null) {
        m.relationships.remove(modelFileName);
        ModelField mf = m.modelFields.firstWhere(
            (mf) => mf.name.contains(model.modelName.toLowerCase()),
            orElse: () => null,
        );
        if (mf != null) m.modelFields.remove(mf);
        generateModelClass(m, config);
      }
    });
    saveConfig(config.toString());
  }

  generateFromConfig() {
    try {
      Directory(ormModelFolder).deleteSync(recursive: true);
      Directory(ormRepoFolder).deleteSync(recursive: true);
    } catch (e) {
      print("folder doesn't exisit or cannot be deleted");
    }
    config.databases.forEach((dbType, db) => addDb(dbType, db));
    config.models.forEach((_, mm) => createModel(mm));
  }
}
