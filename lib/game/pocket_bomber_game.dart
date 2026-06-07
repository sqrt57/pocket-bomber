import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'bomb.dart';
import 'enemy.dart';
import 'exit_component.dart';
import 'explosion.dart';
import 'grid.dart';
import 'grid_component.dart';
import 'hud_component.dart';
import 'player.dart';
import 'powerup.dart';

const int kMaxEnemies = 3;
const int kTotalEnemies = 10;
const int kStartLives = 3;

class PocketBomberGame extends FlameGame with TapCallbacks {
  late Grid grid;
  late Vector2 gridOffset;
  late PlayerComponent player;
  late GridComponent _gridComponent;

  int _activeBombs = 0;
  int _totalSpawned = 0;
  int _totalKilled = 0;
  final List<EnemyComponent> _enemies = [];

  int _score = 0;
  int _lives = kStartLives;

  bool _playerDead = false;
  double _deathTimer = 0;
  static const double _deathDelay = 0.6;

  bool _playerWon = false;
  bool _gameOver = false;
  _WinOverlay? _winOverlay;
  _GameOverOverlay? _gameOverOverlay;

  bool _exitSpawned = false;
  ExitComponent? _exitComponent;

  final _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gridOffset = Vector2((size.x - kCols * kTileSize) / 2, kHudHeight);
    add(HudComponent(
      gameWidth: size.x,
      getScore: () => _score,
      getLives: () => _lives,
      getKills: () => _totalKilled,
    ));
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
    _playerWon = false;
    _gameOver = false;
    _exitSpawned = false;
    _exitComponent = null;
    _enemies.clear();

    for (var i = 0; i < kMaxEnemies; i++) {
      _spawnEnemy();
    }
  }

  void _restartLevel() {
    _gridComponent.removeFromParent();
    _enemies.clear();
    _init();
  }

  void _startNewGame() {
    _winOverlay?.removeFromParent();
    _winOverlay = null;
    _gameOverOverlay?.removeFromParent();
    _gameOverOverlay = null;
    _lives = kStartLives;
    _score = 0;
    _gridComponent.removeFromParent();
    _enemies.clear();
    _init();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_playerWon || _gameOver) return;
    if (_playerDead) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDelay) {
        _playerDead = false;
        if (_lives > 0) {
          _restartLevel();
        } else {
          _showGameOver();
        }
      }
      return;
    }
    _checkEnemyTouch();
    _checkPowerupPickup();
    _checkExitReached();
  }

  void _checkExitReached() {
    final exit = _exitComponent;
    if (exit == null) return;
    if (player.gridCol == exit.gridCol && player.gridRow == exit.gridRow) {
      _onPlayerWon();
    }
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
    if (_playerDead || _playerWon || _gameOver) return;
    _placeBomb(player.gridCol, player.gridRow);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_playerWon || _gameOver) {
      _startNewGame();
      return;
    }
    if (_playerDead) return;
    final pos = event.canvasPosition;
    final col = ((pos.x - gridOffset.x) / kTileSize).floor();
    final row = ((pos.y - gridOffset.y) / kTileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return;
    if (!grid.isWalkable(col, row)) return;
    player.setDestination(_bfsPath(player.gridCol, player.gridRow, col, row));
  }

  List<(int, int)> _bfsPath(
      int startCol, int startRow, int targetCol, int targetRow) {
    if (startCol == targetCol && startRow == targetRow) return [];
    final visited = <(int, int), (int, int)?>{(startCol, startRow): null};
    final queue = Queue<(int, int)>()..add((startCol, startRow));
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    while (queue.isNotEmpty) {
      final (col, row) = queue.removeFirst();
      if (col == targetCol && row == targetRow) {
        final path = <(int, int)>[];
        var cur = (col, row);
        while (visited[cur] != null) {
          path.add(cur);
          cur = visited[cur]!;
        }
        return path.reversed.toList();
      }
      for (final (dc, dr) in dirs) {
        final nc = col + dc;
        final nr = row + dr;
        if (!grid.isWalkable(nc, nr)) continue;
        if (visited.containsKey((nc, nr))) continue;
        visited[(nc, nr)] = (col, row);
        queue.add((nc, nr));
      }
    }
    return [];
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

    final killed = _enemies
        .where((e) => blastTiles.contains((e.gridCol, e.gridRow)))
        .toList();
    for (final e in killed) {
      e.removeFromParent();
      _enemies.remove(e);
      _totalKilled++;
      _score += 100;
      _spawnEnemy();
    }

    if (!_playerDead && blastTiles.contains((player.gridCol, player.gridRow))) {
      _onPlayerDied();
    }

    if (!_exitSpawned && _totalKilled >= kTotalEnemies && !_playerDead) {
      _spawnExit();
    }

    for (final b in toChain) {
      b.trigger();
    }
  }

  void _spawnExit() {
    _exitSpawned = true;
    (int, int)? best;
    var bestDist = -1;
    for (var row = 0; row < kRows; row++) {
      for (var col = 0; col < kCols; col++) {
        if (!grid.isWalkable(col, row)) continue;
        final d =
            (col - player.gridCol).abs() + (row - player.gridRow).abs();
        if (d > bestDist) {
          bestDist = d;
          best = (col, row);
        }
      }
    }
    if (best == null) return;
    final (col, row) = best;
    _exitComponent = ExitComponent(gridCol: col, gridRow: row);
    _gridComponent.add(_exitComponent!);
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
    _lives--;
    _playerDead = true;
    _deathTimer = 0;
  }

  void _showGameOver() {
    _gameOver = true;
    _gameOverOverlay = _GameOverOverlay(gameSize: size, score: _score);
    add(_gameOverOverlay!);
  }

  void _onPlayerWon() {
    _playerWon = true;
    _winOverlay = _WinOverlay(gameSize: size, score: _score);
    add(_winOverlay!);
  }
}

class _WinOverlay extends Component {
  _WinOverlay({required this.gameSize, required this.score});
  final Vector2 gameSize;
  final int score;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      Paint()..color = const Color(0x99000000),
    );
    _drawCentered(canvas, 'YOU WIN!', 48, const Color(0xFFFFD700), -40);
    _drawCentered(canvas, 'Score: $score', 24, const Color(0xFFFFFFFF), 20);
    _drawCentered(canvas, 'Tap to play again', 18, const Color(0xFFCCCCCC), 60);
  }

  void _drawCentered(
      Canvas canvas, String text, double size, Color color, double dy) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style:
            TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (gameSize.x - tp.width) / 2,
        gameSize.y / 2 + dy - tp.height / 2,
      ),
    );
  }
}

class _GameOverOverlay extends Component {
  _GameOverOverlay({required this.gameSize, required this.score});
  final Vector2 gameSize;
  final int score;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      Paint()..color = const Color(0x99000000),
    );
    _drawCentered(canvas, 'GAME OVER', 48, const Color(0xFFFF4444), -40);
    _drawCentered(canvas, 'Score: $score', 24, const Color(0xFFFFFFFF), 20);
    _drawCentered(canvas, 'Tap to play again', 18, const Color(0xFFCCCCCC), 60);
  }

  void _drawCentered(
      Canvas canvas, String text, double size, Color color, double dy) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style:
            TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (gameSize.x - tp.width) / 2,
        gameSize.y / 2 + dy - tp.height / 2,
      ),
    );
  }
}
