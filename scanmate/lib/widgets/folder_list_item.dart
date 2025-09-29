import 'package:flutter/material.dart';
import 'package:scanmate/models/folder_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class FolderListItem extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // For context menu (rename, delete)

  const FolderListItem({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder, size: 40.0),
      title: Text(folder.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        'Created: ${DateFormat.yMd().add_jm().format(folder.createdAt)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
