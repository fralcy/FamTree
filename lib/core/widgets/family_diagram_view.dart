import 'package:flutter/material.dart';

import '../../models/index.dart';
import '../utils/tree_layout_calculator.dart';

/// Sơ đồ cây pan/zoom (InteractiveViewer) — node chỉ hiện tên tóm tắt, tap
/// node mở modal xem/sửa. Dùng chung cho mobile (sau 1 nút "Xem sơ đồ") và
/// desktop (hiển thị mặc định).
///
/// Con có ĐỦ 2 cha/mẹ ruột VÀ 2 người đó có hôn nhân ghi nhận với nhau →
/// nối vào ĐƯỜNG HÔN NHÂN giữa họ (1 đường từ điểm giữa xuống con) thay vì
/// nối riêng 2 đường tới từng người — chỉ nối riêng khi ngoài giá thú
/// (không có hôn nhân giữa 2 cha/mẹ ruột), con nuôi/con riêng, hoặc chỉ có
/// 1 cha/mẹ được ghi nhận.
class FamilyDiagramView extends StatefulWidget {
  const FamilyDiagramView({
    super.key,
    required this.persons,
    required this.relationships,
    required this.generationMap,
    required this.onTapPerson,
  });

  final List<Person> persons;
  final List<Relationship> relationships;
  final Map<String, int> generationMap;
  final void Function(String personId) onTapPerson;

  static const double nodeWidth = 120;
  static const double nodeHeight = 56;
  static const double padding = 120;

  @override
  State<FamilyDiagramView> createState() => _FamilyDiagramViewState();
}

