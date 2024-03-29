class Config {
  final Map<String, ModelMetadata> models;
  final Map<String, DatabaseMetadata> databases;

  Config({Map<String, ModelMetadata> models, Map<String, DatabaseMetadata> dbs})
    : models = models ?? {},
      databases = dbs ?? {};

  static Config fromJson(Map json) {
    Map modelsJson = json['models'];
    Map<String, ModelMetadata> models;
    Map<String, DatabaseMetadata> dbs;
    if (modelsJson != null) {
      models = modelsJson.map(
        (name, modelJ) => MapEntry(name, ModelMetadata.fromJson(modelJ)));
    }
    Map dbsJson = json['repositories'] as Map;
    if (dbsJson != null && dbsJson.length > 0) {
      dbs = dbsJson?.map((name, dbJson) =>
        MapEntry(name, DatabaseMetadata.fromJson(dbJson)));
    }
    return Config(models: models, dbs: dbs);
  }

  String modelsString() {
    String ms = '';
    if (models.length == 0) return ms;
    models.forEach((name, model) {
      ms += '\n    "$name": ${model.toString()},';
    });
    ms = ms.substring(0, ms.length - 1);
    return ms;
  }

  String dbsString() {
    String rs = '';
    if (databases.length == 0) return rs;
    databases.forEach((name, db) {
      rs += '\n    "$name": ${db.toString()},';
    });
    rs = rs.substring(0, rs.length - 1);
    return rs;
  }

  String toString() {
    return '''
{
  "repositories":{${dbsString()}
  },
  "models": {${modelsString()} 
  }
}
    ''';
  }
}

class DatabaseMetadata {
  final String name;

  DatabaseMetadata(this.name);

  static DatabaseMetadata fromJson(Map reposJson) {
    return DatabaseMetadata(reposJson["name"]);
  }

  DatabaseMetadata copyWith({String name}) {
    return DatabaseMetadata(this.name ?? name);
  }

  DatabaseMetadata copyWithFromJson(Map json) {
    return DatabaseMetadata(json['name'] ?? name);
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name
    };
  }

  String toString() {
    return ''' 
    {
      "name": "$name"
    }
    ''';
  }
}

class ModelMetadata {
  final String modelName;
  final List<ModelField> modelFields;
  final String repository;
  final String repoName; //table_name or collection path
  final Map<String, dynamic> relationships;

  const ModelMetadata(this.modelName, this.modelFields, this.repoName,
      this.repository, this.relationships);

  String relationshipsString() {
    String rels = '';
    relationships.forEach((rel, model) {
      rels += '\n        "$rel": "$model",';
    });
    rels =
        ['', null].contains(rels) ? rels : rels.substring(0, rels.length - 1);
    return rels;
  }

  String modelFieldsString() {
    String mfs = '';
    modelFields.forEach((mf) {
      mfs += '\n${mf.toString()},';
    });
    if (mfs.length > 0) mfs = mfs.substring(0, mfs.length - 1);
    return mfs;
  }

  String toString() {
    return '''
    {
      "modelName": "$modelName",
      "modelFields": [${modelFieldsString()}  
      ],
      "repository": "$repository", 
      "repoName": "$repoName", 
      "relationships": {${relationshipsString()}      
      }
    }''';
  }

  static ModelMetadata fromJson(json) {
    List modelFieldsJ = json["modelFields"] as List;
    final rels = json["relationships"] as Map<String, dynamic>;
    final modelFields =
        modelFieldsJ.map((mf) => ModelField.fromJson(mf)).toList();
    return ModelMetadata(json["modelName"], modelFields, json["repoName"],
        json["repository"], rels);
  }
}

class ModelField {
  final String name;
  final String type;
  final bool isRequired;
  final defaultValue;

  ModelField(this.name, this.type, this.isRequired, this.defaultValue);

  static ModelField fromJson(Map<String, dynamic> json) {
    return ModelField(json['name'], json['type'], json['isRequired'],
        json['defaultValue'] ?? '');
  }

  static final Map fieldPropsPrompt = {
    'name': {
      'prompt': 'Field name (e.g title): ',
    },
    'type': {
      'prompt': 'Select Field type',
      'options': ['String', 'int', 'double', 'bool', 'DateTime']
    },
    'isRequired': {'prompt': 'is field required', 'isBool': true},
    'defaultValue': {'prompt': 'set default value', 'isOptional': true}
  };

  @override
  String toString() {
    return ''' 
        {
          "name": "$name",
          "type": "$type",
          "isRequired": $isRequired, 
          "defaultValue": ${[
      '',
      null
    ].contains(defaultValue) ? null : defaultValue.runtimeType != String ? defaultValue : '\"$defaultValue\"'}  
        }''';
  }
}
