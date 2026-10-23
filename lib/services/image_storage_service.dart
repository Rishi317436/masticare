import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Web builds cannot use path_provider.getApplicationDocumentsDirectory().
// Use a browser-compatible storage key instead on the web while keeping the
// native filesystem behavior on Android/iOS. On web we persist image bytes
// in SharedPreferences as base64 under a deterministic key.
class ImageStorageService {
  ImageStorageService();

  /// Save an image. On native platforms, [sourcePath] should be a readable
  /// file path and the image will be copied into the app documents folder.
  /// On web, provide [bytes] (required) and the method will store the bytes
  /// in shared preferences under a 'web://' key and return that key.
  Future<String> saveImage({required String fileName, required String sourcePath, Uint8List? bytes}) async {
    if (kIsWeb) {
      if (bytes == null) throw ArgumentError('bytes must be provided when saving on web');
      final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final storageKey = 'masticare_image_$safeFileName';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, base64Encode(bytes));
      return 'web://$storageKey';
    }

    final directory = await getApplicationDocumentsDirectory();
    final cattleDir = Directory('${directory.path}/cattle_images');
    if (!await cattleDir.exists()) {
      await cattleDir.create(recursive: true);
    }

    final file = File(sourcePath);
    final targetFile = File('${cattleDir.path}/$fileName');

    if (await file.exists()) {
      await file.copy(targetFile.path);
      return targetFile.path;
    }

    return sourcePath;
  }

  /// Delete an image by path. On web, removes the shared preferences entry.
  Future<void> deleteImage(String path) async {
    if (kIsWeb) {
      if (path.startsWith('web://')) {
        final key = path.replaceFirst('web://', '');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      }
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Load image bytes for a stored path. On web, reads the base64 from
  /// SharedPreferences. On native platforms, reads the file bytes.
  Future<Uint8List?> loadImageBytes(String path) async {
    if (kIsWeb) {
      if (!path.startsWith('web://')) return null;
      final key = path.replaceFirst('web://', '');
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString(key);
      if (b64 == null) return null;
      return base64Decode(b64);
    }

    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }
}
