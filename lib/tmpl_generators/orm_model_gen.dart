import 'package:flutter_orm_sugar/models/model_field.dart';
import 'package:flutter_orm_sugar/models/model_metadata.dart';

class OrmModelGenerator {
  final ModelMetadata modelMetadata;
  final List<ModelField> requiredFields = [];
  final List<ModelField> optionalFields = [];
  final List<ModelField> optionalFieldsNoDefault = [];
  final List<ModelField> modelFields = [];

  OrmModelGenerator(this.modelMetadata) {
    modelMetadata.modelFields.forEach((modelField) {
      modelFields.add(modelField);
      if (modelField.isRequired)
        requiredFields.add(modelField);
      else
        optionalFields.add(modelField);
    });
  }

  final List nullables = ['', false, 0, null];

  String generateModelFieldsDeclaration() {
    String fieldDeclarations = '';
    modelFields.forEach((mf) {
      fieldDeclarations += '\n  ';
      fieldDeclarations += 'final ${mf.type} ${mf.name};';
    });
    return fieldDeclarations;
  }

  String generateConstructor() {
    String c = '${modelMetadata.modelName}(';

    if (requiredFields.length > 0) {
      requiredFields.forEach((modelField) {
        c += '\n    this.${modelField.name},';
      });
    }
    c += requiredFields.length > 0 ? ' [' : '[';
    if (optionalFields.length > 0) {
      optionalFields.forEach((modelField) {
        c += '\n    ';
        if (!nullables.contains(modelField.defaultValue)) {
          c += 'this.${modelField.name} = ${modelField.defaultValue},';
        } else {
          c += '${modelField.type} ${modelField.name},';
          optionalFieldsNoDefault.add(modelField);
        }
      });
    }
    c += '\n    String id,\n    DateTime createdAt, \n    DateTime updatedAt';
    c += '\n  ])';

    c += ':';
    if (optionalFieldsNoDefault.length > 0) {
      optionalFieldsNoDefault.forEach((modelField) {
        c += '\n    ';
        c += 'this.${modelField.name} = ${modelField.name},';
      });
    }
    c += '\n    super(id, createdAt, updatedAt)';
    c += ';';

    return c;
  }

  String generateCopyWith() {
    String cw = '${modelMetadata.modelName} copyWith({';

    modelFields.forEach((mf) {
      cw += '\n    ${mf.type} ${mf.name},';
    });
    cw += '\n    String id,\n    DateTime createdAt,\n    DateTime updatedAt';
    cw += '\n  }) {';
    cw += '\n    return ${modelMetadata.modelName}(';
    modelFields.forEach((mf) {
      cw += '\n      ${mf.name} ?? this.${mf.name},';
    });
    cw +=
        '\n      id ?? this.id,\n      createdAt ?? this.createdAt, \n      updatedAt ?? this.updatedAt';
    cw += '\n    );\n  }';

    return cw;
  }

  String generateHashCode() {
    String hc = '@override \n  int get hashCode => \n     ';
    int fieldPerLine = 0;
    modelFields.forEach((mf) {
      if (fieldPerLine > 5) {
        //maximum of 6 fields per line
        fieldPerLine = 0;
        hc += '\n     ';
      }
      hc += ' ${mf.name}.hashCode ^';
      fieldPerLine += 1;
    });
    hc = hc.substring(0, hc.length - 2);
    hc += ';';
    return hc;
  }

  String generateOperator() {
    String o = '@override \n  bool operator ==(Object other) =>';
    o +=
        '\n      identical(this, other) || \n      other is ${modelMetadata.modelName} &&';
    o += '\n          runtimeType == other.runtimeType &&';
    modelFields.forEach((mf) {
      o += '\n          ${mf.name} == other.${mf.name} &&';
    });
    o = o.substring(0, o.length - 3);
    o += ';';
    return o;
  }

