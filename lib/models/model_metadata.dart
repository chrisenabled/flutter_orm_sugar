import 'package:flutter_mvvm_generator/models/model_field.dart';

class ModelMetadata {
  final String modelName;
  final List<ModelField> modelFields;
  final String repo;
  final bool hasRepoDep;

  ModelMetadata(this.modelName, this.modelFields, this.repo, this.hasRepoDep);
}
