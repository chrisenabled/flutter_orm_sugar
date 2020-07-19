class OrmAbsClassesGenerator {
  String generateOrmClasses() {
    return '''
library orm_classes;


/// Converts a string to a camelCase.
String toCamelCase(String snakeCase) {
  RegExp exp = RegExp(r'(_)([a-z])');
  return snakeCase.replaceAllMapped(
      exp, (match) => match.group(2).toUpperCase());
}

/// Converts a string to snake_case.
String toSnakeCase(String camelCase) {
  RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
  return camelCase
      .replaceAllMapped(exp, (match) => ('_' + match.group(0)))
      .toLowerCase();
}

Map<String, dynamic> jsonSC(Map<String, dynamic> json) {
  final Map<String, dynamic> jsonSC = {};
  return jsonSC.map((key, value) => MapEntry(toSnakeCase(key), value));
}

Map<String, dynamic> jsonCC(Map<String, dynamic> json) {
  final Map<String, dynamic> jsonSC = {};
  return jsonSC.map((key, value) => MapEntry(toCamelCase(key), value));
}

abstract class OrmModel {
  var id;

  /// Automatically generated first time object is saved.
  DateTime createdAt;

  /// Automatically updated anytime object is saved.
  DateTime updatedAt;

  OrmModel([this.id, this.createdAt, this.updatedAt]);

  Map<String, dynamic> toJson();
}

typedef S ItemCreator<S>(Map<String, dynamic> json);

abstract class QueryExecutor<T> {
  final String repo;
  List<String> _ordering;
  List<Map<Map<String, String>, String>> _conditions;
  int _lim;
  bool useNamingConvention = true;
  final ItemCreator<T> _creator;

  QueryExecutor(this.repo, this._creator);

  Stream<List<T>> getAll();

  Future<T> save(OrmModel p);

  Future<T> update(OrmModel p);

  Future<T> getById(String id);

  Future<void> delete(var id);

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

  String generateFirestoreExecutorClass() {
    return ''' 
part of orm_classes; 

class FirestoreQueryExecutor<T> extends QueryExecutor<T> {
  FirestoreQueryExecutor(String repo, ItemCreator<T> creator) : super(repo, creator);

  Stream<List<Map<String, dynamic>>> _getQuery() {
    return FirebaseRepository()
        .query(repo, whereClauses: _conditions, orderBys: _ordering, limit: _lim)
        .map((event) => !useNamingConvention
            ? event
            : event.map((e) => jsonCC(e)).toList());
  }

  Stream<List<T>> getAll() =>
      _getQuery().map((value) => value.map((json) => _creator(json)).toList());

  /// A convinience method to get a Post by its id
  Future<T> getById(String id) =>
      FirebaseRepository().getById(repo, id).then((value) => _creator(value));

  Future<T> save(OrmModel pm) {
    Map<String, dynamic> json = pm.toJson();
    final DateTime t = DateTime.now();
    final values = Map.from(!useNamingConvention ? json : jsonSC(json));
    values.addAll({'updated_at': t, 'created_at': t});
    return FirebaseRepository().save(repo, values).then((id) {
      json.addAll({'id': id, 'createdAt': t, 'updatedAt': t});
      return _creator(json);
    });
  }

  Future<T> update(OrmModel pm) {
    Map<String, dynamic> json = pm.toJson();
    final DateTime t = DateTime.now();
    final values = Map.from(!useNamingConvention ? json : jsonSC(json));
    values['updated_at'] = t;
    return FirebaseRepository().update(repo, values).then((value) {
      json['updatedAt'] = t;
      return _creator(json);
    });
  }

  Future<void> delete(var id) {
    return FirebaseRepository().delete(repo, id.toString());
  }
}
    ''';
  }

  String generateFirestoreRepositoryClass() {
    return ''' 

import \'package:cloud_firestore/cloud_firestore.dart\';

class FirebaseRepository {

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

  Future<Map<String, dynamic>> getById(String repo, String id) {
    return Firestore.instance.collection(repo).document(id).get().then((doc) {
      doc.data.addAll({'id': doc.documentID});
      return doc.data;
    });
  }

  Future<void> delete(String repo, String id) {
    return Firestore.instance.collection(repo).document(id).delete();
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
