class ModelField {
  final String name;
  final String type;
  final bool isRequired;
  final defaultValue;

  ModelField(this.name, this.type, this.isRequired, this.defaultValue);

  static ModelField fromJson(Map<String, dynamic> json) {
    return ModelField(
      json['name'], 
      json['type'], 
      json['isRequired'], 
      json['defaultValue'] ?? ''
    );
  }

  static final Map fieldPropsPrompt = {
    'name': {
      'prompt': 'Field name (e.g title): ',
    },
    'type': {
      'prompt': 'Select Field type',
      'options': ['String', 'int', 'double', 'bool', 'DateTime']
    },
    'isRequired': {
      'prompt': 'is field required',
      'isBool': true
    },
    'defaultValue': {
      'prompt': 'set default value',
      'isOptional': true
    }

  };

  @override
  String toString() {
      return 'ModelField {name: $name, type: $type, isRequired: $isRequired, defaultValue: $defaultValue}';
  }

}