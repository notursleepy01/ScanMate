import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<String?> createPdfFromImages(List<String> imagePaths, String fileName) async {
    if (imagePaths.isEmpty) {
      return null;
    }

    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      try {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          print('Image file not found: $imagePath');
          continue; // Skip if image doesn't exist
        }
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image),
              );
            },
          ),
        );
      } catch (e) {
        print('Error adding image to PDF ($imagePath): $e');
        // Optionally, add a placeholder page or skip
      }
    }

    if (pdf.document.pdfPageList.pages.isEmpty) {
      print('No pages were added to the PDF. Aborting PDF creation.');
      return null;
    }

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final filePath = '${outputDir.path}/$fileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      print('PDF saved to: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  // Example of how to use this service (can be called from a BLoC/Cubit or UI event)
  // Future<void> generateExamplePdf() async {
  //   // In a real app, these paths would come from your document management system
  //   // For testing, you might need to place some sample images in accessible paths
  //   // or use image_picker to get paths.
  //
  //   // Example: Using a bundled asset image (requires setup in pubspec.yaml)
  //   // ByteData data = await rootBundle.load('assets/images/sample_image.png');
  //   // List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  //   // final tempDir = await getTemporaryDirectory();
  //   // final tempFile = File('${tempDir.path}/sample_image.png');
  //   // await tempFile.writeAsBytes(bytes);
  //   //
  //   // final List<String> testImagePaths = [tempFile.path];
  //   //
  //   // if (testImagePaths.isNotEmpty) {
  //   //   final pdfPath = await createPdfFromImages(testImagePaths, 'ScanMate_Document');
  //   //   if (pdfPath != null) {
  //   //     print('Example PDF generated at: $pdfPath');
  //   //   } else {
  //   //     print('Failed to generate example PDF.');
  //   //   }
  //   // } else {
  //   //   print('No sample images to generate PDF.');
  //   // }
  // }
}
