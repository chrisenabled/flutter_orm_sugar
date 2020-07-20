class Config {
  final Map<String, ModelMetadata> models;
  final Map<String, Repo> repos;

  Config({models, repos})
      : models = models ?? {},
        repos = repos ?? {};

  static Config fromJson(Map json) {
    Map modelsJson = json['models'];
    if (modelsJson == null || modelsJson.length == 0) return null;
    Map<String, ModelMetadata> models = modelsJson
        .map((name, modelJ) => MapEntry(name, ModelMetadata.fromJson(modelJ)));
    Map reposJson = json['repositories'];
    Map<String, Repo> repos = reposJson
        ?.map((name, modelJ) => MapEntry(name, Repo.fromJson(reposJson)));
    return Config(models: models, repos: repos);
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

  String reposString() {
    String rs = '';
    if (repos.length == 0) return rs;
    repos.forEach((name, repo) {
      rs += '\n    $name: ${repo.toString()},';
    });
    rs = rs.substring(0, rs.length - 1);
    return rs;
  }

  String toString() {
    return '''
{
  "repositories":{${reposString()}
  },
  "models": {${modelsString()} 
  }
}
    ''';
  }
}

class Repo {
  final String dbName;

  Repo(this.dbName);

  static Repo fromJson(Map reposJson) {
    return Repo(reposJson["name"]);
  }

  String toString() {
    return ''' 
    {
      "name": "$dbName"
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
    mfs = mfs.substring(0, mfs.length - 1);
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
