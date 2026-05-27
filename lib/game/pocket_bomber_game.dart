import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'grid.dart';
import 'grid_component.dart';

class PocketBomberGame extends FlameGame with TapCallbacks {
  late final Grid grid;
  late final Vector2 gridOffset;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    grid = Grid.generate();
    gridOffset = Vector2((size.x - kCols * kTileSize) / 2, kHudHeight);
    final gridComponent = GridComponent(grid)..position = gridOffset;
    add(gridComponent);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.canvasPosition;
    final col = ((pos.x - gridOffset.x) / kTileSize).floor();
    final row = ((pos.y - gridOffset.y) / kTileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return;
    // Stage 2: move or place bomb based on (col, row) relative to player
  }
}
