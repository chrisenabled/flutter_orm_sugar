import 'package:flutter_orm_sugar/models/model_field.dart';

class ModelMetadata {
  final String modelName;
  final List<ModelField> modelFields;
  final String repository;
  final String repoName; //table_name or collection path
  final List<Map<String, String>> relationships;

  const ModelMetadata(
      this.modelName, this.modelFields, this.repoName, this.repository, this.relationships);
}
