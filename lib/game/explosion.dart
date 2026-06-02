import 'dart:ui';

import 'package:flame/components.dart';

import 'grid.dart';

class ExplosionComponent extends PositionComponent {
  final List<(int, int)> tiles;

  double _elapsed = 0;
  static const double _duration = 0.4;

  ExplosionComponent(this.tiles)
      : super(size: Vector2(kCols * kTileSize, kRows * kTileSize));

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - _elapsed / _duration) * 255).round().clamp(0, 255);
    final paint = Paint()..color = Color.fromARGB(alpha, 255, 109, 0);
    for (final (col, row) in tiles) {
      canvas.drawRect(
        Rect.fromLTWH(
          col * kTileSize + 1,
          row * kTileSize + 1,
          kTileSize - 2,
          kTileSize - 2,
        ),
        paint,
      );
    }
  }
}
