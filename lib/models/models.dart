class Config {
  final Map<String, ModelMetadata> models;

  Config(this.models);

  static Config fromJson(Map json) {
    Map modelsJson = json['models'];
    if (modelsJson == null || modelsJson.length == 0) return null;
    Map<String, ModelMetadata> models = modelsJson
        .map((name, modelJ) => MapEntry(name, ModelMetadata.fromJson(modelJ)));
    return Config(models);
  }

  String modelsString() {
    String ms = '';
    models.forEach((name, model) {
      ms += '\n    "$name": ${model.toString()},';
    });
    ms = ms.substring(0, ms.length - 1);
    return ms;
  }

  String toString() {
    return '''
{
  "models": {
    ${modelsString()} 
  }
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
    rels = rels.substring(0, rels.length - 1);
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
      "modelFields": [${modelFieldsString()}  ],
      "repository": "$repository", 
      "repoName": "$repoName", 
      "relationships": {${relationshipsString()}      
      }
    }
        ''';
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
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      isRequired.hashCode ^
      defaultValue.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelField &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue;

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
        }
    ''';
  }
}