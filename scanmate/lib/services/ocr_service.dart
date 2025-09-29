import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart' show debugPrint; // For better printing

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromImage(String imagePath) async {
    if (imagePath.isEmpty) {
      debugPrint('OCR Service: Image path is empty.');
      return '';
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // For debugging purposes, let's print block by block
      // for (TextBlock block in recognizedText.blocks) {
      //   debugPrint("Block: ${block.text}");
      //   for (TextLine line in block.lines) {
      //     debugPrint("  Line: ${line.text}");
      //     for (TextElement element in line.elements) {
      //       debugPrint("    Element: ${element.text}");
      //     }
      //   }
      // }
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR Service: Error extracting text from image ($imagePath): $e');
      return ''; // Return empty string on error
    }
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Example of how to use this service (can be called from a BLoC/Cubit or UI event)
  // Future<void> performOcrOnExampleImage(String imagePath) async {
  //   if (imagePath.isEmpty) {
  //     debugPrint("OCR Example: No image path provided.");
  //     return;
  //   }
  //   debugPrint("OCR Example: Processing image at $imagePath");
  //   final String extractedText = await extractTextFromImage(imagePath);
  //
  //   if (extractedText.isNotEmpty) {
  //     debugPrint('--- Extracted Text ---');
  //     debugPrint(extractedText);
  //     debugPrint('--- End of Extracted Text ---');
  //   } else {
  //     debugPrint('OCR Example: No text extracted or an error occurred.');
  //   }
  // }
}
