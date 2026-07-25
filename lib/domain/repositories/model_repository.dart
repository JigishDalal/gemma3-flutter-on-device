abstract class ModelRepository {
  /// Runs the local model for a general request.
  Stream<String> generateExpenseResponseStream(String expenseText);

  /// Runs the local model with function-calling system prompt injected.
  /// The model may respond with a JSON function call or normal text.
  Stream<String> generateFunctionCallStream(String userInput);

  /// Checks if the GGUF model file is downloaded on the device.
  Future<bool> isModelInstalled();

  /// Checks if the LlamaEngine is loaded into memory.
  bool get isModelInitialized;

  /// Explicitly loads/initializes the LlamaEngine in background.
  Future<void> initializeModel();
}
