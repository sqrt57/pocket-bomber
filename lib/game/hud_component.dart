import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

class BombButtonComponent extends PositionComponent with TapCallbacks {
  final void Function() onPressed;

  static const double _radius = 22;

  BombButtonComponent({required this.onPressed, required Vector2 center})
      : super(
          position: center - Vector2.all(_radius),
          size: Vector2.all(_radius * 2),
        );

  @override
  bool containsLocalPoint(Vector2 point) {
    final dx = point.x - _radius;
    final dy = point.y - _radius;
    return dx * dx + dy * dy <= _radius * _radius;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()..color = const Color(0xFFCC3300),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'B',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(_radius - tp.width / 2, _radius - tp.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
