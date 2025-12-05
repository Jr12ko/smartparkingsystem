// Web-specific file operations
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Download a file in web browser
void downloadFileWeb(String content, String fileName) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Stub for desktop - not used on web
void saveFileDesktop(String path, String content) {
  // Not used on web
}
