import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

import 'grid.dart';

class PowerupComponent extends PositionComponent {
  final PowerupType type;

  static final _paints = {
    PowerupType.extraBomb: Paint()..color = const Color(0xFFFFEB3B),
    PowerupType.blastRadius: Paint()..color = const Color(0xFFFF5722),
    PowerupType.speed: Paint()..color = const Color(0xFF4CAF50),
  };

  static const _labels = {
    PowerupType.extraBomb: 'B',
    PowerupType.blastRadius: 'R',
    PowerupType.speed: 'S',
  };

  static final _textPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFF000000),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  PowerupComponent({
    required this.type,
    required int gridCol,
    required int gridRow,
  }) : super(
         position: Vector2(gridCol * kTileSize, gridRow * kTileSize),
         size: Vector2.all(kTileSize),
       );

  int get gridCol => (position.x / kTileSize).round();
  int get gridRow => (position.y / kTileSize).round();

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect().deflate(6), _paints[type]!);
    _textPaint.render(
      canvas,
      _labels[type]!,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}
