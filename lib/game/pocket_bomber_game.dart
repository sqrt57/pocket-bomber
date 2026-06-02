import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'bomb.dart';
import 'explosion.dart';
import 'grid.dart';
import 'grid_component.dart';
import 'player.dart';

class PocketBomberGame extends FlameGame with TapCallbacks {
  late final Grid grid;
  late final Vector2 gridOffset;
  late final PlayerComponent player;
  late final GridComponent _gridComponent;
  int _activeBombs = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    grid = Grid.generate();
    gridOffset = Vector2((size.x - kCols * kTileSize) / 2, kHudHeight);
    _gridComponent = GridComponent(grid)..position = gridOffset;
    add(_gridComponent);
    player = PlayerComponent(grid, gridCol: 0, gridRow: 0);
    _gridComponent.add(player);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.canvasPosition;
    final col = ((pos.x - gridOffset.x) / kTileSize).floor();
    final row = ((pos.y - gridOffset.y) / kTileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return;

    if (col == player.gridCol && row == player.gridRow) {
      _placeBomb(col, row);
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

  void _placeBomb(int col, int row) {
    if (_activeBombs >= 1) return;
    _activeBombs++;
    _gridComponent.add(
      BombComponent(gridCol: col, gridRow: row, onExplode: _handleBombExplosion),
    );
  }

  void _handleBombExplosion(BombComponent bomb) {
    final blastTiles = <(int, int)>[];
    final toChain = <BombComponent>[];

    blastTiles.add((bomb.gridCol, bomb.gridRow));

    const directions = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    for (final (dc, dr) in directions) {
      for (var i = 1; i <= bomb.blastRadius; i++) {
        final col = bomb.gridCol + dc * i;
        final row = bomb.gridRow + dr * i;
        if (col < 0 || col >= kCols || row < 0 || row >= kRows) break;
        final tile = grid.at(col, row);
        if (tile == TileType.hardWall) break;
        blastTiles.add((col, row));
        if (tile == TileType.softWall) {
          grid.setTile(col, row, TileType.floor);
          break;
        }
        final chainBomb = _findBomb(col, row);
        if (chainBomb != null) {
          toChain.add(chainBomb);
          break;
        }
      }
    }

    bomb.removeFromParent();
    _activeBombs--;
    _gridComponent.add(ExplosionComponent(blastTiles));

    for (final b in toChain) {
      b.trigger();
    }
  }

  BombComponent? _findBomb(int col, int row) {
    for (final child in _gridComponent.children) {
      if (child is BombComponent && child.gridCol == col && child.gridRow == row) {
        return child;
      }
    }
    return null;
  }
}
