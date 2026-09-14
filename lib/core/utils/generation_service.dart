import 'dart:collection';

import '../../models/index.dart';
import '../models/generation_result.dart';

/// Tính "đời" (generation) cho mọi Person trong 1 FamilyTree.
///
/// Cài đặt bằng 1 BFS/worklist đa nguồn DUY NHẤT lan qua cả 2 loại cạnh
/// (parentChild: +1 đời; marriage: cùng đời) thay vì tách riêng "BFS huyết
/// thống" rồi "fixed-point loop cho vợ/chồng" — vì mỗi node chỉ được gán
/// generation đúng 1 lần (kiểm tra `generationOf.containsKey` trước khi
/// enqueue), thuật toán tự nhiên bị chặn bởi số lượng Person hữu hạn và
/// KHÔNG THỂ rơi vào vòng lặp vô tận, kể cả khi dữ liệu mâu thuẫn (ví dụ A
/// vừa là cha B vừa kết hôn với B) — cạnh nào xử lý trước sẽ thắng, cạnh
/// mâu thuẫn còn lại bị bỏ qua an toàn thay vì gây dao động hay treo app.
class GenerationService {
  const GenerationService._();

  static GenerationResult computeGenerations(
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final childIds = <String>{};
    final parentIds = <String>{};
    final childrenByParent = <String, List<String>>{};
    final spousesByPerson = <String, List<String>>{};

    for (final r in relationships) {
      if (r.type == RelationshipType.parentChild) {
        childIds.add(r.personBId);
        parentIds.add(r.personAId);
        childrenByParent.putIfAbsent(r.personAId, () => []).add(r.personBId);
      } else if (r.type == RelationshipType.marriage) {
        spousesByPerson.putIfAbsent(r.personAId, () => []).add(r.personBId);
        spousesByPerson.putIfAbsent(r.personBId, () => []).add(r.personAId);
      }
    }

    // Root chuẩn = không có cha/mẹ trong hệ thống VÀ thực sự là cha/mẹ của
    // ai đó. Riêng trường hợp người này lại kết hôn với 1 người CÓ cha/mẹ
    // trong cây (childIds chứa vợ/chồng đó) thì KHÔNG coi là root độc lập —
    // đây là spouse married-in vào 1 nhánh đã có huyết thống, generation
    // của họ phải lan theo huyết thống của vợ/chồng (bước BFS bên dưới),
    // không phải tự thành gốc 0 riêng (nếu không sẽ "khoá" sai generation
    // trước khi BFS kịp lan tới, như trường hợp dâu/rể có con riêng ghi
    // nhận trong cây).
    final rootCandidates = <String>[
      for (final p in persons)
        if (!childIds.contains(p.id) && parentIds.contains(p.id)) p.id,
    ];
    final rootIds = <String>[
      for (final id in rootCandidates)
        if (!(spousesByPerson[id] ?? const <String>[])
            .any((spouseId) => childIds.contains(spouseId)))
          id,
    ];

    final generationOf = <String, int>{for (final id in rootIds) id: 0};
    final queue = Queue<String>.from(rootIds);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentGen = generationOf[current]!;

      for (final child in childrenByParent[current] ?? const <String>[]) {
        if (!generationOf.containsKey(child)) {
          generationOf[child] = currentGen + 1;
          queue.add(child);
        }
      }
      for (final spouse in spousesByPerson[current] ?? const <String>[]) {
        if (!generationOf.containsKey(spouse)) {
          generationOf[spouse] = currentGen;
          queue.add(spouse);
        }
      }
    }

    // Nhánh cô lập (không root, không hôn phối resolve được) → generation 0.
    final unlinkedIds = <String>[];
    for (final p in persons) {
      if (!generationOf.containsKey(p.id)) {
        generationOf[p.id] = 0;
        unlinkedIds.add(p.id);
      }
    }

    return GenerationResult(
      generationOf: generationOf,
      rootIds: rootIds,
      unlinkedIds: unlinkedIds,
    );
  }
}
