import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool isActive;
  final ConfettiType type;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.isActive,
    this.type = ConfettiType.win,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

enum ConfettiType { win, blackjack, lose }

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Defer callback to avoid setState during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles.clear();

    final particleCount = switch (widget.type) {
      ConfettiType.blackjack => 100,
      ConfettiType.win => 60,
      ConfettiType.lose => 20,
    };

    final colors = switch (widget.type) {
      ConfettiType.blackjack => [
          Colors.amber,
          Colors.yellow,
          Colors.orange,
          Colors.white,
          Colors.greenAccent,
        ],
      ConfettiType.win => [
          Colors.green,
          Colors.lightGreen,
          Colors.greenAccent,
          Colors.white,
        ],
      ConfettiType.lose => [
          Colors.red.shade300,
          Colors.grey,
        ],
    };

    for (int i = 0; i < particleCount; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        velocityX: (_random.nextDouble() - 0.5) * 0.3,
        velocityY: _random.nextDouble() * 0.3 + 0.2,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        size: _random.nextDouble() * 10 + 5,
        color: colors[_random.nextInt(colors.length)],
        shape: ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if not active or animation finished
    if (!widget.isActive || _controller.isCompleted || _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

enum ConfettiShape { circle, square, rectangle, star }

class ConfettiParticle {
  double x;
  double y;
  final double velocityX;
  final double velocityY;
  double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final ConfettiShape shape;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = (particle.x + particle.velocityX * progress) * size.width;
      final y = (particle.y + particle.velocityY * progress + 0.5 * progress * progress) * size.height;
      final rotation = particle.rotation + particle.rotationSpeed * progress;
      final opacity = (1 - progress * 0.7).clamp(0.0, 1.0);

      if (y > size.height + 50 || y < -50) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;
        case ConfettiShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size / 2,
            ),
            paint,
          );
          break;
        case ConfettiShape.star:
          _drawStar(canvas, particle.size / 2, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class CoinShower extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onComplete;

  const CoinShower({
    super.key,
    required this.isActive,
    this.onComplete,
  });

  @override
  State<CoinShower> createState() => _CoinShowerState();
}

class _CoinShowerState extends State<CoinShower>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<CoinParticle> _coins = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Defer callback to avoid setState during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void didUpdateWidget(CoinShower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateCoins();
      _controller.forward(from: 0);
    }
  }

  void _generateCoins() {
    _coins.clear();
    for (int i = 0; i < 30; i++) {
      _coins.add(CoinParticle(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.3,
        speed: 0.3 + _random.nextDouble() * 0.4,
        wobble: (_random.nextDouble() - 0.5) * 0.2,
        size: 20 + _random.nextDouble() * 15,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render if not active or animation finished
    if (!widget.isActive || _controller.isCompleted || _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CoinPainter(
            coins: _coins,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class CoinParticle {
  final double x;
  final double delay;
  final double speed;
  final double wobble;
  final double size;

  CoinParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.wobble,
    required this.size,
  });
}

class CoinPainter extends CustomPainter {
  final List<CoinParticle> coins;
  final double progress;

  CoinPainter({required this.coins, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      final adjustedProgress = ((progress - coin.delay) / (1 - coin.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final x = (coin.x + math.sin(adjustedProgress * math.pi * 4) * coin.wobble) * size.width;
      final y = adjustedProgress * size.height * coin.speed + (adjustedProgress * adjustedProgress * size.height * 0.5);
      final opacity = (1 - adjustedProgress * 0.5).clamp(0.0, 1.0);

      if (y > size.height + 50) continue;

      // Draw coin
      final coinPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Colors.amber.shade300.withValues(alpha: opacity),
            Colors.amber.shade600.withValues(alpha: opacity),
            Colors.amber.shade800.withValues(alpha: opacity),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: coin.size / 2));

      canvas.drawCircle(Offset(x, y), coin.size / 2, coinPaint);

      // Draw dollar sign
      final textPainter = TextPainter(
        text: TextSpan(
          text: '\$',
          style: TextStyle(
            color: Colors.amber.shade900.withValues(alpha: opacity),
            fontSize: coin.size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CoinPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
