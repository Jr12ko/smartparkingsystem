// Desktop/mobile file operations
import 'dart:io';

/// Stub for web - not used on desktop
void downloadFileWeb(String content, String fileName) {
  // Not used on desktop/mobile
}

/// Save file on desktop/mobile platforms
void saveFileDesktop(String path, String content) {
  final file = File(path);
  file.writeAsStringSync(content);
}
