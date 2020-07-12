class OrmAbsClassesGenerator {
  String generateAbsPersistentModelClass() {
    return '''

abstract class PersistentModel {
  String repo;
  var id; /// Automatically generated first time object is saved.
  DateTime createdAt; /// Automatically generated first time object is saved.
  DateTime updatedAt; /// Automatically updated anytime object is saved.
  List<String> ordering;
  List<Map<Map<String, String>, String>> conditions;
  int lim;
  bool useNamingConvention = true;

  PersistentModel([this.id, this.createdAt, this.updatedAt]);

  Map<String, dynamic> toJson();

  Future<dynamic> save();

  Future<dynamic> delete();

  void orderBy(String ob) {
    this.ordering.add(ob);
  }

  void where(String field, String operation, dynamic predicate) {
    this.conditions.add({
      {field: predicate}: operation
    });
  }

  void limit(int lim) => this.lim = lim;

  Stream<List<dynamic>> getAll();

  /// Converts a string to snake_case.
  static String toSnakeCase(String camelCase) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]');
    return camelCase
        .replaceAllMapped(exp, (match) => ('_' + match.group(0)))
        .toLowerCase();
  }
  /// Converts a string to a camelCase.
  static String toCamelCase(String snakeCase) {
    RegExp exp = RegExp(r'(_)([a-z])');
    return snakeCase.replaceAllMapped(exp, (match) => match.group(2).toUpperCase());
  }
  /// Converts a map with camelCase keys to a map with snake_case keys.
  /// When useNamingConvention is set to true this method is called
  /// on the json keys to be saved or updated in the repository
  static Map<String, dynamic> jsonSC(Map<String, dynamic> json) {
    final Map<String, dynamic> jsonSC = {};
    return jsonSC.map((key, value) => MapEntry(toSnakeCase(key), value));
  }
  /// Converts a map with snake_case keys to a map with camelCase keys.
  /// When useNamingConvention is set to true this method is called
  /// on the json keys gotten from the repository to be converted to
  /// the corresponding PersistentModel properties.
  static Map<String, dynamic> jsonCC(Map<String, dynamic> json) {
    final Map<String, dynamic> jsonSC = {};
    return jsonSC.map((key, value) => MapEntry(toCamelCase(key), value));
  }
}
    
    
    ''';
  }

  String generateAbsFirestoreModelClass() {
    return ''' 

import 'persistent_model.dart';
import '../orm_repositories/firestore_repository.dart';

abstract class FirestoreModel extends PersistentModel {

  FirestoreModel([id, createdAt, updatedAt])
      : super(id, createdAt, updatedAt);

  Stream<List<Map<String, dynamic>>> getQuery() {
    return FirebaseRepository()
        .query(repo, whereClauses: conditions, orderBys: ordering)
        .map((event) => !useNamingConvention? event : event.map((e) => PersistentModel.jsonCC(e)));
  }

  Future<dynamic> save() {
    final DateTime t = DateTime.now();
    final Map<String, dynamic> values = 
    Map.from(!useNamingConvention? toJson() : PersistentModel.jsonSC(toJson()));
    values.addAll({'updatedAt': t});
    if (['', null].contains(id)) {
      values.addAll({'createdAt': t});
      return FirebaseRepository().save(repo, values).then((value) {
        values.addAll({id: value});
        return values;
      });
    }
    values.addAll({'id': id});
    return FirebaseRepository().update(repo, values).then((value) {
      return values;
    });
  }

  Future<void> delete() {
    return FirebaseRepository().delete(repo, id);
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

  Future<String> update(String repo, Map<String, dynamic> values) {
    String id = values['id'];
    if (['', null].contains(id)) {
      return save(repo, values);
    }
    values.remove('id');
    values['updated_at'] = DateTime.now();
    return Firestore.instance
        .collection(repo)
        .document(values['id'])
        .updateData(values)
        .then((value) => id);
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
