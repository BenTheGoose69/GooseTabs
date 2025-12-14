import 'package:flutter/material.dart';

class FolderNameDialog extends StatefulWidget {
  final String? currentName;

  const FolderNameDialog({super.key, this.currentName});

  static Future<String?> show({
    required BuildContext context,
    String? currentName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => FolderNameDialog(currentName: currentName),
    );
  }

  @override
  State<FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<FolderNameDialog> {
  late final TextEditingController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName ?? '');
    _isValid = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  void _submit() {
    if (_isValid) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.currentName == null;

    return AlertDialog(
      title: Text(isCreating ? 'New Folder' : 'Rename Folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Folder name',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: Text(isCreating ? 'Create' : 'Rename'),
        ),
      ],
    );
  }
}
