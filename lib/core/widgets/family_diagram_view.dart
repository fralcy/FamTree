import 'package:flutter/material.dart';

import '../../models/index.dart';
import '../utils/tree_layout_calculator.dart';

/// Sơ đồ cây pan/zoom (InteractiveViewer) — node chỉ hiện tên tóm tắt, tap
/// node mở modal xem/sửa. Dùng chung cho mobile (sau 1 nút "Xem sơ đồ") và
/// desktop (hiển thị mặc định).
class FamilyDiagramView extends StatelessWidget {
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

  static const double _nodeWidth = 120;
  static const double _nodeHeight = 56;
  static const double _padding = 80;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return const SizedBox.shrink();
    }

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    final maxX = positions.values.map((o) => o.dx).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = positions.values.map((o) => o.dy).fold<double>(0, (a, b) => a > b ? a : b);

    return InteractiveViewer(
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
        width: maxX + _nodeWidth + _padding * 2,
        height: maxY + _nodeHeight + _padding * 2,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(maxX + _nodeWidth + _padding * 2, maxY + _nodeHeight + _padding * 2),
              painter: _DiagramEdgesPainter(
                persons: persons,
                relationships: relationships,
                positions: positions,
                padding: _padding,
                nodeWidth: _nodeWidth,
                nodeHeight: _nodeHeight,
              ),
            ),
            for (final person in persons)
              Positioned(
                left: (positions[person.id]?.dx ?? 0) + _padding,
                top: (positions[person.id]?.dy ?? 0) + _padding,
                width: _nodeWidth,
                height: _nodeHeight,
                child: _PersonNode(person: person, onTap: () => onTapPerson(person.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonNode extends StatelessWidget {
  const _PersonNode({required this.person, required this.onTap});

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDeceased = person.isDeceased;
    return Material(
      color: isDeceased ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
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
              style: TextStyle(color: colorScheme.onPrimaryContainer),
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

  @override
  void paint(Canvas canvas, Size size) {
    final marriagePaint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2;
    final parentChildPaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2;

    for (final r in relationships) {
      if (r.type == RelationshipType.marriage) {
        canvas.drawLine(_center(r.personAId), _center(r.personBId), marriagePaint);
      } else {
        final parentCenter = _center(r.personAId);
        final childCenter = _center(r.personBId);
        final midY = (parentCenter.dy + childCenter.dy) / 2;
        final path = Path()
          ..moveTo(parentCenter.dx, parentCenter.dy)
          ..lineTo(parentCenter.dx, midY)
          ..lineTo(childCenter.dx, midY)
          ..lineTo(childCenter.dx, childCenter.dy);
        canvas.drawPath(path, parentChildPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramEdgesPainter oldDelegate) {
    return oldDelegate.persons != persons ||
        oldDelegate.relationships != relationships ||
        oldDelegate.positions != positions;
  }
}
