import 'package:args/command_runner.dart';

import 'create_model_cmd.dart';

class CreateCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "create";
  final description = "Creates Model, Entity, BREAD";

  CreateCommand() {
    addSubcommand(CreateModelCommand());
  }
}

