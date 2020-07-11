

import 'package:flutter_orm_sugar/models/model_field.dart';
import 'package:flutter_orm_sugar/models/model_metadata.dart';

class EntityClassGenerator {

  final ModelMetadata modelMetadata;
  final List<ModelField> modelFields = [];
  String entityName;

  EntityClassGenerator(this.modelMetadata) {
    modelFields.addAll(this.modelMetadata.modelFields);
    entityName = '${this.modelMetadata.modelName}Entity';
  }

  String generateModelFieldsDeclaration() {
    String fieldDeclarations = '';
    modelFields.forEach((modelField) {
      fieldDeclarations  += 'final ${modelField.type} ${modelField.name}; \n  ';
    });
    return fieldDeclarations;
  }

  String generateConstructor() {
    String c = 'const ${this.entityName}(';
    modelFields.forEach((mf) {
      c += '\n      this.${mf.name},';
    });
    c = c.substring(0, c.length - 1);
    c += '\n  );';
    return c;
  }

  String generateToJson() {
    String tj = 'Map<String, Object> toJson() { \n    return {';
    modelFields.forEach((mf) {
      tj += '\n      "${mf.name}": ${mf.name},';
    });
    tj = tj.substring(0, tj.length - 1);
    tj += '\n    }; \n  }';
    return tj;
  }

  String generateToDocument() {
    String tj = 'Map<String, Object> toDocument() { \n    return {';
    modelFields.forEach((mf) {
      if (mf.name != 'id')
        tj += '\n      "${mf.name}": ${mf.name},';
    });
    tj = tj.substring(0, tj.length - 1);
    tj += '\n    }; \n  }';
    return tj;
  }

  String generateToString() {
    String ts = '@override \n  String toString() { \n    return \'\'\'${this.entityName} {';
    modelFields.forEach((mf) {
      ts += '\n        ${mf.name}: \$${mf.name},';
    });
    ts = ts.substring(0, ts.length - 1);
    ts += '\n    }\'\'\'; \n  }';
    return ts;
  }

  String generateFromJson() {
    String rj = 'static $entityName fromJson(Map<String, Object> json) { \n    return $entityName (';
    modelFields.forEach((mf) {
      rj += '\n        ';
      rj += 'json["${mf.name}"] as ${mf.type},';
    });
    rj = rj.substring(0, rj.length - 1);
    rj += '\n    ); \n  }';
    return rj;
  }

  String generateFromSnapshot(bool hasFirestoreDep) {
    String commented () => hasFirestoreDep? '':'//' ;
    String rj = hasFirestoreDep?'':'///Install ${this.modelMetadata.repository} package and uncomment this method to support firestore \n';
    rj += '${commented()}  static $entityName fromSnapshot(DocumentSnapshot snap) { \n${commented()}    return $entityName (';
    modelFields.forEach((mf) {
      rj += '\n${commented()}        ';
      if (mf.name == 'id') rj += 'snap.documentID,';
      else rj += 'snap.data["${mf.name}"],';
    });
    rj = rj.substring(0, rj.length - 1);
    rj += '\n${commented()}    ); \n${commented()}  }';
    return rj;
  }

  String addRepoImport(bool hasRepoDep) {
    String repo = modelMetadata.repository;
    String importStmt = '';
    if (!hasRepoDep) importStmt += '///Install $repo pacakge and uncomment this import \n// ';
    importStmt += 'import \'package:$repo/$repo.dart\';';
    
    return importStmt;
  }


  String generateClass({bool hasRepoDep = false}) {
    return '''
// Auto generated Entity class

${addRepoImport(hasRepoDep)}

class $entityName {

  ${generateModelFieldsDeclaration()}

  ${generateConstructor()}

  ${generateToJson()}  ${modelMetadata.repository == 'cloud_firestore' ? '\n\n  ' + generateToDocument():''}

  ${generateToString()}

  ${generateFromJson()} ${modelMetadata.repository == 'cloud_firestore' ? '\n\n' + generateFromSnapshot(hasRepoDep):''}

}

    ''';
  }
}