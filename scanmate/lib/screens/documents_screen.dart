import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanmate/bloc/file_manager_bloc.dart';
import 'package:scanmate/models/document_model.dart';
import 'package:scanmate/models/folder_model.dart';
import 'package:scanmate/services/storage_service.dart'; // For BLoC
import 'package:scanmate/widgets/document_list_item.dart';
import 'package:scanmate/widgets/folder_list_item.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For simplicity, we'll instantiate StorageService here.
    // In a larger app, it would be provided, perhaps by a parent BLoC or get_it.
    final storageService = StorageService();

    return BlocProvider(
      create: (context) =>
          FileManagerBloc(storageService)..add(const LoadRootContent()),
      child: BlocConsumer<FileManagerBloc, FileManagerState>(
        listener: (context, state) {
          if (state is FileManagerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          } else if (state is FileManagerActionSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green),
            );
          } else if (state is FileManagerActionFailure) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Action failed: ${state.message}'),
                  backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is FileManagerLoading && state is! FileManagerLoaded) { // Show loading only if not already loaded
            return const Center(child: CircularProgressIndicator());
          } else if (state is FileManagerLoaded) {
            return _buildLoadedView(context, state);
          } else if (state is FileManagerError && state is! FileManagerLoaded) {
            // Only show error if not falling back to a loaded state from an action failure
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () => BlocProvider.of<FileManagerBloc>(context)
                        .add(const LoadRootContent()),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          return const Center(child: Text('Initializing File Manager...')); // Initial or unhandled state
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, FileManagerLoaded state) {
    final items = <Widget>[];

    // Breadcrumbs for navigation
    if (state.pathBreadcrumbs.isNotEmpty) {
      items.add(_buildBreadcrumbs(context, state.pathBreadcrumbs, state.currentFolderPath == 'root'));
      items.add(const Divider(height: 1));
    }

    if (state.currentFolderPath != 'root' && state.pathBreadcrumbs.length > 1) { // Allow going up only if not at root and not just showing current folder as breadcrumb
        items.add(ListTile(
          leading: const Icon(Icons.arrow_upward),
          title: const Text('..'),
          onTap: () {
            final parentId = state.pathBreadcrumbs.length > 1
                ? state.pathBreadcrumbs[state.pathBreadcrumbs.length - 2].id
                : null;
            if (parentId != null) {
                BlocProvider.of<FileManagerBloc>(context).add(LoadFolderContent(parentId));
            } else {
                BlocProvider.of<FileManagerBloc>(context).add(const LoadRootContent());
            }
          },
        ));
        items.add(const Divider(height: 1));
    }


    // Add folders
    for (final folder in state.folders) {
      items.add(FolderListItem(
        folder: folder,
        onTap: () => BlocProvider.of<FileManagerBloc>(context)
            .add(LoadFolderContent(folder.id)),
        onLongPress: () => _showItemOptions(context, folder.id, folder.name, true),
      ));
    }

    // Add documents
    for (final document in state.documents) {
      items.add(DocumentListItem(
        document: document,
        onTap: () {
          // TODO: Implement document viewing (e.g., open PDF)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on document: ${document.title}')),
          );
        },
        onLongPress: () => _showItemOptions(context, document.id, document.title, false),
      ));
    }

    // Check if the list is empty *after* potentially adding breadcrumbs and ".."
    bool onlyNavigationElements = true;
    for (final item in items) {
      if (item is FolderListItem || item is DocumentListItem) {
        onlyNavigationElements = false;
        break;
      }
    }

    if (onlyNavigationElements) {
      items.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 80, color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(
                  'This folder is empty',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentFolderPath == 'root'
                    ? 'Tap the + buttons below to create a new folder or scan a document.'
                    : 'You can add items here or go up a level.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
         if (state.currentFolderPath == 'root') {
           BlocProvider.of<FileManagerBloc>(context).add(const LoadRootContent());
         } else {
           BlocProvider.of<FileManagerBloc>(context).add(LoadFolderContent(state.currentFolderPath));
         }
      },
      child: ListView.separated(
        itemCount: items.length,
        itemBuilder: (context, index) {
          // Simple fade-in animation for items
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0, // Could be tied to a loading state per item if needed
            child: items[index],
          );
        },
        separatorBuilder: (context, index) {
            final currentItem = items[index];
            final nextItem = (index + 1 < items.length) ? items[index+1] : null;

            if (currentItem is FolderListItem && nextItem is DocumentListItem) {
                 return const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1);
            }
            // No separator after breadcrumbs or ".." item
            if (currentItem is Padding && (currentItem.child is Row && (currentItem.child as Row).children.any((w) => w is InkWell && (w.child as Padding).child is Text && ((w.child as Padding).child as Text).data == 'Documents'))) { // Breadcrumbs
                return const SizedBox.shrink();
            }
            if (currentItem is ListTile && (currentItem.leading is Icon && (currentItem.leading as Icon).icon == Icons.arrow_upward)) {
                 return const SizedBox.shrink(); // No separator after ".."
            }
             if (currentItem is Center) { // No separator after empty state message
                return const SizedBox.shrink();
            }
            return const Divider(height: 1, indent: 72); // Standard separator after items
        }
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, List<FolderModel> breadcrumbs, bool isRoot) {
    List<Widget> breadcrumbWidgets = [];

    breadcrumbWidgets.add(
      Material( // Added Material for InkWell splash effect
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => BlocProvider.of<FileManagerBloc>(context).add(const LoadRootContent()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Text('Documents', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      )
    );

    for (int i = 0; i < breadcrumbs.length; i++) {
      final folder = breadcrumbs[i];
      breadcrumbWidgets.add(Icon(Icons.chevron_right, size: 20.0, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)));
      breadcrumbWidgets.add(
        Material( // Added Material for InkWell splash effect
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => BlocProvider.of<FileManagerBloc>(context).add(LoadFolderContent(folder.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
              child: Text(
                folder.name,
                style: TextStyle(
                  color: i == breadcrumbs.length - 1
                      ? Theme.of(context).textTheme.titleSmall?.color
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: i == breadcrumbs.length - 1 ? FontWeight.normal : FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        )
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: breadcrumbWidgets),
      ),
    );
  }

  void _showItemOptions(BuildContext context, String itemId, String currentName, bool isFolder) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(bottomSheetContext); // Close bottom sheet
                _showRenameDialog(context, itemId, currentName, isFolder);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(bottomSheetContext); // Close bottom sheet
                _showDeleteConfirmationDialog(context, itemId, currentName, isFolder);
              },
            ),
            if (!isFolder) // Share option only for documents
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // TODO: Implement sharing logic using ShareService and document.pdfPath
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share: $currentName (not implemented yet)')),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext outerContext, String itemId, String currentName, bool isFolder) {
    final TextEditingController renameController = TextEditingController(text: currentName);
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Rename ${isFolder ? "Folder" : "Document"}'),
          content: TextField(
            controller: renameController,
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter new name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  BlocProvider.of<FileManagerBloc>(outerContext)
                      .add(RenameItem(itemId: itemId, newName: newName, isFolder: isFolder));
                }
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext outerContext, String itemId, String itemName, bool isFolder) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${isFolder ? "Folder" : "Document"}?'),
          content: Text('Are you sure you want to delete "$itemName"?${isFolder ? "\nAll contents will also be deleted." : ""} This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(outerContext).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                BlocProvider.of<FileManagerBloc>(outerContext)
                    .add(DeleteItem(itemId: itemId, isFolder: isFolder));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }
}
