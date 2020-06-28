

import 'package:flutter_bread/models/model_field.dart';

class ModelMetadata {

  final String modelName;
  final List<ModelField> modelFields;
  final bool hasEntity;
  final bool hasFirebaseSupport;

  ModelMetadata(this.modelName, this.modelFields, this.hasEntity, this.hasFirebaseSupport);

}