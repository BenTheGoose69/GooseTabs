import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../card_models.dart';

class PlayingCardWidget extends StatefulWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final bool animateEntry;
  final int entryDelay;
  final Offset? slideFrom;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 70,
    this.height = 100,
    this.animateEntry = true,
    this.entryDelay = 0,
    this.slideFrom,
  });

  @override
  State<PlayingCardWidget> createState() => _PlayingCardWidgetState();
}

class _PlayingCardWidgetState extends State<PlayingCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _entryController;
  late Animation<double> _flipAnimation;
  late Animation<double> _entryAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showFront = true;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _flipController.addListener(() {
      if (_flipAnimation.value >= 0.5 && _showFront != widget.card.faceUp) {
        setState(() => _showFront = widget.card.faceUp);
      }
    });

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    final slideStart = widget.slideFrom ?? const Offset(0, -2);
    _slideAnimation = Tween<Offset>(
      begin: slideStart,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animateEntry) {
      Future.delayed(Duration(milliseconds: widget.entryDelay), () {
        if (mounted) _entryController.forward();
      });
    } else {
      _entryController.value = 1;
    }

    _showFront = widget.card.faceUp;
  }

  @override
  void didUpdateWidget(PlayingCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.faceUp != widget.card.faceUp) {
      _flipController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _entryAnimation,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * math.pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle < math.pi / 2
                  ? _buildCardFace(_showFront)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildCardFace(_showFront),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFace(bool showFront) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: showFront ? _buildFrontFace() : _buildBackFace(),
      ),
    );
  }

  Widget _buildFrontFace() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Top-left rank and suit
          Positioned(
            top: 4,
            left: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.card.rank,
                  style: TextStyle(
                    color: widget.card.suitColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  widget.card.suitSymbol,
                  style: TextStyle(
                    color: widget.card.suitColor,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          // Center suit
          Center(
            child: Text(
              widget.card.suitSymbol,
              style: TextStyle(
                color: widget.card.suitColor,
                fontSize: 36,
              ),
            ),
          ),
          // Bottom-right rank and suit (rotated)
          Positioned(
            bottom: 4,
            right: 6,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.card.rank,
                    style: TextStyle(
                      color: widget.card.suitColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    widget.card.suitSymbol,
                    style: TextStyle(
                      color: widget.card.suitColor,
                      fontSize: 12,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: CustomPaint(
            size: Size(widget.width - 16, widget.height - 16),
            painter: CardBackPatternPainter(),
          ),
        ),
      ),
    );
  }
}

class CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw diamond pattern
    const spacing = 8.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
