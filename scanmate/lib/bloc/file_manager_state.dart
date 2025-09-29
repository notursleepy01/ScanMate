part of 'file_manager_bloc.dart';

abstract class FileManagerState extends Equatable {
  const FileManagerState();

  @override
  List<Object?> get props => [];
}

class FileManagerInitial extends FileManagerState {}

class FileManagerLoading extends FileManagerState {}

class FileManagerLoaded extends FileManagerState {
  final String currentFolderPath; // Could be "root" or a folder ID
  final String? currentFolderName; // Name of the current folder, null if root
  final List<FolderModel> folders;
  final List<DocumentModel> documents;
  final List<FolderModel> pathBreadcrumbs; // For navigation trail

  const FileManagerLoaded({
    required this.currentFolderPath,
    this.currentFolderName,
    required this.folders,
    required this.documents,
    this.pathBreadcrumbs = const [],
  });

  @override
  List<Object?> get props => [currentFolderPath, currentFolderName, folders, documents, pathBreadcrumbs];

  FileManagerLoaded copyWith({
    String? currentFolderPath,
    String? currentFolderName,
    bool clearCurrentFolderName = false, // To explicitly set currentFolderName to null
    List<FolderModel>? folders,
    List<DocumentModel>? documents,
    List<FolderModel>? pathBreadcrumbs,
  }) {
    return FileManagerLoaded(
      currentFolderPath: currentFolderPath ?? this.currentFolderPath,
      currentFolderName: clearCurrentFolderName ? null : (currentFolderName ?? this.currentFolderName),
      folders: folders ?? this.folders,
      documents: documents ?? this.documents,
      pathBreadcrumbs: pathBreadcrumbs ?? this.pathBreadcrumbs,
    );
  }
}

class FileManagerError extends FileManagerState {
  final String message;

  const FileManagerError(this.message);

  @override
  List<Object?> get props => [message];
}

// Specific state for when an action like delete/rename is successful,
// potentially to trigger UI feedback before reloading content.
class FileManagerActionSuccess extends FileManagerState {
  final String message;
  const FileManagerActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Specific state for when an action like delete/rename fails.
class FileManagerActionFailure extends FileManagerState {
  final String message;
  const FileManagerActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
