import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'grid.dart';
import 'grid_component.dart';
import 'player.dart';

class PocketBomberGame extends FlameGame with TapCallbacks {
  late final Grid grid;
  late final Vector2 gridOffset;
  late final PlayerComponent player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    grid = Grid.generate();
    gridOffset = Vector2((size.x - kCols * kTileSize) / 2, kHudHeight);
    final gridComponent = GridComponent(grid)..position = gridOffset;
    add(gridComponent);
    player = PlayerComponent(grid, gridCol: 0, gridRow: 0);
    gridComponent.add(player);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.canvasPosition;
    final col = ((pos.x - gridOffset.x) / kTileSize).floor();
    final row = ((pos.y - gridOffset.y) / kTileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return;

    if (col == player.gridCol && row == player.gridRow) {
      // tap on player → place bomb (Stage 3)
      return;
    }

    final dc = col - player.gridCol;
    final dr = row - player.gridRow;
    if (dc.abs() >= dr.abs()) {
      player.tryMove(dc.sign, 0);
    } else {
      player.tryMove(0, dr.sign);
    }
  }
}