class _FamilyDiagramViewState extends State<FamilyDiagramView> {
  final TransformationController _transformationController = TransformationController();
  bool _centered = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FamilyDiagramView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cây khác (đổi personId tập hợp hoàn toàn) → cho canh giữa lại từ đầu.
    if (oldWidget.persons.isEmpty && widget.persons.isNotEmpty) {
      _centered = false;
    }
  }

  void _centerContent(BoxConstraints constraints, double contentWidth, double contentHeight) {
    if (_centered) return;
    _centered = true;
    final dx = (constraints.maxWidth - contentWidth) / 2;
    final dy = (constraints.maxHeight - contentHeight) / 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transformationController.value = Matrix4.identity()..translateByDouble(dx, dy, 0, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.persons.isEmpty) {
      return const SizedBox.shrink();
    }

    final positions = TreeLayoutCalculator.computeNodePositions(
      widget.persons,
      widget.relationships,
      widget.generationMap,
    );

    final maxX = positions.values.map((o) => o.dx).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = positions.values.map((o) => o.dy).fold<double>(0, (a, b) => a > b ? a : b);
    final contentWidth = maxX + FamilyDiagramView.nodeWidth + FamilyDiagramView.padding * 2;
    final contentHeight = maxY + FamilyDiagramView.nodeHeight + FamilyDiagramView.padding * 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        _centerContent(constraints, contentWidth, contentHeight);
        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          minScale: 0.15,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(600),
          child: SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(contentWidth, contentHeight),
                  painter: _DiagramEdgesPainter(
                    persons: widget.persons,
                    relationships: widget.relationships,
                    positions: positions,
                    padding: FamilyDiagramView.padding,
                    nodeWidth: FamilyDiagramView.nodeWidth,
                    nodeHeight: FamilyDiagramView.nodeHeight,
                  ),
                ),
                for (final person in widget.persons)
                  Positioned(
                    left: (positions[person.id]?.dx ?? 0) + FamilyDiagramView.padding,
                    top: (positions[person.id]?.dy ?? 0) + FamilyDiagramView.padding,
                    width: FamilyDiagramView.nodeWidth,
                    height: FamilyDiagramView.nodeHeight,
                    child: _PersonNode(person: person, onTap: () => widget.onTapPerson(person.id)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonNode extends StatelessWidget {
  const _PersonNode({required this.person, required this.onTap});

  final Person person;
  final VoidCallback onTap;

  /// Cố định xanh dương/hồng theo giới tính (cliché nhưng dễ nhận ra ngay
  /// khi lướt mắt qua cây to) — KHÔNG lấy theo seed color của theme đang
  /// chọn, chỉ đổi sắc độ theo light/dark để chữ/viền luôn đọc rõ.
  Color _baseColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (person.gender == Gender.male) {
      return isDark ? Colors.blue.shade700 : Colors.blue.shade200;
    }
    return isDark ? Colors.pink.shade700 : Colors.pink.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = _baseColor(Theme.of(context).brightness);
    // Người mất: cùng tông nhưng nhạt hẳn đi (pha xám) thay vì đổi hẳn màu
    // khác — vẫn phân biệt được giới tính, chỉ "nhạt" đi để báo đã mất.
    final fillColor = person.isDeceased ? Color.lerp(baseColor, Colors.grey, 0.5)! : baseColor;
    final textColor = ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Material(
      color: fillColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              person.fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagramEdgesPainter extends CustomPainter {
  _DiagramEdgesPainter({
    required this.persons,
    required this.relationships,
    required this.positions,
    required this.padding,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final List<Person> persons;
  final List<Relationship> relationships;
  final Map<String, Offset> positions;
  final double padding;
  final double nodeWidth;
  final double nodeHeight;

  Offset _center(String personId) {
    final pos = positions[personId] ?? Offset.zero;
    return Offset(pos.dx + padding + nodeWidth / 2, pos.dy + padding + nodeHeight / 2);
  }

  /// personId -> record parentChild mà personId là con, CHỈ tính
  /// childType=biological — dùng để phát hiện cặp cha/mẹ ruột có hôn nhân.
  Map<String, List<Relationship>> get _biologicalParentEdgesByChild {
    final map = <String, List<Relationship>>{};
    for (final r in relationships) {
      if (r.type == RelationshipType.parentChild && r.childType == ChildType.biological) {
        map.putIfAbsent(r.personBId, () => []).add(r);
      }
    }
    return map;
  }

  Relationship? _marriageBetween(String personAId, String personBId) {
    for (final r in relationships) {
      if (r.type != RelationshipType.marriage) continue;
      final matches = (r.personAId == personAId && r.personBId == personBId) ||
          (r.personAId == personBId && r.personBId == personAId);
      if (matches) return r;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final marriagePaint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final parentChildPaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Con có đủ 2 cha/mẹ RUỘT đã kết hôn với nhau → nối vào đường hôn
    // nhân (điểm giữa), bỏ qua vẽ 2 đường riêng biological cho con đó.
    final consolidatedChildToMarriage = <String, Relationship>{};
    for (final entry in _biologicalParentEdgesByChild.entries) {
      if (entry.value.length != 2) continue;
      final marriage = _marriageBetween(entry.value[0].personAId, entry.value[1].personAId);
      if (marriage != null) {
        consolidatedChildToMarriage[entry.key] = marriage;
      }
    }

    for (final r in relationships) {
      if (r.type == RelationshipType.marriage) {
        final ended = r.endDate != null;
        if (ended) {
          _drawDashedLine(canvas, _center(r.personAId), _center(r.personBId), marriagePaint);
        } else {
          canvas.drawLine(_center(r.personAId), _center(r.personBId), marriagePaint);
        }
      }
    }

    for (final r in relationships) {
      if (r.type != RelationshipType.parentChild) continue;
      final isConsolidatedBiological =
          r.childType == ChildType.biological && consolidatedChildToMarriage.containsKey(r.personBId);
      if (isConsolidatedBiological) continue; // vẽ qua đường hôn nhân bên dưới
      _drawParentChildPath(canvas, _center(r.personAId), _center(r.personBId), parentChildPaint);
    }

    for (final entry in consolidatedChildToMarriage.entries) {
      final marriage = entry.value;
      final midpoint = Offset.lerp(_center(marriage.personAId), _center(marriage.personBId), 0.5)!;
      _drawParentChildPath(canvas, midpoint, _center(entry.key), parentChildPaint);
    }
  }

  void _drawParentChildPath(Canvas canvas, Offset parentPoint, Offset childCenter, Paint paint) {
    final midY = (parentPoint.dy + childCenter.dy) / 2;
    final path = Path()
      ..moveTo(parentPoint.dx, parentPoint.dy)
      ..lineTo(parentPoint.dx, midY)
      ..lineTo(childCenter.dx, midY)
      ..lineTo(childCenter.dx, childCenter.dy);
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashWidth = 6,
    double dashGap = 4,
  }) {
    final totalDistance = (p2 - p1).distance;
    if (totalDistance == 0) return;
    final direction = (p2 - p1) / totalDistance;
    var covered = 0.0;
    var start = p1;
    while (covered < totalDistance) {
      final segment = dashWidth < (totalDistance - covered) ? dashWidth : (totalDistance - covered);
      final end = start + direction * segment;
      canvas.drawLine(start, end, paint);
      covered += segment + dashGap;
      start = end + direction * dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramEdgesPainter oldDelegate) {
    return oldDelegate.persons != persons ||
        oldDelegate.relationships != relationships ||
        oldDelegate.positions != positions;
  }
}
