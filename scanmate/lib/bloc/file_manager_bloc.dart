import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scanmate/models/document_model.dart';
import 'package:scanmate/models/folder_model.dart';
import 'package:scanmate/services/storage_service.dart'; // Assuming this is created

part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  final StorageService _storageService;

  FileManagerBloc(this._storageService) : super(const FileManagerInitial()) { // Made const
    on<LoadRootContent>(_onLoadRootContent);
    on<LoadFolderContent>(_onLoadFolderContent);
    on<CreateNewFolder>(_onCreateNewFolder);
    on<CreateNewDocument>(_onCreateNewDocument);
    on<DeleteItem>(_onDeleteItem);
    on<RenameItem>(_onRenameItem);
  }

  Future<void> _onLoadRootContent(
      LoadRootContent event, Emitter<FileManagerState> emit) async {
    emit(FileManagerLoading());
    try {
      final folders = _storageService.getFoldersInParent(null); // Root folders
      final documents = _storageService.getDocumentsInFolder(null); // Root documents
      emit(FileManagerLoaded(
        currentFolderPath: 'root',
        currentFolderName: null, // Root has no name in this context
        folders: folders,
        documents: documents,
        pathBreadcrumbs: const [], // Made const
      ));
    } catch (e) {
      emit(FileManagerError('Failed to load root content: ${e.toString()}')); // Cannot be const
    }
  }

  Future<void> _onLoadFolderContent(
      LoadFolderContent event, Emitter<FileManagerState> emit) async {
    emit(const FileManagerLoading()); // Made const
    try {
      final currentFolder = _storageService.getFolder(event.folderId);
      if (currentFolder == null) {
        emit(const FileManagerError('Folder not found.')); // Made const
        add(const LoadRootContent()); // Already const
        return;
      }

      final folders = _storageService.getFoldersInParent(event.folderId);
      final documents = _storageService.getDocumentsInFolder(event.folderId);

      // Build breadcrumbs
      final List<FolderModel> breadcrumbs = [];
      String? parentId = currentFolder.parentFolderId;
      FolderModel? tempParent = currentFolder;

      // Add current folder first for reverse iteration later
      breadcrumbs.add(currentFolder);

      while (parentId != null) {
        tempParent = _storageService.getFolder(parentId);
        if (tempParent != null) {
          breadcrumbs.add(tempParent);
          parentId = tempParent.parentFolderId;
        } else {
          break; // Should not happen in a consistent DB
        }
      }

      emit(FileManagerLoaded(
        currentFolderPath: event.folderId,
        currentFolderName: currentFolder.name,
        folders: folders,
        documents: documents,
        pathBreadcrumbs: breadcrumbs.reversed.toList(), // Cannot be const if `toList()` is used on a dynamic list
      ));
    } catch (e) {
      emit(FileManagerError('Failed to load folder content: ${e.toString()}')); // Cannot be const
    }
  }

  Future<void> _onCreateNewFolder(
      CreateNewFolder event, Emitter<FileManagerState> emit) async {
    try {
      await _storageService.createFolder(
          name: event.folderName, parentFolderId: event.parentFolderId);
      emit(const FileManagerActionSuccess('Folder created successfully.')); // Made const
      // Reload current view (root or parent folder)
      if (event.parentFolderId == null) {
        add(const LoadRootContent()); // Already const
      } else {
        add(LoadFolderContent(event.parentFolderId!)); // Event itself is not const here due to arg
      }
    } catch (e) {
      emit(FileManagerActionFailure('Failed to create folder: ${e.toString()}')); // Cannot be const
       // Optionally, reload current view even on failure to refresh state
      if (state is FileManagerLoaded) {
        final loadedState = state as FileManagerLoaded;
        add(LoadFolderContent(loadedState.currentFolderPath)); // Event itself is not const here
      } else {
        add(const LoadRootContent());
      }
    }
  }

  Future<void> _onCreateNewDocument(
      CreateNewDocument event, Emitter<FileManagerState> emit) async {
    try {
      await _storageService.createDocument(
        title: event.title,
        imagePaths: event.imagePaths,
        pdfPath: event.pdfPath,
        folderId: event.folderId,
        extractedText: event.ocrText,
      );
      emit(const FileManagerActionSuccess('Document created successfully.')); // Made const
      // Reload current view
      if (event.folderId == null) {
        add(const LoadRootContent()); // Already const
      } else {
        add(LoadFolderContent(event.folderId!)); // Event itself is not const here due to arg
      }
    } catch (e) {
      emit(FileManagerActionFailure('Failed to create document: ${e.toString()}')); // Cannot be const
      if (state is FileManagerLoaded) {
        final loadedState = state as FileManagerLoaded;
        add(LoadFolderContent(loadedState.currentFolderPath)); // Event itself is not const here
      } else {
        add(const LoadRootContent());
      }
    }
  }

  Future<void> _onDeleteItem(
      DeleteItem event, Emitter<FileManagerState> emit) async {
    try {
      String? parentFolderIdToReload;
      if (state is FileManagerLoaded) {
         // final loadedState = state as FileManagerLoaded; // Removed unused variable
         if (event.isFolder) {
            final item = _storageService.getFolder(event.itemId);
            parentFolderIdToReload = item?.parentFolderId;
         } else {
            final item = _storageService.getDocument(event.itemId);
            parentFolderIdToReload = item?.folderId;
         }
      }

      if (event.isFolder) {
        await _storageService.deleteFolder(event.itemId, deleteContents: true); // Example: default to deleting contents
      } else {
        await _storageService.deleteDocument(event.itemId);
      }
      emit(FileManagerActionSuccess('${event.isFolder ? "Folder" : "Document"} deleted.')); // Made const (message is interpolated but based on consts)
                                                                                          // Actually, no, event.isFolder makes it non-const.
                                                                                          // Let's assume the linter is okay if the string itself is simple enough.
                                                                                          // Reverting to non-const for safety with interpolated strings.
      // emit(const FileManagerActionSuccess('${event.isFolder ? "Folder" : "Document"} deleted.'));

      if (parentFolderIdToReload == null && (state as FileManagerLoaded).currentFolderPath == 'root') {
         add(const LoadRootContent());
      } else if (parentFolderIdToReload != null) {
         add(LoadFolderContent(parentFolderIdToReload));
      } else if ((state as FileManagerLoaded).currentFolderPath != 'root' ) {
         add(LoadFolderContent((state as FileManagerLoaded).currentFolderPath));
      }
       else {
        add(const LoadRootContent()); // Fallback
      }

    } catch (e) {
      emit(FileManagerActionFailure( // Cannot be const
          'Failed to delete ${event.isFolder ? "folder" : "document"}: ${e.toString()}'));
      // Reload current view to reflect that delete failed or partially succeeded
      if (state is FileManagerLoaded) {
        final loadedState = state as FileManagerLoaded;
        add(LoadFolderContent(loadedState.currentFolderPath)); // Event itself is not const here
      } else {
        add(const LoadRootContent());
      }
    }
  }

  Future<void> _onRenameItem(
      RenameItem event, Emitter<FileManagerState> emit) async {
    try {
       String? parentFolderIdToReload;

      if (event.isFolder) {
        final folder = _storageService.getFolder(event.itemId);
        if (folder != null) {
          parentFolderIdToReload = folder.parentFolderId;
          folder.name = event.newName;
          await _storageService.updateFolder(folder);
        } else {
          throw Exception('Folder not found for renaming.');
        }
      } else {
        final document = _storageService.getDocument(event.itemId);
        if (document != null) {
          parentFolderIdToReload = document.folderId;
          document.title = event.newName;
          await _storageService.updateDocument(document);
        } else {
          throw Exception('Document not found for renaming.');
        }
      }
      emit(FileManagerActionSuccess(
          '${event.isFolder ? "Folder" : "Document"} renamed.'));

      if (parentFolderIdToReload == null && (state as FileManagerLoaded).currentFolderPath == 'root') {
         add(const LoadRootContent());
      } else if (parentFolderIdToReload != null) {
         add(LoadFolderContent(parentFolderIdToReload));
      } else if ((state as FileManagerLoaded).currentFolderPath != 'root' ) {
         add(LoadFolderContent((state as FileManagerLoaded).currentFolderPath));
      }
       else {
        add(const LoadRootContent()); // Fallback
      }

    } catch (e) {
      emit(FileManagerActionFailure(
          'Failed to rename ${event.isFolder ? "folder" : "document"}: ${e.toString()}'));
      if (state is FileManagerLoaded) {
        final loadedState = state as FileManagerLoaded;
        add(LoadFolderContent(loadedState.currentFolderPath));
      } else {
        add(const LoadRootContent());
      }
    }
  }
}
