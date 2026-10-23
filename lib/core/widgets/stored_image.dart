import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/image_storage_service.dart';

class StoredImage extends StatelessWidget {
  const StoredImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: ImageStorageService().loadImageBytes(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image)),
            );
          }
          return Image.memory(bytes, width: width, height: height, fit: fit);
        },
      );
    }

    final file = File(path);
    return Image.file(file, width: width, height: height, fit: fit);
  }
}
