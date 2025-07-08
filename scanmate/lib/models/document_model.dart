import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'document_model.g.dart'; // Hive generator will create this

@HiveType(typeId: 0)
class DocumentModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id; // Unique ID for the document

  @HiveField(1)
  String title;

  @HiveField(2)
  final List<String> imagePaths; // Paths to cropped images on local storage

  @HiveField(3)
  final String pdfPath; // Path to the generated PDF on local storage

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? folderId; // ID of the folder this document belongs to (null if root)

  @HiveField(7)
  String extractedText; // For OCR search

  DocumentModel({
    required this.id,
    required this.title,
    required this.imagePaths,
    required this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.extractedText = '',
  });

  @override
  List<Object?> get props => [id, title, imagePaths, pdfPath, createdAt, updatedAt, folderId, extractedText];
}
