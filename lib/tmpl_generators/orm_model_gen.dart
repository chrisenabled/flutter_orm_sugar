import 'package:flutter_orm_sugar/constants.dart';
import 'package:flutter_orm_sugar/models/models.dart';

import '../constants.dart';

class OrmModelGenerator {
  final ModelMetadata modelMetadata;
  final List<ModelField> requiredFields = [];
  final List<ModelField> optionalFields = [];
  final List<ModelField> optionalFieldsNoDefault = [];
  final List<ModelField> modelFields = [];
  String modelName;

  OrmModelGenerator(this.modelMetadata) {
    modelMetadata.modelFields.forEach((modelField) {
      modelFields.add(modelField);
      if (modelField.isRequired)
        requiredFields.add(modelField);
      else
        optionalFields.add(modelField);
    });
    modelName = toUpperCamelCase(modelMetadata.modelName);
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
    String c = '$modelName(';

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
    String cw = '$modelName copyWith({';

    modelFields.forEach((mf) {
      cw += '\n    ${mf.type} ${mf.name},';
    });
    cw += '\n    String id,\n    DateTime createdAt,\n    DateTime updatedAt';
    cw += '\n  }) {';
    cw += '\n    return $modelName(';
    modelFields.forEach((mf) {
      cw += '\n      ${mf.name} ?? this.${mf.name},';
    });
    cw +=
        '\n      id ?? this.id,\n      createdAt ?? this.createdAt, \n      updatedAt ?? this.updatedAt';
    cw += '\n    );\n  }';

    return cw;
  }

  String generateUpdateMethod() {
    String cw = 'Future<$modelName> update({';

    modelFields.forEach((mf) {
      cw += '\n    ${mf.type} ${mf.name},';
    });
    cw += '\n  }) {';
    cw += '\n    $modelName record =  $modelName(';
    modelFields.forEach((mf) {
      cw += '\n      ${mf.name} ?? this.${mf.name},';
    });
    cw += '\n      this.id,\n      this.createdAt, \n      this.updatedAt';
    cw += '\n    );';
    cw += '\n    return $modelName.query().update(record); \n  }';

    return cw;
  }

  String generateHashCode() {
    String hc = '@override \n  int get hashCode => ';
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
    o += '\n      identical(this, other) || \n      other is $modelName &&';
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
    ts += '\n    return \'\'\'$modelName {';
    modelFields.forEach((mf) {
      ts += '\n      ${mf.name}: \$${mf.name},';
    });
    ts +=
        '\n      id: \$id, \n      createdAt: \$createdAt, \n      updatedAt: \$updatedAt';
    ts += '\n    }\'\'\'; \n  }';
    return ts;
  }

  String generateToJson() {
    String tj = 'Map<String, dynamic> toJson() { \n    return {';
    modelFields.forEach((mf) {
      tj += '\n          "${mf.name}": ${mf.name},';
    });
    tj +=
        '\n          "id": id, \n          "createdAt": createdAt, \n          "updatedAt": updatedAt';
    tj += '\n    }; \n  }';
    return tj;
  }

  String generateFromJson() {
    String rj =
        'static ${this.modelName} fromJson(Map<String, dynamic> json) { \n    return ${this.modelName} (';
    requiredFields.forEach((mf) {
      rj += '\n      ';
      rj += 'json["${mf.name}"] as ${mf.type},';
    });
    if (optionalFields == null) rj = rj.substring(0, rj.length - 1);

    if (optionalFields != null && optionalFields.length > 0) {
      optionalFields.forEach((of) {
        rj += '\n      json["${of.name}"] as ${of.type},';
      });
    }
    rj += '\n      json["id"] as String,';
    rj += '\n      json["createdAt"] as DateTime,';
    rj += '\n      json["updatedAt"] as DateTime';

    rj += '\n    ); \n  }';
    return rj;
  }

  String getExecutor() {
    return modelMetadata.repository == 'Firestore'
        ? 'FirestoreQueryExecutor'
        : 'SqliteQueryExecutor';
  }

  String importRelModels() {
    String relImports = '';
    if (modelMetadata.relationships.length > 0) {
      modelMetadata.relationships.forEach((model, rel) {
        relImports += '\nimport \'../$model/$model.dart\';';
      });
    }
    relImports += '\n';
    return relImports;
  }

  String generateRelMethod() {
    String relMethod = '';
    if (modelMetadata.relationships.length > 0) {
      modelMetadata.relationships.forEach((modelFileName, rel) {
        String m = toCamelCase(modelFileName);
        String model = toUpperCamelCase(modelFileName);
        String thisModelSC = toSnakeCase(modelName);
        String s =
            model[model.length - 1] != 's' && rel == 'hasMany' ? '' : 's';
        String mn = modelName;
        relMethod += rel == 'HasMany'
            ? '/// $mn Has Many $model$s \n  /// returns a $model query builder filtered with the foreign constraint on $mn\'s id'
            : rel == 'HasOne'
                ? '/// $mn Has One $model \n  /// returns the $model that belongs to $mn'
                : '/// $mn Belongs To a $model \n  /// returns the $model who owns $mn';
        relMethod += '\n';
        relMethod +=
            rel == 'HasMany' ? '  QueryExecutor<$model> $m$s' : '  Future<$model> $m';
        relMethod += '() { \n    return';
        relMethod += rel == 'BelongsTo'
            ? ' $model.query().getById(${m}Id);'
            : rel == 'HasMany'
                ? ''' $model.query()..where('${thisModelSC}_id','=',id);'''
                : ''' ($model.query()..where('${thisModelSC}_id','=',id))
                .getAll().first.then((result) => result.first);''';
      });
      relMethod += '\n  }';
    }
    return relMethod;
  }

  String generateClass() {
    return '''
// Auto generated model class

import '../../orm_classes/orm_classes.dart';
${importRelModels()}
class $modelName extends OrmModel {

  /// this is the name of ${this.modelMetadata.repository == 'Firestore' ? 'or path to the firestore collection' : ' Table'}
  /// e.g. ${this.modelMetadata.repository == 'Firestore' ? '\'todos\', or \'path/to/todos\'' : 'todo_table'}

  ${generateModelFieldsDeclaration()}

  ${generateConstructor()}

  @override
  ${generateToJson()}

  ${generateFromJson()}

  /// Returns a query builder to perform queries on $modelName
  static QueryExecutor<$modelName> query() => ${getExecutor()}<$modelName>
          ('${modelMetadata.repoName}', (Map<String, dynamic> json) 
          => $modelName.fromJson(json));

  /// Saves a $modelName and returns a new $modelName that represents the saved object.
  Future<$modelName> save() => $modelName.query().save(this);

  /// Updates a $modelName and returns a new $modelName that represents the updated object.
  ${generateUpdateMethod()}
  
  Future<void> delete() => $modelName.query().delete(id);

  ${generateHashCode()}

  ${generateOperator()}

  ${generateToString()}

  ${generateRelMethod()}

}  
    
    ''';
  }
}
