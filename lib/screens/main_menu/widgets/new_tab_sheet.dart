import 'package:flutter/material.dart';
import '../../../models/tab_model.dart';
import '../../../services/storage_service.dart';
import 'instrument_option.dart';
import 'string_count_option.dart';

class NewTabSheet extends StatefulWidget {
  final Function(GuitarTab) onCreated;

  const NewTabSheet({super.key, required this.onCreated});

  @override
  State<NewTabSheet> createState() => _NewTabSheetState();
}

class _NewTabSheetState extends State<NewTabSheet> {
  final _songNameController = TextEditingController();
  String _instrument = 'Guitar';
  int _stringCount = 6;

  @override
  void dispose() {
    _songNameController.dispose();
    super.dispose();
  }

  List<String> _getDefaultStrings() {
    if (_instrument == 'Bass') {
      if (_stringCount == 4) return ['G', 'D', 'A', 'E'];
      if (_stringCount == 5) return ['G', 'D', 'A', 'E', 'B'];
      return ['C', 'G', 'D', 'A', 'E', 'B'];
    } else {
      if (_stringCount == 4) return ['e', 'B', 'G', 'D'];
      if (_stringCount == 7) return ['e', 'B', 'G', 'D', 'A', 'E', 'B'];
      if (_stringCount == 8) return ['e', 'B', 'G', 'D', 'A', 'E', 'B', 'F#'];
      return ['e', 'B', 'G', 'D', 'A', 'E'];
    }
  }

  List<int> _getStringOptions() {
    if (_instrument == 'Bass') {
      return [4, 5, 6];
    } else {
      return [6, 7, 8];
    }
  }

  void _create() {
    final songName = _songNameController.text.trim();
    if (songName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song name')),
      );
      return;
    }

    final stringNames = _getDefaultStrings();
    final tab = GuitarTab(
      id: StorageService.generateId(),
      songName: songName,
      tuning: '$_instrument $_stringCount-string',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    final section = TabSection(stringNames: stringNames);
    // Start with 1 empty column
    section.bars[0].addColumn();
    tab.sections.add(section);

    Navigator.pop(context);
    widget.onCreated(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New Tab',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _songNameController,
              decoration: const InputDecoration(
                labelText: 'Song Name',
                hintText: 'Enter the song name',
                prefixIcon: Icon(Icons.music_note_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 20),
            Text(
              'Instrument',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InstrumentOption(
                    label: 'Guitar',
                    icon: Icons.music_note,
                    isSelected: _instrument == 'Guitar',
                    onTap: () => setState(() {
                      _instrument = 'Guitar';
                      if (_stringCount < 6) _stringCount = 6;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InstrumentOption(
                    label: 'Bass',
                    icon: Icons.graphic_eq,
                    isSelected: _instrument == 'Bass',
                    onTap: () => setState(() {
                      _instrument = 'Bass';
                      if (_stringCount > 6) _stringCount = 4;
                      if (_stringCount == 6) _stringCount = 4;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Strings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _getStringOptions().map((count) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: StringCountOption(
                      count: count,
                      isSelected: _stringCount == count,
                      onTap: () => setState(() => _stringCount = count),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Create Tab'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
