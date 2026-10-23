// Simple ModelLoader that initializes a tflite Interpreter for native
// platforms. This loader intentionally keeps responsibilities small: load
// the interpreter (from asset), provide access, and close it when done.

// Conditional export: use native IO implementation when dart:io is available
// (Android/iOS/native), otherwise use a stub which is safe for web/tests.

export 'model_loader_stub.dart'
  if (dart.library.io) 'model_loader_io.dart';
