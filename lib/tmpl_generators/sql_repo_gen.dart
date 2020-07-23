// part of 'orm_classes.dart';
import 'package:flutter_orm_sugar/models/models.dart';

class SqlSchemaGenerator {
  final ModelMetadata modelMetadata;

  String modelName;

  SqlSchemaGenerator(this.modelMetadata) : modelName = modelMetadata.modelName;

  String getSqlFieldType(String fieldName) {
    switch (fieldName) {
      case ('bool'):
      case ('int'):
        return 'INTEGER';
        break;
      case ('String'):
      case ('DateTime'):
        return 'TEXT';
        break;
      case ('double'):
        return 'REAL';
      default:
        return null;
    }
  }

  String sqlIncludeFields() {
    String sqlFields = '';
    modelMetadata.modelFields.forEach((mf) {
      if (mf.name != 'id') {
        sqlFields += '\n        ';
        sqlFields +=
            '${mf.name} ${getSqlFieldType(mf.type)} ${mf.isRequired ? 'NOT NULL' : ''},';
      }
    });
    sqlFields = sqlFields.substring(0, sqlFields.length - 1);
    return sqlFields;
  }

  String foreignKeys() {
    String foreignKeys = '';
    if (modelMetadata.relationships.length > 0) {
      modelMetadata.relationships.forEach((tableName, rel) {
        if (rel == 'BelongsTo') {
          foreignKeys +=
            '\n        FOREIGN KEY (${tableName}_id) REFERENCES $tableName(id) ON DELETE CASCADE,';
        }
      });
    }
    foreignKeys = foreignKeys.substring(0, foreignKeys.length - 1);
    return foreignKeys;
  }

  String generateTableSchema() {
    return '''
  static void createTable$modelName(batch) {
    batch.execute('DROP TABLE IF EXISTS ${this.modelName}');
    batch.execute(\'\'\' CREATE TABLE ${this.modelName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,${sqlIncludeFields()},${foreignKeys()}
    )\'\'\');
  }
    ''';
  }

  String generateClass() {
    String camelCaseName = modelName[0].toLowerCase() + modelName.substring(1);
    String s = modelName[modelName.length - 1] != 's' ? 's' : '';
    return '''
import 'dart:async';

import \'package:sqflite/sqflite.dart\';

import '${modelName}Entity.dart';

import '$modelName.dart';

class Sql${modelName + s}Repository {
  
  final db;

  Sql${modelName + s}Repository(this.db);

  Future<$modelName> addNew$modelName($modelName $camelCaseName) async {

    $camelCaseName.id = await db.insert('$modelName', $camelCaseName.toEntity().toJson());
    return $camelCaseName;
  }

  Future<$modelName> get$modelName($modelName $camelCaseName) async {

      return (await this.${camelCaseName + s}({'id': $camelCaseName.id})).first;

  }

  Future<List<$modelName>> ${camelCaseName + s}(Map<String, dynamic> whereClause) async {
    List<Map> list;
    if (whereClause == null) {
      list = await db.rawQuery('SELECT * FROM $modelName');
    } else {
      String wc = '';
      List wcVal = []; 
      whereClause.forEach((k,v) {
        wc += ' \$k = ? AND';
        wcVal.add(v);
      });
      wc = wc.substring(0, wc.length - 3);
      list = await db.rawQuery('SELECT * FROM $modelName WHERE \$wc', wcVal );
    } 
      
    return list.map((result) => $modelName.fromEntity(${modelName}Entity.fromJson(result))).toList();
  }

  Future<int> update$modelName($modelName $camelCaseName) async {

    return await db.update('$modelName', $camelCaseName.toEntity().toJson(),
     where: 'id = ?', whereArgs: [$camelCaseName.id]
    );

  }

  Future<int> delete$modelName($modelName $camelCaseName) async {

    return await db.delete('$modelName', where: 'id = ?', whereArgs: [$camelCaseName.id]);

  }

  Future close() async => db.close();

} 

     ''';
  }
}
