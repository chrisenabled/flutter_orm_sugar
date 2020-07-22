import 'dart:io';

import 'package:flutter_orm_sugar/generator.dart';
import 'package:flutter_orm_sugar/models/models.dart';
import 'package:flutter_orm_sugar/prompts.dart' as prompts;
import 'package:flutter_orm_sugar/utils.dart';

class MenuController {
  final name = 'model';
  final description = 'Generates a Model Class';

  final List<ModelField> modelFields = [];
  final Map<String, dynamic> rels = {};
  String modelName;
  String repoName;
  String repository;
  final Map modelMetadata = {};
  final String action;
  final List<String> files;
  final Config config;

  MenuController(this.action, this.files, this.config);

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

  void getFieldsDetails({List<ModelField> fields}) {
    final addField = prompts.getBool('Add new Field', defaultsTo: true);
    if (addField) {
      final ModelField field = getFieldFromUserInput();
      if (field != null) {
        fields != null ? fields.add(field) : modelFields.add(field);
      }
      getFieldsDetails();
    }
  }

  void getRelationships([List<String> fs, Map<String, dynamic> relationships]) {
    if (fs == null || fs.length == 0) return;
    bool addRel = prompts.getBool('Add a Relationship', defaultsTo: false);
    while (addRel) {
      List<String> relTypes = [hasOne, hasMany];
      final relType = prompts.choose('Select relationship type', relTypes,
          defaultsTo: relTypes[0]);
      final relModel = prompts.choose(
        'Select Model',
        fs,
        defaultsTo: fs[0],
        validate: (s) => s.toLowerCase() != modelName.toLowerCase(),
      );
      relationships != null
          ? relationships.addEntries([MapEntry(relModel, relType)])
          : rels.addEntries([MapEntry(relModel, relType)]);
      fs.removeWhere((model) => model == relModel);
      addRel = prompts.getBool('Add a Relationship', defaultsTo: false);
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
    final dbs = config.databases.keys.toList();
    repository = prompts.choose('Select repository', dbs, defaultsTo: dbs[0]);
    if (repository == sqlite) {
      repoName = prompts.get('Enter table name e.g(todo)');
    } else {
      repoName = prompts.get('Enter collection path e.g(path/to/collection)');
    }
    getRelationships(
        files?.where((f) => f != toSnakeCase(modelName))?.toList());
    return ModelMetadata(modelName, modelFields, repoName, repository, rels);
  }

  void deleteModel() {
    final modelFileName = prompts.choose('Select Model to delete', files);
    File('$ormModelFolder$modelFileName/$modelFileName.dart').deleteSync();
    deleteDir('$ormModelFolder$modelFileName');
    deleteDir(ormModelFolder);

    final model = config.models.remove(modelFileName);

    final List sameRepo = [];
    config.models.forEach((key, m) {
      if (model.repository == m.repository) sameRepo.add(m);
      if (m.relationships[modelFileName] != null) {
        m.relationships.remove(modelFileName);
        generateModelClass(m, config);
      }
    });
    saveConfig(config.toString());
  }

  void buildConfig() {
    try {
      Directory(ormModelFolder).deleteSync(recursive: true);
      Directory(ormRepoFolder).deleteSync(recursive: true);
    } catch (e) {
      print("folder doesn't exisit or cannot be deleted");
    }
    config.models.forEach((_, mm) => run(action: create, modelMeta: mm));
  }

  void editModel() {
    final modelFileName = prompts.choose('Select Model to edit', files);
    final model = config.models[modelFileName];
    final editMenu = [addProp];
    if (model.modelFields.length > 0) editMenu.add(deleteProp);
    if (files.length > 0) editMenu.add(addRel);
    if (model.relationships.length > 0 &&
        (model.relationships.values.contains(hasMany) ||
            (model.relationships.values.contains(hasOne)))) {
      editMenu.add(deleteRel);
    }
    final getEdit = prompts.choose('Select Editing', editMenu);
    switch (getEdit) {
      case addProp:
        getFieldsDetails(fields: model.modelFields);
        break;
      case deleteProp:
        {
          final selectedProp = prompts.choose('Select Property to delete',
              model.modelFields.map((mf) => mf.name).toList());
          model.modelFields.removeWhere((mf) => mf.name == selectedProp);
        }
        break;
      case addRel:
        getRelationships(files.where((f) => f != modelFileName).toList(),
            model.relationships);
        break;
      case deleteRel:
        {
          final selectedRel = prompts.choose(
              'Select Relationship to remove',
              model.relationships.keys
                  .skipWhile((key) => model.relationships[key] == belongsTo)
                  .toList());
          model.relationships.remove(selectedRel);
          final relatedModel = config.models[selectedRel];
          relatedModel.relationships.remove(modelFileName);
          run(action: create, modelMeta: relatedModel);
        }
        break;
      default:
    }
    run(action: create, modelMeta: model);
  }

  Future<void> addADb() async {
    final dbTypes = [firestore, sqlite, api, sharedPref];
    final dbType = prompts.choose('Select Database to Add',
        dbTypes.skipWhile((type) => config.databases.keys.contains(type)));
    DatabaseMetadata dbMeta;
    String name;
    switch (dbType) {
      case sqlite:
        {
          name = prompts.get('Enter a database name (e.g tododb)');
        }
        break;
      case firestore:
        {
          name = prompts.get('Enter firebase root path if any (e.g tododb)');
        }
        break;
      case api:
        {
          name = prompts
              .get('Enter base api address (e.g http://weather.com/api/)');
        }
        break;
      case sharedPref:
        {
          name = prompts.get('Enter shared preference name (e.g TodoPref)');
        }
        break;
      default:
    }
    dbMeta = DatabaseMetadata(name);
    config.databases[dbType] = dbMeta;
    await generateOrmClasses(config.databases.keys.toList());
    generateRepository(dbType);
    saveConfig(config.toString());
  }

  void editADb() {
    final dbs = config.databases.keys.toList();
    final dbToEdit = prompts.choose('Select Database to Edit', dbs);
    final db = config.databases[dbToEdit];
    String field;
    final json = {};
    while (field != '--Done') {
      final fields = db.toJson().keys.toList();
      fields.add('--Done');
      field = prompts.choose('Select field to change', fields);
      if (field != '--Done') {
        final newVal = prompts.get('Enter new value for $field');
        json[field] = newVal;
      }
    }
    DatabaseMetadata dbm = db.copyWithFromJson(json);
    config.databases[dbToEdit] = dbm;
    saveConfig(config.toString());
  }

  void deleteADb() {
    final dbs = config.databases.keys.toList();
    final dbToDel = prompts.choose('Select Database to Delete', dbs);
    final models =
        config.models.values.skipWhile((model) => model.repository != dbToDel);
    if (models != null && models.length > 0) {
      String ms = models.map((m) => m.modelName).toList().join(', ');
      print(
          'These models: [$ms] use $dbToDel. First delete them before deleting $dbToDel');
    } else {
      config.databases.remove(dbToDel);
      File(ormRepoFolder + '${dbToDel}_repository.dart').delete();
      generateOrmClasses(config.databases.keys.toList());
      saveConfig(config.toString());
    }
  }

  Future<void> run({String action, ModelMetadata modelMeta}) async {
    switch (action ?? this.action) {
      case create:
        {
          modelMeta ??= getModelMetaData();
          await generateOrmClasses(config.databases.keys.toList());
          generateModelClass(modelMeta, config);
        }
        break;
      case edit:
        editModel();
        break;
      case delete:
        deleteModel();
        break;
      case buildConf:
        buildConfig();
        break;
      case addDb:
        addADb();
        break;
      case editDb:
        editADb();
        break;
      case deleteDb:
        deleteADb();
        break;
      default:
    }
  }
}
