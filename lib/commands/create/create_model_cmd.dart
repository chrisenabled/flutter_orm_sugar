import 'dart:io';

import 'package:flutter_orm_sugar/generator.dart';
import 'package:flutter_orm_sugar/models/models.dart';
import 'package:flutter_orm_sugar/prompts.dart' as prompts;
import 'package:args/command_runner.dart';

import '../../constants.dart';

class CreateModelCommand extends Command {
  final name = 'model';
  final description = 'Generates a Model Class';

  final List<ModelField> modelFields = [];
  final Map<String, dynamic> rels = {};
  String modelName;
  String repoName;
  String repository;
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

  void getRelationships([List<String> fs]) {
    if (!Directory(ormModelFolder).existsSync()) return;
    fs ??= Directory(ormModelFolder)
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((element) => element != toSnakeCase(modelName))
        .toList();
    if (fs == null || fs.length == 0) return;
    final addRel = prompts.getBool('Add a Relationship', defaultsTo: false);
    if (addRel) {
      List<String> relTypes = ['HasOne', 'HasMany', 'BelongsTo'];
      final relType = prompts.choose('Select relationship type', relTypes,
          defaultsTo: relTypes[0]);
      final relModel = prompts.choose(
        'Select Model',
        fs,
        defaultsTo: fs[0],
        validate: (s) => s.toLowerCase() != modelName.toLowerCase(),
      );
      rels.addEntries([MapEntry(relModel, relType)]);
      if (relType == relTypes[2]) {
        String name = '${relModel}Id';
        String type = repository == 'Firestore' ? 'String' : 'int';
        modelFields.add(ModelField(name, type, true, null));
      }
      getRelationships(
          fs.where((element) => !fs.contains(relModel)).toList());
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
    modelName = getNameDetails();
    getFieldsDetails();
    repository = prompts.choose('Select repository', ['Sqlite', 'Firestore'],
        defaultsTo: 'Sqlite');
    if (repository == 'Sqlite') {
      repoName = prompts.get('Enter table name e.g(todo)');
    } else {
      repoName = prompts.get('Enter collection path e.g(path/to/collection)');
    }
    getRelationships();
    return ModelMetadata(modelName, modelFields, repoName, repository, rels);
  }

  void run() {
    final ModelMetadata mm = getModelMetaData();
    generateOrmClasses(mm);
    generateModelClass(mm);
    // if (mm.repoEngine != null) {
    //   generateEntityClass(mm);
    //   if (mm.repoEngine == 'sqflite')
    //     generateSqlRepositoryClass(mm);
    //   else
    //     generateFirebaseRepositoryClass(mm);
    // }
  }
}
