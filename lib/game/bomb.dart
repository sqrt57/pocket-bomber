import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

import 'grid.dart';

class BombComponent extends PositionComponent {
  final int gridCol;
  final int gridRow;
  final int blastRadius;
  final void Function(BombComponent) onExplode;

  double _elapsed = 0;
  bool _triggered = false;

  static const double _duration = 3.0;
  static final _bodyPaint = Paint()..color = const Color(0xFF1A1A1A);
  static final _fusePaint = Paint()..color = const Color(0xFFFF5722);
  static final _textPaint = TextPaint(
    style: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );

  BombComponent({
    required this.gridCol,
    required this.gridRow,
    required this.onExplode,
    this.blastRadius = 1,
  }) : super(
         position: Vector2(gridCol * kTileSize, gridRow * kTileSize),
         size: Vector2.all(kTileSize),
       );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (!_triggered && _elapsed >= _duration) {
      _triggered = true;
      onExplode(this);
    }
  }

  void trigger() {
    if (_triggered) return;
    _triggered = true;
    onExplode(this);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 4,
      _bodyPaint,
    );
    canvas.drawCircle(Offset(size.x * 0.65, size.y * 0.22), 3, _fusePaint);
    final remaining = (_duration - _elapsed).ceil().clamp(0, 3);
    _textPaint.render(
      canvas,
      '$remaining',
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}
