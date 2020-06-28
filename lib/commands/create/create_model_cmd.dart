import 'dart:io';

import 'package:flutter_bread/generator.dart';
import 'package:flutter_bread/models/model_field.dart';
import 'package:flutter_bread/models/model_metadata.dart';
import 'package:flutter_bread/prompts.dart' as prompts;
import 'package:args/command_runner.dart';

class CreateModelCommand extends Command {
   
  final name = 'model';
  final description = 'Generates a Model Class';

  final List<ModelField> modelFields = [];
  final Map modelMetadata = {};

  bool rightFormat(name) {
    final namingRegex = RegExp(r"^[a-zA-Z][a-zA-Z0-9]*");
    return namingRegex.hasMatch(name);
  }

  String getNameDetails() {
    String name = prompts.get("Enter model's name (e.g Todo): ", validate: (s) => rightFormat(s));
    name = '${name[0].toUpperCase()}${name.substring(1)}'; 
    return name;
  }

  void getFieldsDetails() {
    final addField = prompts.getBool('Add new Field', defaultsTo: true);
    if(addField) {
      final field = getFieldFromUserInput();
      if (field != null) {
        modelFields.add(field);
      }
      getFieldsDetails();
    }
  }

  ModelField getFieldFromUserInput() {
    final Map<String, dynamic> fieldJson = {};
    ModelField.fieldPropsPrompt.forEach((key, value) {
      bool run = true;
      if (key == 'defaultValue') {
        if (fieldJson['isRequired'] == true) {
          run = false;
        }
      }
      if (run) {
        dynamic input;
        if (value['options'] != null) {
          input = prompts.choose(value['prompt'], value['options'], defaultsTo: value['options'][0]);
        } else {
          if (value['isBool'] != null)
            input = prompts.getBool(value['prompt'], defaultsTo: true);
          else {
            bool isOptional = false;
            if (value['isOptional'] != null) isOptional = true;
            
            if (key == 'defaultValue') {
              switch(fieldJson['type']) {
                case 'int' : input = prompts.getInt(value['prompt'], isOptional: isOptional); break;
                case 'double' : input = prompts.getDouble(value['prompt'], isOptional: isOptional); break;
                case 'bool' : {
                  input = prompts.get(value['prompt'], 
                  validate: (s) => s.startsWith('t')||s.startsWith('f'), defaultsTo: 'f');
                  input = input.toString().startsWith('f')? 'false' : 'true';
                } break;
                default: input = prompts.get(value['prompt'], isOptional: isOptional); break;
              }
            } else {
              input = prompts.get(value['prompt'], isOptional: isOptional);
            } 
            if (key == 'name') input = '${input.toString()[0].toLowerCase()}${input.toString().substring(1)}';
          }
        }
        fieldJson[key] = input ?? '';
      }

    });
    return ModelField.fromJson(fieldJson);
  }

  ModelMetadata getModelMetaData() {
    String modelName = getNameDetails();
    bool hasEntity = false;
    getFieldsDetails();
    final addEntity = prompts.getBool("Add Entity Class?");
    bool hasFirebaseSupport = false;
    if (addEntity) {
      hasEntity = true;
      hasFirebaseSupport = prompts.getBool("Add Firebase support");
    }
     return ModelMetadata(modelName, modelFields, hasEntity, hasFirebaseSupport);
  }
  void run() {
    final ModelMetadata mm = getModelMetaData();
    generateModelClass(mm);
    if(mm.hasEntity) {
      generateEntityClass(mm);
    }
  }
}
