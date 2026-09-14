import 'dart:ui';

import '../../models/index.dart';
import 'family_relationship_service.dart';

/// Tính toạ độ node cho sơ đồ cây — tách khỏi widget để unit test độc lập
/// trước khi render (không phụ thuộc Flutter framework rendering).
///
/// Xử lý BOTTOM-UP theo từng generation (hàng Y), từ đời cuối lên đời gốc:
/// vị trí X mong muốn của 1 người = trung bình vị trí X các CON đã có toạ
/// độ CHỐT (ở hàng dưới, đã xử lý xong) — nhờ vậy cha/mẹ tự "căn giữa" theo
/// TOÀN BỘ nhánh con cháu bên dưới thay vì chỉ nhìn 1 chiều từ trên xuống,
/// giảm xô lệch tích luỹ qua nhiều đời. Người không có con (đời cuối, hoặc
/// chưa ghi nhận con) dùng vị trí kề vợ/chồng hoặc thứ tự xuất hiện làm
/// phương án dự phòng. Mỗi hàng đều được "quét" đảm bảo khoảng cách tối
/// thiểu giữa các node liền kề để không chồng chéo.
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
    final sortedGenerationsDesc = byGeneration.keys.toList()..sort((a, b) => b.compareTo(a));

    final positions = <String, Offset>{};

    for (final gen in sortedGenerationsDesc) {
      final peopleInGen = byGeneration[gen]!;
      // Cụm [người-vợ/chồng] cạnh nhau trong thứ tự duyệt — giữ nguyên ý
      // định hiển thị 1 cặp sát nhau kể cả khi phải tính lại vị trí X.
      final ordered = _clusterBySpouse(
        _sortForRow(peopleInGen, persons, relationships),
        persons,
        relationships,
      );

      final desiredX = <String, double>{};

      // Bước 1: người có con đã định vị (hàng dưới) → trung bình X các con.
      for (final p in ordered) {
        final children = FamilyRelationshipService.childrenOf(p.id, persons, relationships);
        final childXs = children.map((c) => positions[c.id]?.dx).whereType<double>().toList();
        if (childXs.isNotEmpty) {
          desiredX[p.id] = childXs.reduce((a, b) => a + b) / childXs.length;
        }
      }

      // Bước 2: người chưa có desiredX (không con/con chưa định vị) —
      // bám theo vợ/chồng đã có desiredX (giữ cặp cạnh nhau), nếu không thì
      // xếp tuần tự làm phương án dự phòng.
      var fallbackCursor = 0.0;
      for (final p in ordered) {
        if (desiredX.containsKey(p.id)) continue;
        final spouses = FamilyRelationshipService.spousesOf(p.id, persons, relationships);
        final anchoredSpouse = spouses.where((s) => desiredX.containsKey(s.id)).firstOrNull;
        desiredX[p.id] = anchoredSpouse != null ? desiredX[anchoredSpouse.id]! : fallbackCursor;
        fallbackCursor += nodeSpacingX;
      }

      // Bước 3: sắp theo desiredX (tie-break theo thứ tự cụm để cặp vợ
      // chồng cùng desiredX vẫn đứng cạnh nhau ổn định), rồi quét đảm bảo
      // khoảng cách tối thiểu — chỉ đẩy sang phải, không chồng lên node đã
      // chốt bên trái.
      final indexOf = {for (var i = 0; i < ordered.length; i++) ordered[i].id: i};
      final rowOrder = ordered.toList()
        ..sort((a, b) {
          final cmp = desiredX[a.id]!.compareTo(desiredX[b.id]!);
          return cmp != 0 ? cmp : indexOf[a.id]!.compareTo(indexOf[b.id]!);
        });

      double? prevX;
      for (final p in rowOrder) {
        var x = desiredX[p.id]!;
        if (prevX != null && x < prevX + nodeSpacingX) {
          x = prevX + nodeSpacingX;
        }
        positions[p.id] = Offset(x, gen * rowSpacingY);
        prevX = x;
      }
    }

    return positions;
  }

  /// Chỉ dùng ngày sinh của người TRỰC HỆ (có cha/mẹ ghi nhận trong cây) để
  /// quyết định thứ tự hàng — vợ/chồng "married-in" (không có cha/mẹ trong
  /// cây) KHÔNG được dùng ngày sinh riêng để tự kéo cặp đi đâu cả, tránh
  /// trường hợp 1 người rể/dâu lớn tuổi hơn làm lệch thứ tự anh/chị/em ruột
  /// của người kia. Vợ/chồng vẫn được _clusterBySpouse cụm cạnh người trực
  /// hệ như cũ — chỉ không tham gia bước SẮP THỨ TỰ này.
  static List<Person> _sortForRow(
    List<Person> peopleInGen,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final core = <Person>[];
    final others = <Person>[];
    for (final p in peopleInGen) {
      final hasParent =
          FamilyRelationshipService.parentsOf(p.id, persons, relationships).isNotEmpty;
      (hasParent ? core : others).add(p);
    }
    if (core.isEmpty) {
      // Không ai trong hàng có cha/mẹ ghi nhận (vd đời gốc/tổ tiên đầu
      // tiên) — không có cơ sở phân biệt trực hệ với "married-in", coi tất
      // cả là trực hệ để vẫn sắp theo ngày sinh bình thường thay vì bỏ qua
      // hẳn ngày sinh của mọi người trong hàng.
      return _sortByBirthDate(peopleInGen);
    }
    return [..._sortByBirthDate(core), ...others];
  }

  /// Người cùng hàng: có ngày sinh thì xếp theo ngày sinh (nhỏ → lớn, anh/
  /// chị lớn bên trái) trước, chưa rõ ngày sinh thì xếp SAU CÙNG (theo
  /// đúng thứ tự đã tạo/nhập giữa họ với nhau) — không xen kẽ người chưa rõ
  /// ngày vào giữa người đã biết ngày để tránh so sánh "đã biết vs chưa
  /// biết" (không có nghĩa, có thể phá tính bắc cầu của thứ tự sắp xếp).
  static List<Person> _sortByBirthDate(List<Person> people) {
    final indexOf = {for (var i = 0; i < people.length; i++) people[i].id: i};
    return people.toList()
      ..sort((a, b) {
        final aDate = a.birthDate;
        final bDate = b.birthDate;
        if (aDate != null && bDate != null) {
          final cmp = aDate.compareTo(bDate);
          if (cmp != 0) return cmp;
        } else if ((aDate != null) != (bDate != null)) {
          return aDate != null ? -1 : 1;
        }
        return indexOf[a.id]!.compareTo(indexOf[b.id]!);
      });
  }

  /// Trong từng cụm vợ/chồng, LUÔN xếp (các) chồng bên trái (các) vợ — đa
  /// thê/đa phu/tái hôn thì nhiều người cùng phía được xếp theo đúng thứ
  /// tự [Relationship.startDate] (cưới trước đứng gần người kia hơn), lấy
  /// từ [FamilyRelationshipService.marriagesOf] đã sắp sẵn — KHÔNG dùng
  /// `List.sort` để trộn nam/nữ vì sort của Dart không đảm bảo ổn định, có
  /// thể xáo trộn mất thứ tự cưới trước/sau giữa những người cùng giới.
  static List<Person> _clusterBySpouse(
    List<Person> peopleInGen,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final ordered = <Person>[];
    final remaining = {for (final p in peopleInGen) p.id: p};
    for (final p in peopleInGen) {
      if (!remaining.containsKey(p.id)) continue;
      remaining.remove(p.id);
      final spouseIdsByMarriageOrder = FamilyRelationshipService.marriagesOf(p.id, relationships)
          .map((r) => r.personAId == p.id ? r.personBId : r.personAId);
      final spouses = spouseIdsByMarriageOrder.map((id) => remaining.remove(id)).whereType<Person>();
      final cluster = p.gender == Gender.male ? [p, ...spouses] : [...spouses, p];
      ordered.addAll(cluster);
    }
    return ordered;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
