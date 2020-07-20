library flutter_orm_sugar;

import 'dart:io';

import 'package:flutter_orm_sugar/menu/menu.dart';
import 'package:flutter_orm_sugar/utils.dart';
import 'package:flutter_orm_sugar/models/models.dart';

import 'package:flutter_orm_sugar/prompts.dart' as prompts;

Future<void> start(List<String> args) async {
  final menuOptions = [create];
  final files = getModelFiles();
  Config config;
  if (File(ormConfigFile).existsSync()) {
    config = Config.fromJson(getConfigJson());
    if (files != null && files.length > 0)
      menuOptions.addAll([edit, delete]);
    if (config.models.length > 0) menuOptions.add(buildConf);
  }

  final selectMenu = prompts.choose('Select Model Action', menuOptions,
      defaultsTo: menuOptions[0]);

  MenuController(selectMenu, files, config?? Config()).run();
}
