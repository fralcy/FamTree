/// Non-web platforms không bao giờ gọi hàm này — [FilePicker.platform.saveFile]
/// đã hoạt động đúng trên io/windows/macos/linux.
void saveFileWeb(String fileName, String content) {
  throw UnsupportedError('saveFileWeb chỉ dùng trên nền tảng web.');
}
