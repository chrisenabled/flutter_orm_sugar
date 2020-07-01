import 'package:flutter_mvvm_generator/models/model_metadata.dart';

class FirebaseRepositoryGenerator {
  final ModelMetadata modelMetadata;

  String modelName;

  FirebaseRepositoryGenerator(this.modelMetadata)
      : modelName = modelMetadata.modelName;

  String addFirebaseImport() {
    String importStmt = '';

    if (!modelMetadata.hasRepoDep)
      importStmt +=
          '///Install cloud_firestore pacakge and uncomment import and all commented codes below \n\n// ';
    importStmt += 'import \'package:cloud_firestore/cloud_firestore.dart\';';

    return importStmt;
  }

  String generateClass() {
    String camelCaseName = modelName[0].toLowerCase() + modelName.substring(1);
    String s = modelName[modelName.length - 1] != 's' ? 's' : '';
    return '''
import 'dart:async';

${addFirebaseImport()}

import '${modelName}Entity.dart';

import '$modelName.dart';

class Firebase${modelName + s}Repository {
  ${!modelMetadata.hasRepoDep ? '// Install cloud_firestore pacakge and uncomment firestore instance ' : ''}
  final ${camelCaseName}Collection = ${!modelMetadata.hasRepoDep ? 'null; //' : ''} Firestore.instance.collection('${camelCaseName + s}');

  Future<void> addNew$modelName($modelName $camelCaseName) async {

    return ${camelCaseName}Collection.add($camelCaseName.toEntity().toDocument());

  }
${!modelMetadata.hasRepoDep ? '//Install cloud_firestore pacakge and uncomment following methods \n /*' : ''}
  Future<$modelName> get$modelName($modelName $camelCaseName) {

    return ${modelName}Collection
      .document($camelCaseName.id).get()
      .then(snapshot) {
        return $modelName.fromEntity(${modelName}Entity.fromSnapshot(snapshot.documents[0]));
    };

  }

  Stream<List<$modelName>> ${camelCaseName + s}() {

    return ${camelCaseName}Collection.snapshots().map((snapshot) {
      return snapshot.documents
          .map((doc) => $modelName.fromEntity(${modelName}Entity.fromSnapshot(doc)))
          .toList();
    });

  }
${!modelMetadata.hasRepoDep ? '*/' : ''}
  Future<void> update$modelName($modelName $camelCaseName) {

    return ${camelCaseName}Collection
        .document($camelCaseName.id)
        .updateData($camelCaseName.toEntity().toDocument());

  }

  Future<void> delete$modelName($modelName $camelCaseName) async {

    return ${camelCaseName}Collection.document($camelCaseName.id).delete();

  }

} 

     ''';
  }
}
