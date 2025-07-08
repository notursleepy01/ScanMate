import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img; // Renamed to avoid conflict with Flutter's Image widget
import 'package:flutter/foundation.dart' show debugPrint;

enum EnhancementType {
  none,
  grayscale,
  blackAndWhite,
  // Potentially more filters later: brightness, contrast, etc.
}

class ImageEnhancementService {
  Future<Uint8List?> applyEnhancement(
      String imagePath, EnhancementType enhancementType) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('ImageEnhancementService: File not found at $imagePath');
        return null;
      }
      Uint8List imageBytes = await imageFile.readAsBytes();
      return await applyEnhancementToBytes(imageBytes, enhancementType);

    } catch (e) {
      debugPrint('ImageEnhancementService: Error reading image file $imagePath: $e');
      return null;
    }
  }

  Future<Uint8List?> applyEnhancementToBytes(
      Uint8List imageBytes, EnhancementType enhancementType) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        debugPrint('ImageEnhancementService: Could not decode image.');
        return null;
      }

      img.Image processedImage;

      switch (enhancementType) {
        case EnhancementType.none:
          processedImage = image;
          break;
        case EnhancementType.grayscale:
          processedImage = img.grayscale(image);
          break;
        case EnhancementType.blackAndWhite:
          // Simple thresholding for black and white.
          // The threshold value (128) can be adjusted.
          // For more advanced B&W, adaptive thresholding might be needed.
          processedImage = img.grayscale(image); // First convert to grayscale
          img.threshold(processedImage, threshold: 128, method: img.ThresholdMethod.binary);
          break;
        // Add more cases for other filters here
      }

      // Encode back to JPG (or PNG if preferred, JPG is usually smaller for photos)
      // The quality can be adjusted.
      return Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));
    } catch (e) {
      debugPrint('ImageEnhancementService: Error applying filter $enhancementType: $e');
      return null;
    }
  }
}
