import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;

/// [file_picker] 8.x KHÔNG triển khai `saveFile()` trên web (luôn ném
/// UnimplementedError — xem file_picker_web.dart) — tự tải file qua Blob +
/// thẻ <a download> thay vì phụ thuộc file_picker cho bước này.
void saveFileWeb(String fileName, String content) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
