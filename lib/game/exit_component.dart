import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'grid.dart';

class ExitComponent extends PositionComponent {
  final int gridCol;
  final int gridRow;

  static final _bgPaint = Paint()..color = const Color(0xFF4CAF50);

  ExitComponent({required this.gridCol, required this.gridRow})
      : super(
          position: Vector2(gridCol * kTileSize, gridRow * kTileSize),
          size: Vector2.all(kTileSize),
        );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect().deflate(3), _bgPaint);
    final laid = TextPainter(
      text: const TextSpan(
        text: 'EXIT',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    laid.paint(
      canvas,
      Offset((kTileSize - laid.width) / 2, (kTileSize - laid.height) / 2),
    );
  }
}
