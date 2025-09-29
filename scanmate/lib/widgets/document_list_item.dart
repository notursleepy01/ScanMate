import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanmate/models/document_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class DocumentListItem extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap; // For viewing the document
  final VoidCallback? onLongPress; // For context menu (rename, delete, share)

  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to show a thumbnail from the first image if available
    Widget leadingWidget = const Icon(Icons.article, size: 40.0); // Default icon
    if (document.imagePaths.isNotEmpty) {
      final firstImageFile = File(document.imagePaths.first);
      if (firstImageFile.existsSync()) { // Check if file exists before trying to load
        leadingWidget = SizedBox(
          width: 56.0, // Standard ListTile leading width
          height: 56.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.file(
              firstImageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 40.0); // Fallback on error
              },
            ),
          ),
        );
      }
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(document.title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        'Created: ${DateFormat.yMd().add_jm().format(document.createdAt)}\nPages: ${document.imagePaths.length}', // Example: show page count
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      // Trailing could be a share icon or more_vert for options
    );
  }
}
