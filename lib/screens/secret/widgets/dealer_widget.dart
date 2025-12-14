import 'dart:async';
import 'package:flutter/material.dart';

class DealerWidget extends StatefulWidget {
  final String? message;
  final bool isThinking;
  final bool isDealing;

  const DealerWidget({
    super.key,
    this.message,
    this.isThinking = false,
    this.isDealing = false,
  });

  @override
  State<DealerWidget> createState() => _DealerWidgetState();
}

class _DealerWidgetState extends State<DealerWidget>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _dealController;
  late Animation<double> _bobAnimation;
  late Animation<double> _dealRotation;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _dealController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dealRotation = Tween<double>(begin: 0, end: -0.1).animate(
      CurvedAnimation(parent: _dealController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DealerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDealing && !oldWidget.isDealing) {
      _dealController.forward().then((_) => _dealController.reverse());
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _dealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message != null) ...[
          SpeechBubble(
            message: widget.message!,
            isThinking: widget.isThinking,
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: Listenable.merge([_bobController, _dealController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bobAnimation.value),
              child: Transform.rotate(
                angle: _dealRotation.value,
                child: _buildDealerAvatar(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDealerAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade500,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Face
          Positioned(
            top: 12,
            child: Container(
              width: 40,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDEB887),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Dealer hat
          Positioned(
            top: 0,
            child: Container(
              width: 48,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(),
                const SizedBox(width: 10),
                _buildEye(),
              ],
            ),
          ),
          // Smile
          Positioned(
            top: 38,
            child: CustomPaint(
              size: const Size(16, 8),
              painter: SmilePainter(),
            ),
          ),
          // Bowtie
          Positioned(
            bottom: 4,
            child: _buildBowtie(),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBowtie() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.3,
          child: Container(
            width: 10,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            shape: BoxShape.circle,
          ),
        ),
        Transform.rotate(
          angle: 0.3,
          child: Container(
            width: 10,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 2)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeechBubble extends StatefulWidget {
  final String message;
  final bool isThinking;

  const SpeechBubble({
    super.key,
    required this.message,
    this.isThinking = false,
  });

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _displayedText = '';
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _startTypewriter();
    _controller.forward();
  }

  @override
  void didUpdateWidget(SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _typewriterTimer?.cancel();
      _displayedText = '';
      _controller.forward(from: 0);
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    int charIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (charIndex < widget.message.length) {
        setState(() {
          _displayedText = widget.message.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayedText,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.isThinking) ...[
                const SizedBox(height: 4),
                const ThinkingDots(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key});

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (animValue < 0.5 ? animValue * 2 : 2 - animValue * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
