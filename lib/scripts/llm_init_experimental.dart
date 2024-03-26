import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:process_run/shell.dart';

class LLMSetupScreen extends StatefulWidget {
  @override
  _LLMSetupScreenState createState() => _LLMSetupScreenState();
}

class _LLMSetupScreenState extends State<LLMSetupScreen> {
  bool _setupInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _setupInProgress
          ? CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () {
                setupLLM();
              },
              child: Text('Setup LLM'),
            ),
    );
  }

  Future<void> setupLLM() async {
    setState(() {
      _setupInProgress = true;
    });

    try {
      // Step 1: allow storage

      // Step 2: Download clang and cmake

      // Step 3: Install clang and cmake

      // Step 4: Download and rename model file
      await downloadModel();

      // Step 5: Build llama.cpp
      await runExecutable('make');

      // Step 6: Run server

      setState(() {
        _setupInProgress = false;
      });
    } catch (e) {
      print('Error during setup: $e');
      setState(() {
        _setupInProgress = false;
      });
      // Handle error, show error message to user
    }
  }

  Future<void> runTermuxCommands(List<String> commands) async {
    for (String command in commands) {
      await runExecutable(command);
    }
  }

  Future<void> downloadModel() async {
    const url =
        'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q5_K_S.gguf?download=true';
    final response = await http.get(Uri.parse(url));
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File('${documentsDir.path}/ggml-model-f16.gguf');
    await file.writeAsBytes(response.bodyBytes);
  }

  getApplicationDocumentsDirectory() {
    // return a local documentsDir where model can be placed.
    return "Downloads";
  }

  Future<void> runExecutable(String command) async {
    final result = await runExecutableArguments('sh', ['-c', command]);
    print('Command output: ${result.stdout}');
    if (result.exitCode != 0) {
      throw Exception('Error executing command: $command');
    }
  }
}
