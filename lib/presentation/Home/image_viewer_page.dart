// lib/presentation/image_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:manajemen_obat/service/service_http_client.dart'; // Import ServiceHttpClient

class ImageViewerPage extends StatelessWidget {
  final String
  photoPath; // Ini adalah '/api/uploads/nama_file.jpg' dari backend

  const ImageViewerPage({Key? key, required this.photoPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String finalImageUrl =
        '${ServiceHttpClient().baseUrl}${photoPath.replaceFirst('/api/', '')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Gambar Obat')),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.1,
          maxScale: 4.0,
          child: Image.network(
            finalImageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Gagal memuat gambar.'),
                ],
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
