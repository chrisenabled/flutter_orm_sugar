import 'dart:io';

import 'package:flutter_mvvm_generator/generator.dart';
import 'package:flutter_mvvm_generator/models/model_field.dart';
import 'package:flutter_mvvm_generator/models/model_metadata.dart';
import 'package:flutter_mvvm_generator/prompts.dart' as prompts;
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
    String name = prompts.get("Enter model's name (e.g Todo): ",
        validate: (s) => rightFormat(s));
    name = '${name[0].toUpperCase()}${name.substring(1)}';
    return name;
  }

  void getFieldsDetails() {
    final addField = prompts.getBool('Add new Field', defaultsTo: true);
    if (addField) {
      final ModelField field = getFieldFromUserInput();
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
          input = prompts.choose(value['prompt'], value['options'],
              defaultsTo: value['options'][0]);
        } else {
          if (value['isBool'] != null)
            input = prompts.getBool(value['prompt'], defaultsTo: true);
          else {
            bool isOptional = false;
            if (value['isOptional'] != null) isOptional = true;

            if (key == 'defaultValue') {
              switch (fieldJson['type']) {
                case 'int':
                  input =
                      prompts.getInt(value['prompt'], isOptional: isOptional);
                  break;
                case 'double':
                  input = prompts.getDouble(value['prompt'],
                      isOptional: isOptional);
                  break;
                case 'bool':
                  {
                    input = prompts.get(value['prompt'],
                        validate: (s) => s.startsWith('t') || s.startsWith('f'),
                        defaultsTo: 'f');
                    input = input.toString().startsWith('f') ? 'false' : 'true';
                  }
                  break;
                default:
                  input = prompts.get(value['prompt'], isOptional: isOptional);
                  break;
              }
            } else {
              if (key == 'name') {
                input = prompts.get(value['prompt'],
                    isOptional: isOptional,
                    validate: (i) => i != 'id' && i != '_id');
                input =
                    '${input.toString()[0].toLowerCase()}${input.toString().substring(1)}';
              } else {
                input = prompts.get(value['prompt'], isOptional: isOptional);
              }
            }
          }
        }
        fieldJson[key] = input ?? '';
      }
    });
    return ModelField.fromJson(fieldJson);
  }

  ModelMetadata getModelMetaData() {
    String modelName = getNameDetails();
    String repo;
    modelFields.add(ModelField('id', 'String', false,
        '')); // add an id field for use with persistent engines
    getFieldsDetails();
    final addRepo = prompts.getBool("Add Repository?");
    if (addRepo) {
      repo = prompts.choose('Select repository', ['SQL', 'Firebase'],
          defaultsTo: 'SQL');
      if (repo == 'SQL')
        repo = 'sqflite';
      else
        repo = 'cloud_firestore';
    }
    return ModelMetadata(modelName, modelFields, repo, hasRepoDep(repo + ':'));
  }

  void run() {
    final ModelMetadata mm = getModelMetaData();
    generateModelClass(mm);
    if (mm.repo != null) {
      generateEntityClass(mm);
      if (mm.repo == 'sqflite')
        generateSqlRepositoryClass(mm);
      else
        generateFirebaseRepositoryClass(mm);
    }
  }
}
