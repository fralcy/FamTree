import 'dart:ui';

import '../../models/index.dart';
import 'family_relationship_service.dart';

/// Tính toạ độ node cho sơ đồ cây — tách khỏi widget để unit test độc lập
/// trước khi render (không phụ thuộc Flutter framework rendering).
///
/// Hàng Y = generation. Vị trí X gom nhóm theo hộ gia đình: 1 người + vợ/
/// chồng của họ nằm sát nhau, con cái xếp ngay dưới và căn giữa theo đoạn
/// nối giữa cha mẹ. MVP chấp nhận vẫn có thể chồng chéo ở cây rất rộng/
/// nhiều đời — không cần thuật toán chống chồng chéo hoàn hảo.
class TreeLayoutCalculator {
  const TreeLayoutCalculator._();

  static const double nodeSpacingX = 160;
  static const double rowSpacingY = 140;

  static Map<String, Offset> computeNodePositions(
    List<Person> persons,
    List<Relationship> relationships,
    Map<String, int> generationMap,
  ) {
    if (persons.isEmpty) return {};

    final byGeneration = <int, List<Person>>{};
    for (final p in persons) {
      final gen = generationMap[p.id] ?? 0;
      byGeneration.putIfAbsent(gen, () => []).add(p);
    }

    final visitedInOrder = <String>{};
    final orderedByGeneration = <int, List<Person>>{};

    final sortedGenerations = byGeneration.keys.toList()..sort();
    for (final gen in sortedGenerations) {
      final peopleInGen = byGeneration[gen]!;
      final ordered = <Person>[];
      final remaining = {for (final p in peopleInGen) p.id: p};

      // Gom cluster [người-vợ/chồng] cạnh nhau: duyệt từng người, nếu chưa
      // xếp thì xếp luôn kèm theo vợ/chồng của họ (nếu vợ/chồng cùng
      // generation này), rồi mới sang cặp tiếp theo.
      for (final p in peopleInGen) {
        if (!remaining.containsKey(p.id)) continue;
        ordered.add(remaining.remove(p.id)!);
        final spouses = FamilyRelationshipService.spousesOf(p.id, persons, relationships);
        for (final spouse in spouses) {
          final stillRemaining = remaining.remove(spouse.id);
          if (stillRemaining != null) ordered.add(stillRemaining);
        }
      }
      orderedByGeneration[gen] = ordered;
      visitedInOrder.addAll(ordered.map((p) => p.id));
    }

    final positions = <String, Offset>{};
    for (final gen in sortedGenerations) {
      final ordered = orderedByGeneration[gen]!;
      for (var i = 0; i < ordered.length; i++) {
        positions[ordered[i].id] = Offset(i * nodeSpacingX, gen * rowSpacingY);
      }
    }

    // Căn giữa con cái theo đoạn nối cha mẹ: gom con theo cùng bộ cha/mẹ,
    // đặt cả cụm anh chị em đó đối xứng quanh trung điểm X của cha/mẹ (giữ
    // khoảng cách đều nhau giữa các anh chị em trong cùng cụm).
    for (final gen in sortedGenerations) {
      if (gen == sortedGenerations.first) continue;
      final ordered = orderedByGeneration[gen]!;

      final groups = <String, List<Person>>{};
      for (final child in ordered) {
        final parents = FamilyRelationshipService.parentsOf(child.id, persons, relationships);
        if (parents.isEmpty) continue;
        final key = (parents.map((p) => p.id).toList()..sort()).join(',');
        groups.putIfAbsent(key, () => []).add(child);
      }

      for (final siblings in groups.values) {
        final parents =
            FamilyRelationshipService.parentsOf(siblings.first.id, persons, relationships);
        final parentXs =
            parents.map((p) => positions[p.id]?.dx).whereType<double>().toList();
        if (parentXs.isEmpty) continue;
        final centerX = parentXs.reduce((a, b) => a + b) / parentXs.length;

        final n = siblings.length;
        for (var i = 0; i < n; i++) {
          final offsetX = (i - (n - 1) / 2) * nodeSpacingX;
          final old = positions[siblings[i].id]!;
          positions[siblings[i].id] = Offset(centerX + offsetX, old.dy);
        }
      }
    }

    return positions;
  }
}
