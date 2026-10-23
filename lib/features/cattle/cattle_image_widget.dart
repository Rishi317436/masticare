import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/image_storage_service.dart';

class CattleImage extends StatelessWidget {
  const CattleImage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, load bytes from ImageStorageService (shared prefs)
      return FutureBuilder<Uint8List?>(
        future: ImageStorageService().loadImageBytes(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.pets_outlined, size: 48)),
            );
          }
          return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        },
      );
    }

    // Native platforms: show from file path
    final file = File(path);
    return Image.file(file, fit: BoxFit.cover);
  }
}
