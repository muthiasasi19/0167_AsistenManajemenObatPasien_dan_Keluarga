import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageHelper {
  static Future<File> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = p.join(directory.path, fileName);
    final File newImage = await imageFile.copy(filePath);
    return newImage;
  }
}
