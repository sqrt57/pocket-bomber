import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'grid.dart';

class EnemyComponent extends PositionComponent {
  final Grid grid;
  int gridCol;
  int gridRow;

  static const double _moveDuration = 0.25;
  static const double _thinkInterval = 0.7;

  bool _moving = false;
  late Vector2 _moveStart;
  late Vector2 _moveTarget;
  double _moveElapsed = 0;
  double _thinkElapsed = 0;

  final Random _rng;

  static final _paint = Paint()..color = const Color(0xFFE53935);

  EnemyComponent({
    required this.grid,
    required this.gridCol,
    required this.gridRow,
    Random? rng,
  })  : _rng = rng ?? Random(),
        super(
          position: Vector2(gridCol * kTileSize, gridRow * kTileSize),
          size: Vector2.all(kTileSize),
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (_moving) {
      _moveElapsed += dt;
      if (_moveElapsed >= _moveDuration) {
        position = _moveTarget.clone();
        _moving = false;
      } else {
        final t = _moveElapsed / _moveDuration;
        position = Vector2(
          _moveStart.x + (_moveTarget.x - _moveStart.x) * t,
          _moveStart.y + (_moveTarget.y - _moveStart.y) * t,
        );
      }
      return;
    }

    _thinkElapsed += dt;
    if (_thinkElapsed < _thinkInterval) return;
    _thinkElapsed = 0;
    _wander();
  }

  void _wander() {
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    final shuffled = [...dirs]..shuffle(_rng);
    for (final (dc, dr) in shuffled) {
      final nc = gridCol + dc;
      final nr = gridRow + dr;
      if (grid.isWalkable(nc, nr)) {
        _moveStart = position.clone();
        _moveTarget = Vector2(nc * kTileSize, nr * kTileSize);
        _moveElapsed = 0;
        _moving = true;
        gridCol = nc;
        gridRow = nr;
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect().deflate(6), _paint);
  }
}
