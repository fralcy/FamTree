/// Kết quả tính "đời" (generation) cho 1 FamilyTree — value type derived,
/// tạo mới mỗi lần build từ [GenerationService], không persist vào Hive.
class GenerationResult {
  const GenerationResult({
    required this.generationOf,
    required this.rootIds,
    required this.unlinkedIds,
  });

  /// personId -> generation (0 = root/gốc của nhánh).
  final Map<String, int> generationOf;

  /// Person là gốc huyết thống thật sự (có con, không có cha mẹ trong cây).
  final List<String> rootIds;

  /// Person không thể resolve generation qua huyết thống lẫn hôn nhân
  /// (nhánh cô lập, hoặc dữ liệu mâu thuẫn khiến fixed-point loop không hội
  /// tụ) — được gán tạm generation 0, UI có thể hiển thị cảnh báo riêng.
  final List<String> unlinkedIds;
}
