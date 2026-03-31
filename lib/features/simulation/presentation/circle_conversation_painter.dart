import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/protocol.dart';

class CircleConversationPainter extends CustomPainter {
  CircleConversationPainter({
    required this.peopleCount,
    required this.batch,
    required this.colorScheme,
    required this.textStyle,
  });

  final int peopleCount;
  final BatchExecution? batch;
  final ColorScheme colorScheme;
  final TextStyle textStyle;

  static const double _personRadius = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (peopleCount < 2) {
      return;
    }

    final positions = _personPositions(size);
    _drawGuideRing(canvas, size);

    if (batch != null) {
      _drawBatch(canvas, positions, batch!);
    }

    _drawPeople(canvas, positions);
  }

  @override
  bool shouldRepaint(covariant CircleConversationPainter oldDelegate) {
    return oldDelegate.peopleCount != peopleCount ||
        oldDelegate.batch != batch ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.textStyle != textStyle;
  }

  List<Offset> _personPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;

    return List<Offset>.generate(peopleCount, (index) {
      final angle = (-pi / 2) + (2 * pi * index / peopleCount);
      return center + Offset(cos(angle) * radius, sin(angle) * radius);
    });
  }

  void _drawGuideRing(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;

    final ringPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, ringPaint);
  }

  void _drawBatch(Canvas canvas, List<Offset> positions, BatchExecution batch) {
    final groupedTurns = <PairId, List<MessageTurn>>{};
    for (final turn in batch.turns) {
      groupedTurns.putIfAbsent(turn.pair, () => <MessageTurn>[]).add(turn);
    }

    for (final entry in groupedTurns.entries) {
      final turns = entry.value;
      for (var turnIndex = 0; turnIndex < turns.length; turnIndex++) {
        final turn = turns[turnIndex];
        final centeredOffset = turnIndex - ((turns.length - 1) / 2);

        final start = positions[turn.from];
        final end = positions[turn.to];
        _drawTurn(
          canvas,
          start: start,
          end: end,
          text: turn.text,
          lateralOffset: centeredOffset * 14,
          lineColor: colorScheme.primary.withValues(alpha: 0.8),
        );
      }
    }
  }

  void _drawTurn(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required String text,
    required double lateralOffset,
    required Color lineColor,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance < 1) {
      return;
    }

    final direction = delta / distance;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final shiftedStart = start + perpendicular * lateralOffset;
    final shiftedEnd = end + perpendicular * lateralOffset;

    final lineStart = shiftedStart + direction * (_personRadius + 3);
    final lineEnd = shiftedEnd - direction * (_personRadius + 3);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(lineStart, lineEnd, linePaint);

    final arrowTip = lineEnd;
    final arrowBase = arrowTip - direction * 10;
    final wingA = arrowBase + perpendicular * 5;
    final wingB = arrowBase - perpendicular * 5;
    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(wingA.dx, wingA.dy)
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(wingB.dx, wingB.dy);
    canvas.drawPath(arrowPath, linePaint);

    final bubbleCenter =
        Offset(
          (lineStart.dx + lineEnd.dx) / 2,
          (lineStart.dy + lineEnd.dy) / 2,
        ) +
        perpendicular * 20;

    final bubbleText = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 130);

    final bubbleRect = Rect.fromCenter(
      center: bubbleCenter,
      width: bubbleText.width + 14,
      height: bubbleText.height + 8,
    );

    final bubblePaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8)),
      bubblePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8)),
      borderPaint,
    );

    bubbleText.paint(
      canvas,
      Offset(
        bubbleRect.left + (bubbleRect.width - bubbleText.width) / 2,
        bubbleRect.top + (bubbleRect.height - bubbleText.height) / 2,
      ),
    );
  }

  void _drawPeople(Canvas canvas, List<Offset> positions) {
    for (var i = 0; i < positions.length; i++) {
      final center = positions[i];
      final fillPaint = Paint()
        ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = colorScheme.secondary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, _personRadius, fillPaint);
      canvas.drawCircle(center, _personRadius, borderPaint);

      final icon = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.person.codePoint),
          style: textStyle.copyWith(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontFamily: Icons.person.fontFamily,
            package: Icons.person.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      icon.paint(
        canvas,
        Offset(center.dx - icon.width / 2, center.dy - icon.height / 2 - 4),
      );

      final label = TextPainter(
        text: TextSpan(
          text: 'P${i + 1}',
          style: textStyle.copyWith(
            color: colorScheme.onSurface,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(canvas, Offset(center.dx - label.width / 2, center.dy + 3));
    }
  }
}
