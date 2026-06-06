import 'dart:ui';

import 'package:flame/components.dart';

import 'grid.dart';

class PlayerComponent extends PositionComponent {
  final Grid grid;
  int gridCol;
  int gridRow;

  double moveDuration = 0.15;
  int maxBombs = 1;
  int blastRadius = 1;

  bool _moving = false;
  late Vector2 _moveStart;
  late Vector2 _moveTarget;
  double _moveElapsed = 0;
  final List<(int, int)> _path = [];

  static final _paint = Paint()..color = const Color(0xFF00BCD4);

  PlayerComponent(this.grid, {required this.gridCol, required this.gridRow})
      : super(
          position: Vector2(gridCol * kTileSize, gridRow * kTileSize),
          size: Vector2.all(kTileSize),
        );

  void setDestination(List<(int, int)> path) {
    _path
      ..clear()
      ..addAll(path);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_moving) {
      _moveElapsed += dt;
      if (_moveElapsed >= moveDuration) {
        position = _moveTarget.clone();
        _moving = false;
      } else {
        final t = _moveElapsed / moveDuration;
        position = Vector2(
          _moveStart.x + (_moveTarget.x - _moveStart.x) * t,
          _moveStart.y + (_moveTarget.y - _moveStart.y) * t,
        );
      }
      return;
    }
    if (_path.isNotEmpty) {
      final (nextCol, nextRow) = _path.first;
      if (tryMove(nextCol - gridCol, nextRow - gridRow)) {
        _path.removeAt(0);
      } else {
        _path.clear();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect().deflate(4), _paint);
  }

  bool tryMove(int dc, int dr) {
    if (_moving) return false;
    final newCol = gridCol + dc;
    final newRow = gridRow + dr;
    if (!grid.isWalkable(newCol, newRow)) return false;
    _moveStart = position.clone();
    _moveTarget = Vector2(newCol * kTileSize, newRow * kTileSize);
    _moveElapsed = 0;
    _moving = true;
    gridCol = newCol;
    gridRow = newRow;
    return true;
  }
}
