import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'bomb.dart';
import 'enemy.dart';
import 'explosion.dart';
import 'grid.dart';
import 'grid_component.dart';
import 'hud_component.dart';
import 'player.dart';
import 'powerup.dart';

const int kMaxEnemies = 3;
const int kTotalEnemies = 10;

class PocketBomberGame extends FlameGame with TapCallbacks {
  late Grid grid;
  late Vector2 gridOffset;
  late PlayerComponent player;
  late GridComponent _gridComponent;

  int _activeBombs = 0;
  int _totalSpawned = 0;
  int _totalKilled = 0;
  final List<EnemyComponent> _enemies = [];

  bool _playerDead = false;
  double _deathTimer = 0;
  static const double _deathDelay = 0.6;

  final _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gridOffset = Vector2((size.x - kCols * kTileSize) / 2, kHudHeight);
    add(BombButtonComponent(
      onPressed: _onBombButtonPressed,
      center: Vector2(
        gridOffset.x + kCols * kTileSize - 30,
        kHudHeight + kRows * kTileSize + 35,
      ),
    ));
    _init();
  }

  void _init() {
    grid = Grid.generate();
    _gridComponent = GridComponent(grid)..position = gridOffset;
    add(_gridComponent);
    player = PlayerComponent(grid, gridCol: 0, gridRow: 0);
    _gridComponent.add(player);

    _activeBombs = 0;
    _totalSpawned = 0;
    _totalKilled = 0;
    _playerDead = false;
    _deathTimer = 0;
    _enemies.clear();

    for (var i = 0; i < kMaxEnemies; i++) {
      _spawnEnemy();
    }
  }

  void _restart() {
    _gridComponent.removeFromParent();
    _enemies.clear();
    _init();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_playerDead) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDelay) _restart();
      return;
    }
    _checkEnemyTouch();
    _checkPowerupPickup();
  }

  void _checkEnemyTouch() {
    for (final enemy in _enemies) {
      if (enemy.gridCol == player.gridCol && enemy.gridRow == player.gridRow) {
        _onPlayerDied();
        return;
      }
    }
  }

  void _onBombButtonPressed() {
    if (_playerDead) return;
    _placeBomb(player.gridCol, player.gridRow);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_playerDead) return;
    final pos = event.canvasPosition;
    final col = ((pos.x - gridOffset.x) / kTileSize).floor();
    final row = ((pos.y - gridOffset.y) / kTileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return;

    final dc = col - player.gridCol;
    final dr = row - player.gridRow;
    if (dc.abs() >= dr.abs()) {
      player.tryMove(dc.sign, 0);
    } else {
      player.tryMove(0, dr.sign);
    }
  }

  void _placeBomb(int col, int row) {
    if (_activeBombs >= player.maxBombs) return;
    _activeBombs++;
    _gridComponent.add(
      BombComponent(
        gridCol: col,
        gridRow: row,
        blastRadius: player.blastRadius,
        onExplode: _handleBombExplosion,
      ),
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
          final powerup = grid.takePowerup(col, row);
          if (powerup != null) {
            _gridComponent.add(
              PowerupComponent(type: powerup, gridCol: col, gridRow: row),
            );
          }
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

    // Kill enemies caught in the blast
    final killed = _enemies
        .where((e) => blastTiles.contains((e.gridCol, e.gridRow)))
        .toList();
    for (final e in killed) {
      e.removeFromParent();
      _enemies.remove(e);
      _totalKilled++;
      _spawnEnemy();
    }

    // Kill player if caught in the blast
    if (!_playerDead && blastTiles.contains((player.gridCol, player.gridRow))) {
      _onPlayerDied();
    }

    for (final b in toChain) {
      b.trigger();
    }
  }

  void _spawnEnemy() {
    if (_totalSpawned >= kTotalEnemies) return;
    final pos = _findSpawnPosition();
    if (pos == null) return;
    final (col, row) = pos;
    final enemy = EnemyComponent(grid: grid, gridCol: col, gridRow: row);
    _gridComponent.add(enemy);
    _enemies.add(enemy);
    _totalSpawned++;
  }

  (int, int)? _findSpawnPosition() {
    final candidates = <(int, int)>[];
    for (var row = 0; row < kRows; row++) {
      for (var col = 0; col < kCols; col++) {
        if (!grid.isWalkable(col, row)) continue;
        final distToPlayer =
            (col - player.gridCol).abs() + (row - player.gridRow).abs();
        if (distToPlayer < 4) continue;
        if (_enemies.any((e) => e.gridCol == col && e.gridRow == row)) continue;
        candidates.add((col, row));
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }

  BombComponent? _findBomb(int col, int row) {
    for (final child in _gridComponent.children) {
      if (child is BombComponent &&
          child.gridCol == col &&
          child.gridRow == row) {
        return child;
      }
    }
    return null;
  }

  void _checkPowerupPickup() {
    for (final child in _gridComponent.children.toList()) {
      if (child is PowerupComponent &&
          child.gridCol == player.gridCol &&
          child.gridRow == player.gridRow) {
        child.removeFromParent();
        _applyPowerup(child.type);
        break;
      }
    }
  }

  void _applyPowerup(PowerupType type) {
    switch (type) {
      case PowerupType.extraBomb:
        player.maxBombs++;
      case PowerupType.blastRadius:
        player.blastRadius++;
      case PowerupType.speed:
        player.moveDuration *= 0.75;
    }
  }

  void _onPlayerDied() {
    _playerDead = true;
    _deathTimer = 0;
  }
}
