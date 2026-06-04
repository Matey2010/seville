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

/// A tiny game: tap the moving ball to score. It speeds up each hit.
class TapGame extends FlameGame {
  late final Ball _ball;
  late final TextComponent _scoreText;
  int _score = 0;

  @override
  Color backgroundColor() => const Color(0xFF1A1228);

  @override
  Future<void> onLoad() async {
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(16, 48),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_scoreText);

    _ball = Ball(onHit: _onHit)..position = size / 2;
    add(_ball);
  }

  void _onHit() {
    _score++;
    _scoreText.text = 'Score: $_score';
    _ball.speedUp();
  }

  void reset() {
    _score = 0;
    _scoreText.text = 'Score: 0';
    _ball.resetState(size / 2);
  }
}

class Ball extends CircleComponent with TapCallbacks {
  Ball({required this.onHit})
      : super(
          radius: 32,
          anchor: Anchor.center,
          paint: Paint()..color = Colors.amber,
        );

  final VoidCallback onHit;
  final Random _rng = Random();
  late Vector2 _velocity = _randomVelocity(180);

  Vector2 _randomVelocity(double speed) {
    final angle = _rng.nextDouble() * 2 * pi;
    return Vector2(cos(angle), sin(angle))..scale(speed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;

    // Bounce off the walls.
    final game = findGame()!;
    if (position.x - radius < 0 || position.x + radius > game.size.x) {
      _velocity.x = -_velocity.x;
      position.x = position.x.clamp(radius, game.size.x - radius);
    }
    if (position.y - radius < 0 || position.y + radius > game.size.y) {
      _velocity.y = -_velocity.y;
      position.y = position.y.clamp(radius, game.size.y - radius);
    }
  }

  void speedUp() {
    _velocity.scale(1.12);
  }

  void resetState(Vector2 center) {
    position = center;
    _velocity = _randomVelocity(180);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onHit();
  }
}
