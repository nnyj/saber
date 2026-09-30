import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';

class _Page implements HasSize {
  @override
  Size get size => const Size(1000, 1000);
}

void main() {
  const center = Offset(100, 100);
  const size = 5.0;

  Stroke makeStroke(
    List<(Offset, double?)> points, {
    required bool complete,
    double size = size,
  }) {
    final stroke = Stroke(
      color: Colors.black,
      pressureEnabled: true,
      options: StrokeOptions(size: size, isComplete: complete),
      pageIndex: 0,
      page: _Page(),
      toolId: .fountainPen,
    );
    for (final (point, pressure) in points) {
      stroke.addPoint(point, pressure);
    }
    return stroke;
  }

  final taps = <String, List<(Offset, double?)>>{
    '3 identical points': List.filled(3, (center, 0.5)),
    '5 identical points': List.filled(5, (center, 0.5)),
    '2 light points': [(center, 0.05), (center, 0.02)],
    '3 jittered points': [
      (center, 0.3),
      (center + const Offset(0.2, 0.1), 0.6),
      (center + const Offset(0.3, 0), 0.2),
    ],
    '4 points drifting under pen size': [
      for (var i = 0; i < 4; i++) (center + Offset(i * 1.5, i * 0.5), 0.5),
    ],
  };

  group('A tap is drawn as a visible round dot', () {
    for (final MapEntry(key: name, value: points) in taps.entries) {
      test(name, () {
        final boundsWhileDrawing = makeStroke(
          points,
          complete: false,
        ).highQualityPath.getBounds();
        final stroke = makeStroke(points, complete: true);
        expect(stroke.isDot, isTrue);
        for (final path in [stroke.lowQualityPath, stroke.highQualityPath]) {
          final bounds = path.getBounds();
          expect(bounds.width, greaterThanOrEqualTo(size / 2));
          expect(bounds.width, closeTo(bounds.height, 0.1));
          expect(bounds.size, boundsWhileDrawing.size);
        }
      });
    }
  });

  test('A short swipe with a wide pen is not a dot', () {
    final stroke = makeStroke(
      [for (var i = 0; i < 5; i++) (center + Offset(i * 10.0, 0), 0.5)],
      complete: true,
      size: 50,
    );
    expect(stroke.isDot, isFalse);
  });

  test('A long stroke is not a dot', () {
    final stroke = makeStroke([
      for (var i = 0; i < 20; i++) (center + Offset(i * 2.0, 0), 0.5),
    ], complete: true);
    expect(stroke.isDot, isFalse);
    expect(stroke.highQualityPath.getBounds().width, greaterThan(35));
  });
}
