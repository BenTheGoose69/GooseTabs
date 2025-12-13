import 'package:flutter/material.dart';
import '../../../widgets/common/app_bar_action.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String songName;
  final String tuning;
  final bool hasChanges;
  final VoidCallback onBack;
  final VoidCallback onNameTap;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const EditorAppBar({
    super.key,
    required this.songName,
    required this.tuning,
    required this.hasChanges,
    required this.onBack,
    required this.onNameTap,
    required this.onPreview,
    required this.onDownload,
    required this.onShare,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: onBack,
      ),
      title: GestureDetector(
        onTap: onNameTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tuning,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
      actions: [
        AppBarAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Preview',
          onPressed: onPreview,
        ),
        AppBarAction(
          icon: Icons.download_outlined,
          tooltip: 'Download',
          onPressed: onDownload,
        ),
        AppBarAction(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onPressed: onShare,
        ),
        AppBarAction(
          icon: hasChanges ? Icons.save : Icons.save_outlined,
          tooltip: 'Save',
          highlighted: hasChanges,
          onPressed: onSave,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
