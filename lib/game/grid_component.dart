import 'dart:ui';

import 'package:flame/components.dart';

import 'grid.dart';

class GridComponent extends PositionComponent {
  final Grid grid;

  static final _hardWallPaint = Paint()..color = const Color(0xFF424242);
  static final _softWallPaint = Paint()..color = const Color(0xFF8D6E63);
  static final _floorPaint = Paint()..color = const Color(0xFFBDBDBD);
  static final _bgPaint = Paint()..color = const Color(0xFF212121);

  GridComponent(this.grid)
      : super(size: Vector2(kCols * kTileSize, kRows * kTileSize));

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _bgPaint);
    for (var row = 0; row < kRows; row++) {
      for (var col = 0; col < kCols; col++) {
        final paint = switch (grid.at(col, row)) {
          TileType.hardWall => _hardWallPaint,
          TileType.softWall => _softWallPaint,
          TileType.floor => _floorPaint,
        };
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
}
