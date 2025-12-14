import 'dart:convert';

class TabColumn {
  List<String> notes; // One entry per string, '-' for empty

  TabColumn(int stringCount) : notes = List.filled(stringCount, '-');

  TabColumn.withNotes(this.notes);

  Map<String, dynamic> toJson() => {'notes': notes};

  factory TabColumn.fromJson(Map<String, dynamic> json) =>
      TabColumn.withNotes(List<String>.from(json['notes'] as List));

  bool get isEmpty => notes.every((n) => n == '-');

  int get width {
    int maxWidth = 1;
    for (final note in notes) {
      if (note.length > maxWidth) maxWidth = note.length;
    }
    return maxWidth;
  }
}

class TabMeasure {
  List<TabColumn> columns;
  int stringCount;

  TabMeasure({required this.stringCount, List<TabColumn>? columns})
      : columns = columns ?? [];

  void addColumn() {
    columns.add(TabColumn(stringCount));
  }

  void removeColumn(int index) {
    if (index >= 0 && index < columns.length) {
      columns.removeAt(index);
    }
  }

  void setNote(int columnIndex, int stringIndex, String note) {
    while (columns.length <= columnIndex) {
      addColumn();
    }
    if (stringIndex >= 0 && stringIndex < stringCount) {
      columns[columnIndex].notes[stringIndex] = note.isEmpty ? '-' : note;
    }
  }

  String getNote(int columnIndex, int stringIndex) {
    if (columnIndex < columns.length && stringIndex < stringCount) {
      return columns[columnIndex].notes[stringIndex];
    }
    return '-';
  }

  Map<String, dynamic> toJson() => {
        'stringCount': stringCount,
        'columns': columns.map((c) => c.toJson()).toList(),
      };

