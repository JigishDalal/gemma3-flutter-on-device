abstract class ModelRepository {
  /// Runs the local model for an expense-only request.
  Stream<String> generateExpenseResponseStream(String expenseText);

  /// Checks if the GGUF model file is downloaded on the device.
  Future<bool> isModelInstalled();

  /// Checks if the LlamaEngine is loaded into memory.
  bool get isModelInitialized;

  /// Explicitly loads/initializes the LlamaEngine in background.
  Future<void> initializeModel();
}
