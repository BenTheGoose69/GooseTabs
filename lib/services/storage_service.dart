import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/tab_model.dart';
import '../models/folder_model.dart';

class StorageService {
  static const String _tabsKey = 'saved_tabs';
  static const String _foldersKey = 'folders';
  static final Uuid _uuid = Uuid();

  static String generateId() => _uuid.v4();

  static Future<List<GuitarTab>> loadAllTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final tabsJson = prefs.getStringList(_tabsKey) ?? [];

    return tabsJson.map((json) {
      try {
        return GuitarTab.fromJsonString(json);
      } catch (e) {
        return null;
      }
    }).whereType<GuitarTab>().toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  static Future<void> saveTab(GuitarTab tab) async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = await loadAllTabs();

    final existingIndex = tabs.indexWhere((t) => t.id == tab.id);
    if (existingIndex >= 0) {
      tabs[existingIndex] = tab;
    } else {
      tabs.add(tab);
    }

    final tabsJson = tabs.map((t) => t.toJsonString()).toList();
    await prefs.setStringList(_tabsKey, tabsJson);
  }

  static Future<void> deleteTab(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = await loadAllTabs();

    tabs.removeWhere((t) => t.id == id);

    final tabsJson = tabs.map((t) => t.toJsonString()).toList();
    await prefs.setStringList(_tabsKey, tabsJson);
  }

  static Future<GuitarTab?> getTab(String id) async {
    final tabs = await loadAllTabs();
    try {
      return tabs.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportTabToFile(GuitarTab tab) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${tab.songName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_tab.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(tab.toTabFormat());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${tab.songName} - Guitar Tab',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> downloadTabToDownloads(GuitarTab tab) async {
    try {
      final fileName =
          '${tab.songName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_tab.txt';

      // Try to get the Downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // On Android, use the public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to external storage
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            downloadsDir = Directory('${extDir.path}/Download');
            await downloadsDir.create(recursive: true);
          }
        }
      } else if (Platform.isIOS) {
        // On iOS, use the documents directory (accessible via Files app)
        downloadsDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // On desktop, find the Downloads folder
        final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (home != null) {
          downloadsDir = Directory('$home/Downloads');
        }
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        // Final fallback to documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(tab.toTabFormat());

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String> exportTabAsText(GuitarTab tab) async {
    return tab.toTabFormat();
  }

  static Future<String?> exportTabToFileWithStructure(GuitarTab tab, String customStructure) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${tab.songName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_tab.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(tab.toTabFormatWithStructure(customStructure));

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${tab.songName} - Guitar Tab',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> downloadTabToDownloadsWithStructure(GuitarTab tab, String customStructure) async {
    try {
      final fileName =
          '${tab.songName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_tab.txt';

      // Try to get the Downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // On Android, use the public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to external storage
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            downloadsDir = Directory('${extDir.path}/Download');
            await downloadsDir.create(recursive: true);
          }
        }
      } else if (Platform.isIOS) {
        // On iOS, use the documents directory (accessible via Files app)
        downloadsDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // On desktop, find the Downloads folder
        final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (home != null) {
          downloadsDir = Directory('$home/Downloads');
        }
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        // Final fallback to documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(tab.toTabFormatWithStructure(customStructure));

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<GuitarTab?> importTabFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'tab'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      return GuitarTab.fromTabFormat(content, generateId());
    } catch (e) {
      return null;
    }
  }

  static Future<GuitarTab?> importTabFromText(String content) async {
    try {
      return GuitarTab.fromTabFormat(content, generateId());
    } catch (e) {
      return null;
    }
  }

  // Folder methods

  static Future<List<TabFolder>> loadAllFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getStringList(_foldersKey) ?? [];

    return foldersJson.map((json) {
      try {
        return TabFolder.fromJsonString(json);
      } catch (e) {
        return null;
      }
    }).whereType<TabFolder>().toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Future<void> saveFolder(TabFolder folder) async {
    final prefs = await SharedPreferences.getInstance();
    final folders = await loadAllFolders();

    final existingIndex = folders.indexWhere((f) => f.id == folder.id);
    if (existingIndex >= 0) {
      folders[existingIndex] = folder;
    } else {
      folders.add(folder);
    }

    final foldersJson = folders.map((f) => f.toJsonString()).toList();
    await prefs.setStringList(_foldersKey, foldersJson);
  }

  static Future<void> deleteFolder(String folderId) async {
    final prefs = await SharedPreferences.getInstance();

    // Move all tabs in this folder to root (unfiled)
    final tabs = await loadAllTabs();
    for (final tab in tabs) {
      if (tab.folderId == folderId) {
        tab.folderId = null;
        await saveTab(tab);
      }
    }

    // Remove the folder
    final folders = await loadAllFolders();
    folders.removeWhere((f) => f.id == folderId);

    final foldersJson = folders.map((f) => f.toJsonString()).toList();
    await prefs.setStringList(_foldersKey, foldersJson);
  }

  static Future<void> moveTabToFolder(String tabId, String? folderId) async {
    final tab = await getTab(tabId);
    if (tab != null) {
      tab.folderId = folderId;
      await saveTab(tab);
    }
  }
}
