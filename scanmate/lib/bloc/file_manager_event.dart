part of 'file_manager_bloc.dart';

abstract class FileManagerEvent extends Equatable {
  const FileManagerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRootContent extends FileManagerEvent {
  const LoadRootContent();
}

class LoadFolderContent extends FileManagerEvent {
  final String folderId;
  const LoadFolderContent(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

class CreateNewFolder extends FileManagerEvent {
  final String folderName;
  final String? parentFolderId;

  const CreateNewFolder({required this.folderName, this.parentFolderId});

  @override
  List<Object?> get props => [folderName, parentFolderId];
}

class CreateNewDocument extends FileManagerEvent {
  // For now, let's assume we get all necessary info.
  // In reality, this might be triggered after scan, crop, OCR.
  final String title;
  final List<String> imagePaths;
  final String pdfPath;
  final String? folderId;
  final String ocrText;

  const CreateNewDocument({
    required this.title,
    required this.imagePaths,
    required this.pdfPath,
    this.folderId,
    required this.ocrText,
  });

  @override
  List<Object?> get props => [title, imagePaths, pdfPath, folderId, ocrText];
}

class DeleteItem extends FileManagerEvent {
  final String itemId;
  final bool isFolder; // True if deleting a folder, false for a document

  const DeleteItem({required this.itemId, required this.isFolder});

  @override
  List<Object?> get props => [itemId, isFolder];
}

class RenameItem extends FileManagerEvent {
  final String itemId;
  final String newName;
  final bool isFolder;

  const RenameItem({required this.itemId, required this.newName, required this.isFolder});

  @override
  List<Object?> get props => [itemId, newName, isFolder];
}

// Add more events for sorting, searching if handled directly by this BLoC later
// For now, search might be a separate UI concern that filters the current list.
