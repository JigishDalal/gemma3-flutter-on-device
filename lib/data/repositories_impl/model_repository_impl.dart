import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/model_repository.dart';

class ModelRepositoryImpl implements ModelRepository {
  LlamaEngine? _engine;

  static const String _modelFileName = 'gemma-3-270m-it-Q4_K_M.gguf';

  static const String _modelUrl =
      'https://huggingface.co/bartowski/google_gemma-3-270m-it-GGUF/resolve/main/google_gemma-3-270m-it-Q4_K_M.gguf?download=true';

  @override
  bool get isModelInitialized => _engine != null;

  @override
  Future<bool> isModelInstalled() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    return File(modelPath).existsSync();
  }

  @override
  Future<void> initializeModel() async {
    if (_engine != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$_modelFileName';

    if (!File(modelPath).existsSync()) return;

    if (Platform.isAndroid) {
      try {
        ffi.DynamicLibrary.open('libmtmd.so');
      } catch (_) {}
    }

    _engine = await LlamaEngine.spawn(
      libraryPath: 'libllama.so',
      modelParams: ModelParams(path: modelPath),
      contextParams: const ContextParams(
        nCtx: 2048,
        nBatch: 512,
        nUbatch: 512,
      ),
    );
  }

  @override
  Stream<String> generateExpenseResponseStream(String userInput) async* {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$_modelFileName';

    // Download model if not available
    if (!File(modelPath).existsSync()) {
      final dio = Dio();
      final controller = StreamController<String>();
      int lastProgress = -1;

      dio
          .download(
            _modelUrl,
            modelPath,
            onReceiveProgress: (received, total) {
              if (total > 0) {
                final progress = ((received / total) * 100).toInt();
                if (progress != lastProgress) {
                  lastProgress = progress;
                  controller.add('<download>$progress</download>');
                }
              }
            },
          )
          .then((_) => controller.close())
          .catchError((e) => controller.addError(e));

      try {
        await for (final progress in controller.stream) {
          yield progress;
        }
      } catch (e) {
        yield '<error>Download failed: $e</error>';
        return;
      }
    }

    // Load model only once
    try {
      if (Platform.isAndroid) {
        try {
          ffi.DynamicLibrary.open('libmtmd.so');
        } catch (_) {}
      }

      _engine ??= await LlamaEngine.spawn(
        libraryPath: 'libllama.so',
        modelParams: ModelParams(path: modelPath),
        contextParams: const ContextParams(
          nCtx: 2048,
          nBatch: 512,
          nUbatch: 512,
        ),
      );
    } catch (e) {
      yield '<error>Unable to load model: $e</error>';
      return;
    }

    EngineSession? session;

    try {
      session = await _engine!.createSession();

      await for (final event in session.generate(
        prompt: _buildPrompt(userInput),
        addSpecial: true,
        parseSpecial: true,
        sampler: const SamplerParams(temperature: 0.7, topK: 40, topP: 0.95),
        maxTokens: 512,
      )) {
        if (event is TokenEvent) {
          yield event.text;
        } else if (event is DoneEvent && event.trailingText.isNotEmpty) {
          yield event.trailingText;
        }
      }
    } catch (e) {
      yield '<error>Generation failed: $e</error>';
    } finally {
      await session?.dispose();
    }
  }

  String _buildPrompt(String userInput) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return '''
<start_of_turn>user
You are an offline FunctionGemma Mobile Actions Agent.
Current Date and Time: $dateStr

Available Mobile Action Tools:
1. turn_on_flashlight: {"action":"turn_on_flashlight","arguments":{}}
2. turn_off_flashlight: {"action":"turn_off_flashlight","arguments":{}}
3. create_contact: {"action":"create_contact","arguments":{"name":"string","phone_number":"string"}}
4. send_email: {"action":"send_email","arguments":{"recipient":"email","subject":"subject","body":"text"}}
5. show_map_location: {"action":"show_map_location","arguments":{"location":"address or query"}}
6. open_wifi_settings: {"action":"open_wifi_settings","arguments":{}}
7. create_calendar_event: {"action":"create_calendar_event","arguments":{"title":"string","date_time":"YYYY-MM-DD HH:mm"}}
8. add_expense: {"action":"add_expense","arguments":{"amount":number,"currency":"INR","category":"string"}}

Output ONLY a JSON function call object matching the user request.

User Request: $userInput<end_of_turn>
<start_of_turn>model
''';
  }
}
