import 'dart:io';

import 'package:flutter_bread/models/model_metadata.dart';
import 'package:flutter_bread/tmpl_generators/entity_class_gen.dart';
import 'package:flutter_bread/tmpl_generators/model_class_gen.dart';

void generateModelClass(ModelMetadata modelMetadata) {
  String modelString = ModelClassGenerator(modelMetadata).generateClass();
  print(modelString);
}

void generateEntityClass(ModelMetadata modelMetadata) {
  String entityString = EntityClassGenerator(modelMetadata).generateClass();
  print(entityString);
}