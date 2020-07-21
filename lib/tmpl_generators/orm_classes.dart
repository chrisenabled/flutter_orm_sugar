class OrmAbsClassesGenerator {
  String generateOrmClasses(List<String> repos) {
    return '''
library orm_classes;

import 'package:flutter_orm_sugar/utils.dart';

abstract class OrmModel {
  var id;

  /// Automatically generated first time object is saved.
  DateTime createdAt;

  /// Automatically updated anytime object is saved.
  DateTime updatedAt;

  OrmModel([this.id, this.createdAt, this.updatedAt]);

  Map<String, dynamic> toJson();
}

abstract class Repository {
  Future save(String collection, Map<String, dynamic> values);
  Future update(String collection, Map<String, dynamic> values);
  Future<Map<String, dynamic>> getById(String collection, var id );
  Future<void> delete(String collection, var id);
  Stream<List<Map<String, dynamic>>> query(String repo,
      {List<Map<Map<String, dynamic>, String>> whereClauses,
      List<String> orderBys,
      int limit,
      List<dynamic> startAfter});
}

${generateQueryExecutor(repos)}

    ''';
  }

  String generateQueryExecutor(List<String> repos) {
    String getRepoClass(String repo) {
      return repos.contains(repo) ? '${repo}Repository()' : 'null';
    }

    return ''' 

typedef S ItemCreator<S>(Map<String, dynamic> json);

class QueryExecutor<T> {
  final String repo;
  List<String> _ordering;
  List<Map<Map<String, String>, String>> _conditions;
  int _lim;
  bool useNamingConvention = true;
  final ItemCreator<T> _creator;
  final Repository repository;

  QueryExecutor(this.repo, this._creator, String repositoryType):
    repository = repositoryType == 'firebase'? 
    ${getRepoClass('Firebase')} : repositoryType == 'sqlite'? 
    ${getRepoClass('Sqlite')} : repositoryType == 'api'?
    ${getRepoClass('Api')} : ${getRepoClass('SharedPref')};

  Stream<List<Map<String, dynamic>>> _getQuery() {
    return repository
        .query(repo, whereClauses: _conditions, orderBys: _ordering, limit: _lim)
        .map((event) => !useNamingConvention
            ? event
            : event.map((e) => jsonCC(e)).toList());
  }

  Stream<List<T>> getAll() =>
      _getQuery().map((value) => value.map((json) => _creator(json)).toList());

  /// A convinience method to get a Post by its id
  Future<T> getById(var id) =>
      repository.getById(repo, id).then((value) => _creator(value));

  Future<T> save(OrmModel pm) {
    Map<String, dynamic> json = pm.toJson();
    final DateTime t = DateTime.now();
    final values = Map.from(!useNamingConvention ? json : jsonSC(json));
    values.addAll({'updated_at': t, 'created_at': t});
    return repository.save(repo, values).then((id) {
      json.addAll({'id': id, 'createdAt': t, 'updatedAt': t});
      return _creator(json);
    });
  }

  Future<T> update(OrmModel pm) {
    Map<String, dynamic> json = pm.toJson();
    final DateTime t = DateTime.now();
    final values = Map.from(!useNamingConvention ? json : jsonSC(json));
    values['updated_at'] = t;
    return repository.update(repo, values).then((value) {
      json['updatedAt'] = t;
      return _creator(json);
    });
  }

  Future<void> delete(var id) {
    return repository.delete(repo, id);
  }

  void orderBy(String ob) => this._ordering.add(ob);

  void where(String field, String operation, dynamic predicate) {
    this._conditions.add({
      {field: predicate}: operation
    });
  }

  void limit(int lim) => this._lim = lim;
} 
    ''';
  }

  String generateSqliteRepositoryClass({String dbName = "flutter_orm_sugar"}) {
    return ''' 
import 'dart:io';

import \'package:sqflite/sqflite.dart\';

import '../orm_classes/orm_classes.dart';
import 'package:flutter_orm_sugar/models/models.dart';
import '../../utils.dart';

_onConfigure(Database db) async {
  // Add support for cascade delete
  await db.execute("PRAGMA foreign_keys = ON");
}
_onCreate(Database db, int version) async {
  // Database is created, create the tables
  Batch b = db.batch();
  final conf = Config.fromJson(getConfigJson());
  conf.models.values.skipWhile((mm) => mm.repository != sqlite).forEach((m) {
    b.execute('DROP TABLE IF EXISTS \${m.repoName}');
    String tbl = "CREATE TABLE \${m.repoName} (id INTEGER PRIMARY KEY AUTOINCREMENT,";
    m.modelFields.forEach((mf) {
      tbl += '\${toSnakeCase(mf.name)} \${getSqlFieldType(mf.type)},';
    });
    m.relationships?.forEach((tableName, relType) {
      if (relType == belongsTo) {
        final model = conf.models[tableName];
        if (model.repository == sqlite) {
          tbl +=
              'FOREIGN KEY (\${tableName}_id) REFERENCES \${model.repoName}(id) ON DELETE CASCADE,';
        }
      }
    });
    tbl = tbl.substring(0, tbl.length - 1) + ')';
    b.execute(tbl);
  });
  await b.commit();
}
_onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Database version is updated, alter the table
  await db.execute("ALTER TABLE Test ADD name TEXT");
}
_onOpen(Database db) async {
  // Database is open, print its version
  print('db version \${await db.getVersion()}');
}

class SqliteRepository extends Repository {

  Database db;

  static final SqliteRepository _instance = SqliteRepository._internal();

  factory SqliteRepository() {
    return _instance;
  }

  SqliteRepository._internal() {
    dbInit();
  }

  static SqliteRepository get instance => _instance;

  Future<void> dbInit() async {
    var databasesPath = await getDatabasesPath();
    var path = '\$databasesPath/$dbName';
    Directory(databasesPath).createSync(recursive: true);
    db = await openDatabase(path,
      version: 1, 
      onOpen: _onOpen,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete
    );    
  }

  Future<int> save(String table, Map<String, dynamic> values) async {
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values) async {
    return db.update(table, values,
        where: 'id = ?', whereArgs: [values["id"] as int]);
  }

  Future<Map<String, dynamic>> getById(String table, var id) async {
    return db.query(table, where: '\$id = ?', whereArgs: [id as int])
      .then((results) {
        if (results.length > 0) return results.first;
        return null;
      });
  }

  Future<void> delete(String table, var id) async {
    return db.delete(table, where: '\$id = ?', whereArgs: [id as int]);
  }

  Stream<List<Map<String, dynamic>>> query(String table,
      {List<Map<Map<String, dynamic>, String>> whereClauses,
      List<String> orderBys,
      int limit,
      List<dynamic> startAfter}) {
    final where = _where(whereClauses);
    final wq = where.keys.toList().first;
    final wl = where.values.toList().first;
    return db.query(table, where: wq, whereArgs: wl).asStream(); 
  }


  Map<String, dynamic> _where(List<Map<Map<String, dynamic>, String>> lw) {
    String ws = '';
    List<dynamic> wv = [];
    lw.forEach((w) {
      w.forEach((key, operation) {
        key.forEach((field, predicate) {
          ws += '\$field \$operation ? AND';
          wv.add(predicate);
        });
      });
    });
    ws = ws.substring(0, ws.length - 1);
    return {ws: wv};
  }

  Future close() async => db.close();

}
    ''';
  }

  String generateFirestoreRepositoryClass() {
    return ''' 

import \'package:cloud_firestore/cloud_firestore.dart\';

import '../orm_classes/orm_classes.dart';

class FirebaseRepository extends Repository {

  Future<String> save(String repo, Map<String, dynamic> values) async {
    return Firestore.instance
        .collection(repo)
        .add(values)
        .then((value) => value.documentID);
  }

  Future<String> update(String repo, Map<String, dynamic> values) {
    String id = values['id'];
    values.remove('id');
    return Firestore.instance
        .collection(repo)
        .document(id)
        .updateData(values)
        .then((value) => id);
  }

  Future<Map<String, dynamic>> getById(String repo, var id) {
    return Firestore.instance.collection(repo).document(id as String).get().then((doc) {
      doc.data.addAll({'id': doc.documentID});
      return doc.data;
    });
  }

  Future<void> delete(String repo, var id) {
    return Firestore.instance.collection(repo).document(id as String).delete();
  }

  Stream<List<Map<String, dynamic>>> query(String repo,
      {List<Map<Map<String, dynamic>, String>> whereClauses,
      List<String> orderBys,
      int limit,
      List<dynamic> startAfter}) {
    final collection = Firestore.instance.collection(repo);

    if (whereClauses != null && whereClauses.length > 0) {
      whereClauses.forEach((w) {
        _addWhereClause(collection, w);
      });
    }
    if (orderBys != null && orderBys.length > 0) {
      orderBys.forEach((orderBy) {
        collection.orderBy(orderBy);
      });
    }
    if (startAfter != null) {
      collection.startAfter(startAfter);
    }
    if (limit != null && limit.runtimeType == int) collection.limit(limit);

    return collection.snapshots().map((snapshot) {
      return snapshot.documents.map((doc) {
        doc.data.addAll({'id': doc.documentID});
        return doc.data;
      }).toList();
    });
  }

  Query _addWhereClause(Query query, Map<Map<String, dynamic>, String> w) {
    Query q;
    w.forEach((key, operation) {
      key.forEach((field, predicate) {
        switch (operation) {
          case '=':
            q = query.where(field, isEqualTo: predicate);
            break;
          case '<':
            return query.where(field, isLessThan: predicate);
            break;
          case '<=':
            return query.where(field, isLessThanOrEqualTo: predicate);
            break;
          case '>':
            return query.where(field, isGreaterThan: predicate);
            break;
          case '>=':
            return query.where(field, isGreaterThanOrEqualTo: predicate);
            break;
          case 'notNull':
            return query.where(field, isNull: false);
            break;
          case 'arrayContains':
            return query.where(field, arrayContains: predicate);
            break;
          case 'arrayContainsAny':
            return predicate.runtimeType == List
                ? query.where(field, arrayContainsAny: predicate)
                : query;
            break;
          case 'whereIn':
            return predicate.runtimeType == List
                ? query.where(field, whereIn: predicate)
                : query;
            break;
          default:
            return query.where(field, isNull: true);
        }
      });
    });
    return q;
  }
}  
  
  ''';
  }
}