  factory TabMeasure.fromJson(Map<String, dynamic> json) => TabMeasure(
        stringCount: json['stringCount'] as int,
        columns: (json['columns'] as List)
            .map((c) => TabColumn.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class TabSection {
  List<TabMeasure> bars;
  int repeatCount;
  String? label;
  List<String> stringNames;

  TabSection({
    required this.stringNames,
    List<TabMeasure>? bars,
    this.repeatCount = 1,
    this.label,
  }) : bars = bars ?? [TabMeasure(stringCount: stringNames.length)];

  int get stringCount => stringNames.length;

  void addBar() {
    bars.add(TabMeasure(stringCount: stringCount));
  }

  void removeBar(int index) {
    if (bars.length > 1 && index >= 0 && index < bars.length) {
      bars.removeAt(index);
    }
  }

  Map<String, dynamic> toJson() => {
        'stringNames': stringNames,
        'bars': bars.map((b) => b.toJson()).toList(),
        'repeatCount': repeatCount,
        'label': label,
      };

  factory TabSection.fromJson(Map<String, dynamic> json) => TabSection(
        stringNames: List<String>.from(json['stringNames'] as List),
        bars: (json['bars'] as List)
            .map((b) => TabMeasure.fromJson(b as Map<String, dynamic>))
            .toList(),
        repeatCount: json['repeatCount'] as int? ?? 1,
        label: json['label'] as String?,
      );
}

class GuitarTab {
  final String id;
  String songName;
  String tuning;
  DateTime createdAt;
  DateTime modifiedAt;
  List<TabSection> sections;
  Map<String, String> legend;
  String? folderId;

  GuitarTab({
    required this.id,
    required this.songName,
    this.tuning = 'Standard',
    required this.createdAt,
    required this.modifiedAt,
    List<TabSection>? sections,
    Map<String, String>? legend,
    this.folderId,
  })  : sections = sections ?? [],
        legend = legend ?? _defaultLegend;

  static final Map<String, String> _defaultLegend = {
    'h': 'Hammer On',
    'p': 'Pull Off',
    'b': 'Bend',
    't': 'Tap',
    '/': 'Slide Up',
    '\\': 'Slide Down',
    '+': 'Natural Harmonic',
    '~': 'Vibrato',
    'x': 'Dead Note',
  };

  static final List<String> standardTunings = [
    'Standard (EADGBE)',
    'Drop D (DADGBE)',
    'Drop C (CGCFAD)',
    'Half Step Down (Eb Ab Db Gb Bb Eb)',
    'Full Step Down (DGCFAD)',
    'Open G (DGDGBD)',
    'Open D (DADF#AD)',
    'DADGAD',
    'Standard Bass (EADG)',
    'Drop D Bass (DADG)',
    '5-String Bass (BEADG)',
    'Custom',
  ];

  static List<String> getStringsForTuning(String tuning) {
    if (tuning.contains('Bass')) {
      if (tuning.contains('5-String')) {
        return ['G', 'D', 'A', 'E', 'B'];
      }
      if (tuning.contains('Drop D')) {
        return ['G', 'D', 'A', 'D'];
      }
      return ['G', 'D', 'A', 'E'];
    }
    if (tuning.contains('Drop D') || tuning == 'DADGAD') {
      return ['e', 'B', 'G', 'D', 'A', 'D'];
    }
    if (tuning.contains('Drop C')) {
      return ['d', 'A', 'F', 'C', 'G', 'C'];
    }
    return ['e', 'B', 'G', 'D', 'A', 'E'];
  }

  List<String> get stringNames => getStringsForTuning(tuning);

  TabSection createEmptySection() {
    final section = TabSection(stringNames: stringNames);
    // Start with 1 empty column
    section.bars[0].addColumn();
    return section;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'songName': songName,
        'tuning': tuning,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'legend': legend,
        'folderId': folderId,
      };

  factory GuitarTab.fromJson(Map<String, dynamic> json) => GuitarTab(
        id: json['id'] as String,
        songName: json['songName'] as String,
        tuning: json['tuning'] as String? ?? 'Standard',
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
        sections: (json['sections'] as List?)
                ?.map((s) => TabSection.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        legend: (json['legend'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            _defaultLegend,
        folderId: json['folderId'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory GuitarTab.fromJsonString(String jsonString) =>
      GuitarTab.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  String toTabFormat() {
    final buffer = StringBuffer();

    // Header with timestamp
    final now = DateTime.now();
    final timestamp = '${now.month}/${now.day}/${now.year}, '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    buffer.writeln('Tab generated by GooseTabs - $timestamp');
    buffer.writeln('Song: $songName');
    buffer.writeln('Tuning: $tuning');
    buffer.writeln();

    for (final section in sections) {
      if (section.label != null && section.label!.isNotEmpty) {
        buffer.writeln('[${section.label}]');
      }

      // Find max string name length for alignment (handles # in names like F#)
      int maxNameLen = 1;
      for (final name in section.stringNames) {
        if (name.length > maxNameLen) maxNameLen = name.length;
      }

      // Export with proper alignment - each column padded to its width
      for (int stringIdx = 0; stringIdx < section.stringCount; stringIdx++) {
        var stringName = section.stringNames[stringIdx];
        // Pad shorter string names with space for alignment
        while (stringName.length < maxNameLen) {
          stringName = '$stringName ';
        }
        buffer.write('$stringName|');

        for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
          final bar = section.bars[barIdx];

          for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
            final column = bar.columns[colIdx];
            final columnWidth = column.width;

            var note = column.notes[stringIdx];

            // Pad note with dashes to match column width for alignment
            while (note.length < columnWidth) {
              note += '-';
            }
            buffer.write(note);
            // Add separator dash after each column
            buffer.write('-');
          }
          buffer.write('|');
        }

        // Add repeat marker on last string
        if (stringIdx == section.stringCount - 1 && section.repeatCount > 1) {
          buffer.write(' x${section.repeatCount}');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    // Generate legend for used symbols
    final usedSymbols = <String, String>{};
    final allContent = sections
        .expand((s) => s.bars)
        .expand((b) => b.columns)
        .expand((c) => c.notes)
        .join();

    for (final entry in legend.entries) {
      if (allContent.contains(entry.key)) {
        usedSymbols[entry.key] = entry.value;
      }
    }

    if (usedSymbols.isNotEmpty) {
      buffer.writeln('************************************');
      for (final entry in usedSymbols.entries) {
        final symbol = entry.key == '◆' ? '+' : entry.key;
        buffer.writeln('$symbol   ${entry.value}');
      }
      buffer.writeln('************************************');
    }

    return buffer.toString();
  }

  factory GuitarTab.fromTabFormat(String content, String id) {
    final lines = content.split('\n');
    String songName = 'Untitled';
    String tuning = 'Standard';
    final sections = <TabSection>[];

    String? currentLabel;
    List<String> currentStringNames = [];
    List<String> currentStringContents = [];
    int repeatCount = 1;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('Song:')) {
        songName = trimmed.substring(5).trim();
      } else if (trimmed.startsWith('Tuning:')) {
        tuning = trimmed.substring(7).trim();
      } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        // Save previous section if exists
        if (currentStringContents.isNotEmpty) {
          sections.add(_parseSection(
            currentStringNames,
            currentStringContents,
            repeatCount,
            currentLabel,
          ));
          currentStringNames = [];
          currentStringContents = [];
          repeatCount = 1;
        }
        currentLabel = trimmed.substring(1, trimmed.length - 1);
      } else if (trimmed.contains('|')) {
        // Parse tab line - string name followed by optional spaces then |
        final match = RegExp(r'^([A-Ga-g#b]*)\s*\|(.+)$').firstMatch(trimmed);
        if (match != null) {
          final stringName = match.group(1)?.trim() ?? '';
          var tabContent = match.group(2) ?? '';

          // Check for repeat marker
          final repeatMatch = RegExp(r'x(\d+)\s*$').firstMatch(tabContent);
          if (repeatMatch != null) {
            repeatCount = int.parse(repeatMatch.group(1)!);
            tabContent = tabContent.replaceAll(RegExp(r'\s*x\d+\s*$'), '');
          }

          // Remove trailing |
          tabContent = tabContent.replaceAll(RegExp(r'\|$'), '');

          currentStringNames.add(stringName);
          currentStringContents.add(tabContent);
        }
      } else if (trimmed.isEmpty && currentStringContents.isNotEmpty) {
        // End of section
        sections.add(_parseSection(
          currentStringNames,
          currentStringContents,
          repeatCount,
          currentLabel,
        ));
        currentStringNames = [];
        currentStringContents = [];
        repeatCount = 1;
        currentLabel = null;
      }
    }

    // Don't forget last section
    if (currentStringContents.isNotEmpty) {
      sections.add(_parseSection(
        currentStringNames,
        currentStringContents,
        repeatCount,
        currentLabel,
      ));
    }

    final now = DateTime.now();
    return GuitarTab(
      id: id,
      songName: songName,
      tuning: tuning,
      createdAt: now,
      modifiedAt: now,
      sections: sections,
    );
  }

  static TabSection _parseSection(
    List<String> stringNames,
    List<String> stringContents,
    int repeatCount,
    String? label,
  ) {
    if (stringNames.isEmpty) {
      return TabSection(stringNames: ['E'], label: label, repeatCount: repeatCount);
    }

    final section = TabSection(
      stringNames: stringNames,
      bars: [],
      repeatCount: repeatCount,
      label: label,
    );

    // Split by | to get bars
    final barContents = <List<String>>[];
    final firstContent = stringContents[0];
    final barParts = firstContent.split('|').where((s) => s.isNotEmpty).toList();

    for (int barIdx = 0; barIdx < barParts.length; barIdx++) {
      barContents.add([]);
      for (int stringIdx = 0; stringIdx < stringContents.length; stringIdx++) {
        final parts = stringContents[stringIdx].split('|').where((s) => s.isNotEmpty).toList();
        if (barIdx < parts.length) {
          barContents[barIdx].add(parts[barIdx]);
        } else {
          barContents[barIdx].add('');
        }
      }
    }

    // Parse each bar - parse all strings together to maintain alignment
    for (final barContent in barContents) {
      final bar = TabMeasure(stringCount: stringNames.length);

      // Find the longest string content
      int maxLen = 0;
      for (final content in barContent) {
        if (content.length > maxLen) maxLen = content.length;
      }

      if (maxLen == 0) {
        bar.addColumn();
        section.bars.add(bar);
        continue;
      }

      // Parse all strings together, tracking positions for proper alignment
      int pos = 0;
      while (pos < maxLen) {
        // Check what's at this position across all strings
        bool anyNonDash = false;
        for (final content in barContent) {
          if (pos < content.length && content[pos] != '-') {
            anyNonDash = true;
            break;
          }
        }

        if (anyNonDash) {
          // At least one string has a note at this position - extract notes from all
          final column = TabColumn(stringNames.length);
          int maxNoteLen = 1;

          for (int stringIdx = 0; stringIdx < barContent.length; stringIdx++) {
            final content = barContent[stringIdx];
            if (pos < content.length && content[pos] != '-') {
              // Extract the note starting at this position
              final note = _extractNoteAt(content, pos);
              column.notes[stringIdx] = note;
              if (note.length > maxNoteLen) maxNoteLen = note.length;
            }
            // else: leave as default '-'
          }

          bar.columns.add(column);
          // Move past the note (maxNoteLen) and its separator dash (+1)
          pos += maxNoteLen + 1;
        } else {
          // All strings have dash at this position - could be empty column or separator
          // Check if next position also has all dashes
          if (pos + 1 < maxLen) {
            bool nextAlsoDash = true;
            for (final content in barContent) {
              if (pos + 1 < content.length && content[pos + 1] != '-') {
                nextAlsoDash = false;
                break;
              }
            }

            if (nextAlsoDash) {
              // Empty column (dash) followed by separator (dash) - add empty column
              bar.columns.add(TabColumn(stringNames.length));
              pos += 2;
            } else {
              // Next position has a note, so this is a separator - skip it
              pos++;
            }
          } else {
            // At the end - skip trailing separator
            pos++;
          }
        }
      }

      if (bar.columns.isEmpty) {
        bar.addColumn();
      }

      section.bars.add(bar);
    }

    if (section.bars.isEmpty) {
      section.bars.add(TabMeasure(stringCount: stringNames.length));
    }

    return section;
  }

  /// Extract a note starting at position [start] in [content]
  /// Returns the full note (e.g., '5h6', '/5', '3+', '12') or '-' if empty
  static String _extractNoteAt(String content, int start) {
    if (start >= content.length || content[start] == '-') {
      return '-';
    }

    final buffer = StringBuffer();
    int i = start;

    while (i < content.length) {
      final char = content[i];
      if (char == '-') break; // End of note (separator dash)

      // Valid note characters: digits, technique symbols, # for sharps, x for dead notes
      if (RegExp(r'[\dhpbt/\\~+#x]').hasMatch(char)) {
        buffer.write(char);
        i++;
      } else {
        break;
      }
    }

    return buffer.isEmpty ? '-' : buffer.toString();
  }
}