  String generateToString() {
    String ts = '@override \n  String toString() {';
    ts += '\n    return \'\'\'${modelMetadata.modelName} {';
    modelFields.forEach((mf) {
      ts += '\n      ${mf.name}: \$${mf.name},';
    });
    ts = ts.substring(0, ts.length - 1);
    ts += '\n    }\'\'\'; \n  }';
    return ts;
  }

  String generateToJson() {
    String tj = 'Map<String, dynamic> toJson() { \n    return {';
    modelFields.forEach((mf) {
      tj += '\n      "${mf.name}": ${mf.name},';
    });
    tj +=
        '\n      "id": id, \n      "createdAt": createdAt, \n      "updatedAt": updatedAt';
    tj += '\n    }; \n  }';
    return tj;
  }

  String generateFromJson() {
    String rj =
        'static ${this.modelMetadata.modelName} fromJson(Map<String, dynamic> json) { \n    return ${this.modelMetadata.modelName} (';
    requiredFields.forEach((mf) {
      rj += '\n      ';
      rj += 'json["${mf.name}"] as ${mf.type},';
    });
    if (optionalFields == null) rj = rj.substring(0, rj.length - 1);

    if (optionalFields != null && optionalFields.length > 0) {
      optionalFields.forEach((of) {
        rj += '\n      json["${of.name}"] as ${of.type},';
      });
      rj += '\n      json["id"] as String,';
      rj += '\n      json["createdAt"] as DateTime,';
      rj += '\n      json["updatedAt"] as DateTime';
    }

    rj += '\n    ); \n  }';
    return rj;
  }

  String generateFinder() {
    String find = '';
    find += '${modelMetadata.modelName}.finder() : this(';
    requiredFields.forEach((mf) {
      find += 'null,';
    });
    find = find.substring(0, find.length - 1);
    find += ');';
    return find;
  }

  String getParentName() {
    return modelMetadata.repository == 'Firestore'
        ? 'FirestoreModel'
        : 'SqliteModel';
  }

  String generateClass() {
    return '''
// Auto generated model class

${this.modelMetadata.repository == 'Firestore' ? 'import \'../orm_abstract/firestore_model.dart\'' : 'import \'../orm_abstract/sqlite_model.dart\''};

class ${modelMetadata.modelName} extends ${getParentName()} {

  /// this is the name of ${this.modelMetadata.repository == 'Firestore'? 'or path to the firestore collection':' Table'}
  /// e.g. ${this.modelMetadata.repository == 'Firestore'? '\'todos\', or \'path/to/todos\'' : 'todo_table'}
  @override
  final String repo = '${modelMetadata.repoName}';

  ${generateModelFieldsDeclaration()}

  ${generateConstructor()}

  ${generateCopyWith()}

  @override
  ${generateToJson()}

  ${generateFromJson()}

  /// An empty constructor to conviniently perform queries on ${modelMetadata.modelName}
  ${generateFinder()}

  /// Returns a stream of ${modelMetadata.modelName} based on the filter in 
  /// the where and ordering properties.
  @override
  Stream<List<${modelMetadata.modelName}>> getAll() {
    return super.getQuery().map((value) => value.map((json) => Todo.fromJson(json)).toList());
  }

  /// A convinience method to get a ${modelMetadata.modelName} by its id
  static Future<${modelMetadata.modelName}> getById(String id) {
    return (${modelMetadata.modelName}.finder()..where('id', '=', id))
      .getAll().first.then((value) => value.first);
  }

  /// Method to save or update a ${modelMetadata.modelName}.
  /// if ${modelMetadata.modelName} has id, model is updated
  /// else model created.
  @override
  Future<Todo> save() {
    return super.save().then((value) => 
      copyWith(id: value['id'], createdAt: value['createdAt'], updatedAt: value['updatedAt']));
  }

  ${generateHashCode()}

  ${generateOperator()}

  ${generateToString()}

}  
    
    ''';
  }
}
