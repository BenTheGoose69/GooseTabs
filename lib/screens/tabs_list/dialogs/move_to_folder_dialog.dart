import 'package:flutter/material.dart';
import '../../../models/folder_model.dart';

class MoveToFolderDialog extends StatelessWidget {
  final List<TabFolder> folders;
  final String? currentFolderId;

  const MoveToFolderDialog({
    super.key,
    required this.folders,
    this.currentFolderId,
  });

  static Future<String?> show({
    required BuildContext context,
    required List<TabFolder> folders,
    String? currentFolderId,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => MoveToFolderDialog(
        folders: folders,
        currentFolderId: currentFolderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move to Folder'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Unfiled option (root level)
            ListTile(
              leading: Icon(
                Icons.folder_off_outlined,
                color: currentFolderId == null
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('Unfiled'),
              trailing: currentFolderId == null
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            if (folders.isNotEmpty) const Divider(),
            // Folder options
            ...folders.map((folder) {
              final isSelected = folder.id == currentFolderId;
              return ListTile(
                leading: Icon(
                  Icons.folder_outlined,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(folder.name),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, folder.id),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
