import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChipData {
  final int value;
  final Color primaryColor;
  final Color accentColor;

  const ChipData({
    required this.value,
    required this.primaryColor,
    required this.accentColor,
  });

  static const List<ChipData> standardChips = [
    ChipData(value: 5, primaryColor: Color(0xFFD32F2F), accentColor: Color(0xFFFF5252)),
    ChipData(value: 25, primaryColor: Color(0xFF388E3C), accentColor: Color(0xFF66BB6A)),
    ChipData(value: 100, primaryColor: Color(0xFF1976D2), accentColor: Color(0xFF42A5F5)),
    ChipData(value: 500, primaryColor: Color(0xFF7B1FA2), accentColor: Color(0xFFAB47BC)),
  ];
}

class PokerChipButton extends StatefulWidget {
  final ChipData chipData;
  final VoidCallback? onTap;
  final bool enabled;

  const PokerChipButton({
    super.key,
    required this.chipData,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PokerChipButton> createState() => _PokerChipButtonState();
}

class _PokerChipButtonState extends State<PokerChipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;

    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.enabled ? 1.0 : 0.4,
                child: _buildChip(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            widget.chipData.accentColor,
            widget.chipData.primaryColor,
            widget.chipData.primaryColor.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: widget.chipData.accentColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: ChipPatternPainter(
          primaryColor: widget.chipData.primaryColor,
          accentColor: widget.chipData.accentColor,
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: widget.chipData.primaryColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '\$${widget.chipData.value}',
                style: TextStyle(
                  color: widget.chipData.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.chipData.value >= 100 ? 10 : 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChipPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  ChipPatternPainter({required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw edge notches
    final notchPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final innerRadius = radius - 6;
      final outerRadius = radius - 2;

      final startX = center.dx + innerRadius * math.cos(angle);
      final startY = center.dy + innerRadius * math.sin(angle);
      final endX = center.dx + outerRadius * math.cos(angle);
      final endY = center.dy + outerRadius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), notchPaint);
    }

    // Draw inner ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 10, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChipStack extends StatelessWidget {
  final int amount;
  final bool animate;

  const ChipStack({
    super.key,
    required this.amount,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = _calculateChips(amount);
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: chips.map((chip) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildMiniChipStack(chip.chipData, chip.count),
          );
        }).toList(),
      ),
    );
  }

  List<({ChipData chipData, int count})> _calculateChips(int amount) {
    final result = <({ChipData chipData, int count})>[];
    int remaining = amount;

    for (final chipData in ChipData.standardChips.reversed) {
      final count = remaining ~/ chipData.value;
      if (count > 0) {
        result.add((chipData: chipData, count: count.clamp(0, 5)));
        remaining -= count * chipData.value;
      }
    }

    return result.reversed.toList();
  }

  Widget _buildMiniChipStack(ChipData data, int count) {
    return SizedBox(
      width: 32,
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(
          count.clamp(0, 5),
          (index) => Positioned(
            bottom: index * 6.0,
            child: Container(
              width: 28,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    data.accentColor,
                    data.primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedChipCounter extends StatefulWidget {
  final int chips;
  final Duration duration;

  const AnimatedChipCounter({
    super.key,
    required this.chips,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedChipCounter> createState() => _AnimatedChipCounterState();
}

class _AnimatedChipCounterState extends State<AnimatedChipCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.chips;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.chips.toDouble(),
      end: widget.chips.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedChipCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chips != widget.chips) {
      _previousValue = oldWidget.chips;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.chips.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.round();
        final isIncreasing = widget.chips > _previousValue;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade700,
                Colors.amber.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.shade900.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: Colors.yellow.shade100,
                size: 22,
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _controller.isAnimating ? 20 : 18,
                  color: _controller.isAnimating
                      ? (isIncreasing ? Colors.greenAccent : Colors.redAccent)
                      : Colors.white,
                ),
                child: Text('\$$value'),
              ),
            ],
          ),
        );
      },
    );
  }
}
