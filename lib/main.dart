import 'dart:io';

import 'package:flutter_orm_sugar/http_handlers.dart';
import 'package:flutter_orm_sugar/menu/menu.dart';
import 'package:flutter_orm_sugar/server_controller.dart';
import 'package:flutter_orm_sugar/utils.dart';
import 'package:flutter_orm_sugar/models/models.dart';

import 'package:flutter_orm_sugar/prompts.dart' as prompts;

Future<void> start() async {
  final modelOptions = [create];
  final files = getModelFiles();
  Config config;
  if (File(ormConfigFile).existsSync()) {
    config = Config.fromJson(getConfigJson());
    if (files != null && files.length > 0) modelOptions.addAll([edit, delete]);
    if (config.models.length > 0) modelOptions.add(buildConf);
  }
  config = config ?? Config();
  final dbOptions = [addDb];
  if (config.databases != null && config.databases.length > 0) {
    dbOptions.addAll([editDb, deleteDb]);
    if (config.databases.length == 4) {
      dbOptions.removeAt(0);
    }
  }
  final menu = [];
  if (config.databases.length > 0) menu.addAll(modelOptions);
  menu.addAll(dbOptions);
  final selectMenu =
      prompts.choose('Select Model Action', menu, defaultsTo: menu[0]);

  MenuController(selectMenu, files, config).run();
}

Future startServer() async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4080);
  print('Listening on localhost:${server.port}');
  await for (HttpRequest request in server) {
    final req = ReqHandler(request);
    final res = ResHandler(request.response);
    addCorsHeaders(res.response);
    handleRequest(req, res);
  }
}
