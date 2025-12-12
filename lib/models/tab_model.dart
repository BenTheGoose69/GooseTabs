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

  GuitarTab({
    required this.id,
    required this.songName,
    this.tuning = 'Standard',
    required this.createdAt,
    required this.modifiedAt,
    List<TabSection>? sections,
    Map<String, String>? legend,
  })  : sections = sections ?? [],
        legend = legend ?? _defaultLegend;

  static final Map<String, String> _defaultLegend = {
    'h': 'Hammer On',
    'p': 'Pull Off',
    '/': 'Slide Up',
    '\\': 'Slide Down',
    'b': 'Bend',
    'r': 'Release',
    'v': 'Vibrato',
    't': 'Tap',
    'x': 'Mute',
    '~': 'Vibrato',
    '<>': 'Natural Harmonic',
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
    // Start with 16 columns (a reasonable bar length)
    for (int i = 0; i < 16; i++) {
      section.bars[0].addColumn();
    }
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
      );

  String toJsonString() => jsonEncode(toJson());

  factory GuitarTab.fromJsonString(String jsonString) =>
      GuitarTab.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  String toTabFormat() {
    final buffer = StringBuffer();
    buffer.writeln('Song: $songName');
    buffer.writeln('Tuning: $tuning');
    buffer.writeln();

    for (final section in sections) {
      if (section.label != null && section.label!.isNotEmpty) {
        buffer.writeln('[${section.label}]');
      }

      // Pre-calculate column widths for each bar
      final barColumnWidths = <List<int>>[];
      for (final bar in section.bars) {
        final widths = <int>[];
        for (final column in bar.columns) {
          int maxLen = 1;
          for (final note in column.notes) {
            if (note.length > maxLen) maxLen = note.length;
          }
          widths.add(maxLen);
        }
        barColumnWidths.add(widths);
      }

      // Build each string line across all bars
      for (int stringIdx = 0; stringIdx < section.stringCount; stringIdx++) {
        final stringName = section.stringNames[stringIdx].padRight(2);
        buffer.write('$stringName|');

        for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
          final bar = section.bars[barIdx];
          final widths = barColumnWidths[barIdx];

          for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
            final note = bar.columns[colIdx].notes[stringIdx];
            final width = widths[colIdx];

            // Pad note to match column width (pad with dashes on right)
            buffer.write(note.padRight(width, '-'));
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
      buffer.writeln('Legend:');
      for (final entry in usedSymbols.entries) {
        buffer.writeln('  ${entry.key} = ${entry.value}');
      }
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
        // Parse tab line
        final match = RegExp(r'^([A-Ga-g#b]?)\|(.+)$').firstMatch(trimmed);
        if (match != null) {
          final stringName = match.group(1) ?? '';
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

    // Parse each bar
    for (final barContent in barContents) {
      final bar = TabMeasure(stringCount: stringNames.length);

      // Parse notes from each string for this bar
      final parsedNotes = <List<String>>[];
      for (final content in barContent) {
        parsedNotes.add(_parseNotesFromString(content));
      }

      // Find the maximum number of notes in any string
      int maxNotes = 0;
      for (final notes in parsedNotes) {
        if (notes.length > maxNotes) maxNotes = notes.length;
      }

      // Build columns from parsed notes
      for (int colIdx = 0; colIdx < maxNotes; colIdx++) {
        final column = TabColumn(stringNames.length);
        for (int stringIdx = 0; stringIdx < parsedNotes.length; stringIdx++) {
          if (colIdx < parsedNotes[stringIdx].length) {
            column.notes[stringIdx] = parsedNotes[stringIdx][colIdx];
          }
        }
        bar.columns.add(column);
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

  /// Parse a string of tab content into individual notes
  static List<String> _parseNotesFromString(String content) {
    final notes = <String>[];
    int pos = 0;

    while (pos < content.length) {
      final char = content[pos];

      // Skip padding dashes between notes
      if (char == '-') {
        // Check if this dash is padding or an actual empty note
        // It's padding if the previous note exists and next char is also a note
        if (notes.isNotEmpty && pos + 1 < content.length) {
          final nextChar = content[pos + 1];
          if (nextChar == '-' || RegExp(r'[\d<x]').hasMatch(nextChar)) {
            // This might be padding, check if we should skip
            // Count consecutive dashes
            int dashCount = 0;
            int tempPos = pos;
            while (tempPos < content.length && content[tempPos] == '-') {
              dashCount++;
              tempPos++;
            }
            // If there's something after the dashes, these are padding
            if (tempPos < content.length && dashCount > 0) {
              pos = tempPos;
              continue;
            }
          }
        }
        notes.add('-');
        pos++;
        continue;
      }

      // Parse harmonic <number>
      if (char == '<') {
        int endPos = pos + 1;
        while (endPos < content.length && content[endPos] != '>') {
          endPos++;
        }
        if (endPos < content.length) {
          notes.add(content.substring(pos, endPos + 1));
          pos = endPos + 1;
          continue;
        }
      }

      // Parse number (fret)
      if (RegExp(r'\d').hasMatch(char)) {
        String note = char;
        pos++;

        // Continue reading digits
        while (pos < content.length && RegExp(r'\d').hasMatch(content[pos])) {
          note += content[pos];
          pos++;
        }

        // Check for technique modifiers after the number
        while (pos < content.length && RegExp(r'[hpbr/\\~vt()]').hasMatch(content[pos])) {
          note += content[pos];
          pos++;
          // For slides, also capture the target fret
          if (content[pos - 1] == '/' || content[pos - 1] == '\\') {
            while (pos < content.length && RegExp(r'\d').hasMatch(content[pos])) {
              note += content[pos];
              pos++;
            }
          }
        }

        notes.add(note);
        continue;
      }

      // Parse technique symbols that can appear alone (x for mute, etc.)
      if (RegExp(r'[xX]').hasMatch(char)) {
        notes.add(char);
        pos++;
        continue;
      }

      // Skip any other characters
      pos++;
    }

    return notes;
  }
}
