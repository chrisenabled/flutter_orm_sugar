library flutter_bread;

import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/create/create_cmd.dart';

Future<void> createBreadFromArgs(List<String> args) async {
  final commandRunner = CommandRunner('flutter_bread', 'A Model generator with BREAD to eat!')
  ..addCommand(CreateCommand());
  commandRunner.run(args).catchError((error) {
    if (error is! UsageException) throw error;
    print(error);
    exit(64); // Exit code 64 indicates a usage error.
  });
}



