import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seville',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TapGame _game = TapGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _game.reset,
                  child: const Text('Reset'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap the plumbob to make it spin a little faster each time.
class TapGame extends FlameGame {
  late final Plumbob _plumbob;

  @override
  Color backgroundColor() => const Color(0xFF1A1228);

  @override
  Future<void> onLoad() async {
    _plumbob = Plumbob()
      ..anchor = Anchor.center
      ..position = size / 2;
    add(_plumbob);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _plumbob.position = size / 2;
    }
  }

  void reset() => _plumbob.reset();
}

/// A green Sims-style plumbob that spins around its vertical axis.
/// The 3D spin is faked by squashing the diamond horizontally over time.
class Plumbob extends PositionComponent with TapCallbacks {
  Plumbob() : super(size: Vector2(120, 170));

  static const double _baseSpeed = 0.4; // radians/sec — a slow idle spin
  static const double _speedPerTap = 0.18; // gentle bump per click

  double _spin = 0; // accumulated rotation angle
  double _speed = _baseSpeed;

  @override
  void update(double dt) {
    super.update(dt);
    _spin += _speed * dt;
  }

  void reset() {
    _speed = _baseSpeed;
    _spin = 0;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _speed += _speedPerTap;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final hh = size.y / 2;
    final cosA = cos(_spin);
    final hw = (size.x / 2) * cosA; // shrinks to 0 when edge-on, then mirrors

    // Brighter when a face points at us, dimmer when seen edge-on.
    final facing = cosA.abs();
    final fill = Color.lerp(
      const Color(0xFF1F6B2E),
      const Color(0xFF66FF8C),
      facing,
    )!;

    final diamond = Path()
      ..moveTo(cx, cy - hh)
      ..lineTo(cx + hw, cy)
      ..lineTo(cx, cy + hh)
      ..lineTo(cx - hw, cy)
      ..close();

    // Soft glow behind the crystal.
    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xFF66FF8C).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    canvas.drawPath(diamond, Paint()..color = fill);

    // A vertical highlight down the center for a glassy look.
    canvas.drawPath(
      diamond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.25 + 0.35 * facing),
    );
  }
}
