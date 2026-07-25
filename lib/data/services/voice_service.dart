import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final WhisperController _whisperController = WhisperController();
  String? _currentPath;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Ensures that if a bundled model asset (ggml-tiny.bin) is placed in assets/models/,
  /// it is copied directly to disk without requiring any runtime download.
  Future<void> _ensureBundledModelExtracted() async {
    try {
      final modelDirPath = await WhisperController.getModelDir();
      final targetFile = File('$modelDirPath/ggml-tiny.bin');

      if (!targetFile.existsSync()) {
        debugPrint('Checking for bundled Whisper model asset...');
        final byteData = await rootBundle.load('assets/models/ggml-tiny.bin');
        await targetFile.create(recursive: true);
        await targetFile.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
          flush: true,
        );
        debugPrint('Bundled Whisper model extracted instantly from assets.');
      }
    } catch (e) {
      debugPrint('Asset check fallback (runtime download will be used if needed): $e');
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    final dir = await getTemporaryDirectory();
    _currentPath = '${dir.path}/expense_recording.wav';

    final file = File(_currentPath!);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentPath!,
    );
    _isRecording = true;
  }

  Future<String?> stopRecordingAndTranscribe() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;

    final targetPath = path ?? _currentPath;
    if (targetPath == null || !File(targetPath).existsSync()) {
      return null;
    }

    try {
      // 1. First extract bundled asset if present
      await _ensureBundledModelExtracted();

      // 2. Download model fallback if asset was not bundled
      await _whisperController.downloadModel(WhisperModel.tiny);

      // 3. Transcribe audio locally using whisper.cpp
      final result = await _whisperController.transcribe(
        model: WhisperModel.tiny,
        audioPath: targetPath,
        lang: 'en',
      );

      final text = result?.transcription.text.trim();
      return (text != null && text.isNotEmpty) ? text : null;
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
