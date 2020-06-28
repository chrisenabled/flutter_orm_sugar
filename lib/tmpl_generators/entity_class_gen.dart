

import 'package:flutter_bread/models/model_field.dart';
import 'package:flutter_bread/models/model_metadata.dart';

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
      c += '\n        this.${mf.name},';
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
    String ts = '@override \n  String toString() { \n    return \'${this.entityName} {';
    modelFields.forEach((mf) {
      ts += '\n        ${mf.name}: \$${mf.name},';
    });
    ts = ts.substring(0, ts.length - 1);
    ts += '\n    }\';';
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

  String generateFromSnapshot() {
    String rj = 'static $entityName fromSnapshot(DocumentSnapshot snap) { \n    return $entityName (';
    modelFields.forEach((mf) {
      rj += '\n        ';
      if (mf.name == 'id') rj += 'snap.documentID,';
      else rj += 'snap.data["${mf.name}"],';
    });
    rj = rj.substring(0, rj.length - 1);
    rj += '\n    ); \n  }';
    return rj;
  }

  String addFirebaseImport() {
    return modelMetadata.hasFirebaseSupport?
     'import \'package:cloud_firestore/cloud_firestore.dart\';' : '';
  }


  String generateClass() {
    return '''
// Auto generated Entity class

${addFirebaseImport()}

class $entityName {

  ${generateModelFieldsDeclaration()}

  ${generateConstructor()}

  ${generateToJson()}  ${this.modelMetadata.hasFirebaseSupport ? '\n\n  ' + generateToDocument():''}

  ${generateToString()}

  ${generateFromJson()} ${this.modelMetadata.hasFirebaseSupport ? '\n\n  ' + generateFromSnapshot():''}

}

    ''';
  }
}