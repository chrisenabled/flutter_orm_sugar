import 'package:flutter_mvvm_generator/models/model_field.dart';
import 'package:flutter_mvvm_generator/models/model_metadata.dart';

class ModelClassGenerator {
  final ModelMetadata modelMetadata;
  final List<ModelField> requiredFields = [];
  final List<ModelField> optionalFields = [];
  final List<ModelField> optionalFieldsNoDefault = [];
  final List<ModelField> modelFields = [];

  ModelClassGenerator(this.modelMetadata) {
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
    modelFields.forEach((modelField) {
      if (modelField.name != 'id') fieldDeclarations += 'final ';
      fieldDeclarations += '${modelField.type} ${modelField.name}; \n  ';
    });
    return fieldDeclarations;
  }

  String generateConstructor() {
    String c = '${modelMetadata.modelName}(';

    if (requiredFields.length > 0) {
      requiredFields.forEach((modelField) {
        c += '\n    this.${modelField.name},';
      });
      if (optionalFields.length == 0) c = c.substring(0, c.length - 1);
    }
    if (optionalFields.length > 0) {
      c += requiredFields.length > 0 ? ' {' : '{';
      optionalFields.forEach((modelField) {
        c += '\n    ';
        if (!nullables.contains(modelField.defaultValue)) {
          c += 'this.${modelField.name} = ${modelField.defaultValue},';
        } else {
          c += '${modelField.type} ${modelField.name},';
          optionalFieldsNoDefault.add(modelField);
        }
      });
      c = c.substring(0, c.length - 1);
      c += '\n  }';
    }
    c += optionalFields.length > 0 ? ')' : '\n  )';

    if (optionalFieldsNoDefault.length > 0) {
      c += ':';
      optionalFieldsNoDefault.forEach((modelField) {
        c += '\n    ';
        c += 'this.${modelField.name} = ${modelField.name},';
      });
      c = c.substring(0, c.length - 1);
    }
    c += ';';

    return c;
  }

  String generateCopyWith() {
    String cw = '${modelMetadata.modelName} copyWith({';

    modelFields.forEach((mf) {
      cw += '\n    ${mf.type} ${mf.name},';
    });
    cw = cw.substring(0, cw.length - 1);
    cw += '\n  }) {';
    cw += '\n    return ${modelMetadata.modelName}(';
    requiredFields.forEach((mf) {
      cw += '\n      ${mf.name} ?? this.${mf.name},';
    });
    optionalFields.forEach((mf) {
      cw += '\n      ${mf.name}: ${mf.name} ?? this.${mf.name},';
    });
    cw = cw.substring(0, cw.length - 1);
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

  String generateToEntity() {
    String te = '${modelMetadata.modelName}Entity toEntity() {';
    te += '\n    return ${modelMetadata.modelName}Entity(';
    modelFields.forEach((mf) {
      te += '\n        ${mf.name},';
    });
    te = te.substring(0, te.length - 1);
    te += '\n    ); \n  }';
    return te;
  }

  String generateFromEntity() {
    String fe =
        'static ${modelMetadata.modelName} fromEntity(${modelMetadata.modelName}Entity entity) {';
    fe += '\n    return ${modelMetadata.modelName}(';
    requiredFields.forEach((rf) {
      fe += '\n        entity.${rf.name},';
    });
    optionalFields.forEach((of) {
      fe += '\n        ';
      if (!nullables.contains(of.defaultValue)) {
        fe += '${of.name}: entity.${of.name} ?? ${of.defaultValue},';
      } else {
        fe += '${of.name}: entity.${of.name},';
      }
    });
    fe = fe.substring(0, fe.length - 1);
    return fe += '\n    ); \n  }';
  }

  String generateClass() {
    return '''
// Auto generated model class

${modelMetadata.repo != null ? 'import \'' + modelMetadata.modelName + 'Entity.dart\';' : ''}

class ${modelMetadata.modelName} {

  ${generateModelFieldsDeclaration()}

  ${generateConstructor()}

  ${generateCopyWith()}

  ${generateHashCode()}

  ${generateOperator()}

  ${generateToString()}

  ${modelMetadata.repo != null ? generateToEntity() : ''}

  ${modelMetadata.repo != null ? generateFromEntity() : ''}

}  
    
    ''';
  }
}
