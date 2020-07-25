import 'package:args/args.dart';
import 'package:flutter_orm_sugar/main.dart' as flutter_orm_sugar;

Future<void> main(List<String> args) async {
  
  final parser = ArgParser();
  parser.addOption('mode',
      abbr: 'm', defaultsTo: 'cmd', allowed: ['cmd', 'web'], callback: (mode) {
    if (mode == 'cmd') {
      flutter_orm_sugar.start();
    } else {
      flutter_orm_sugar.startServer();
    }
  });
  parser.parse(args);
}
