import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import 'grid.dart';

class HudComponent extends Component {
  final double gameWidth;
  final int Function() getScore;
  final int Function() getLives;
  final int Function() getKills;

  HudComponent({
    required this.gameWidth,
    required this.getScore,
    required this.getLives,
    required this.getKills,
  });

  static final _bgPaint = Paint()..color = const Color(0xFF1A1A2E);
  static const _style = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, gameWidth, kHudHeight), _bgPaint);
    _draw(canvas, 'Lives: ${getLives()}', const Offset(8, 17));
    _drawCentered(canvas, 'Score: ${getScore()}');
    _draw(canvas, 'Kills: ${getKills()}/10', Offset(gameWidth - 96, 17));
  }

  void _draw(Canvas canvas, String text, Offset offset) {
    (TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, offset);
  }

  void _drawCentered(Canvas canvas, String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((gameWidth - tp.width) / 2, 17));
  }
}

class BombButtonComponent extends PositionComponent with TapCallbacks {
  final void Function() onPressed;

  static const double _radius = 22;

  BombButtonComponent({required this.onPressed, required Vector2 center})
      : super(
          position: center - Vector2.all(_radius),
          size: Vector2.all(_radius * 2),
        );

  @override
  bool containsLocalPoint(Vector2 point) {
    final dx = point.x - _radius;
    final dy = point.y - _radius;
    return dx * dx + dy * dy <= _radius * _radius;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()..color = const Color(0xFFCC3300),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'B',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(_radius - tp.width / 2, _radius - tp.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
