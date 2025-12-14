import 'package:flutter/material.dart';
import 'card_models.dart';
import 'widgets/playing_card_widget.dart';
import 'widgets/chip_widget.dart';
import 'widgets/dealer_widget.dart';
import 'widgets/confetti_widget.dart';

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen>
    with TickerProviderStateMixin {
  final Deck _deck = Deck();
  List<PlayingCard> _playerHand = [];
  List<PlayingCard> _dealerHand = [];

  int _chips = 1000;
  int _currentBet = 0;
  int _originalBet = 0; // Track original bet for clearing

  bool _gameInProgress = false;
  bool _playerTurn = false;
  bool _showResult = false;
  String _resultMessage = '';
  Color _resultColor = Colors.white;
  String? _dealerMessage;
  bool _dealerThinking = false;
  bool _isDealing = false;

  bool _showConfetti = false;
  ConfettiType _confettiType = ConfettiType.win;
  bool _showCoins = false;

  late AnimationController _resultAnimationController;
  late Animation<double> _resultAnimation;

  final List<String> _dealerGreetings = [
    "Place your bets!",
    "Feeling lucky?",
    "Let's play!",
    "Good luck!",
  ];

  final List<String> _dealerWinMessages = [
    "Better luck next time!",
    "The house wins!",
    "I'll take those.",
  ];

  final List<String> _dealerLoseMessages = [
    "Well played!",
    "You got me!",
    "Nice hand!",
  ];

  final List<String> _dealerBlackjackMessages = [
    "Blackjack! Impressive!",
    "21! Beautiful!",
  ];

  @override
  void initState() {
    super.initState();
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.elasticOut,
    );

    _dealerMessage = _getRandomMessage(_dealerGreetings);
  }

  @override
  void dispose() {
    _resultAnimationController.dispose();
    super.dispose();
  }

  String _getRandomMessage(List<String> messages) {
    return messages[DateTime.now().millisecond % messages.length];
  }

  int _calculateHandValue(List<PlayingCard> hand) {
    int value = 0;
    int aces = 0;

    for (final card in hand) {
      if (!card.faceUp) continue;
      value += card.value;
      if (card.rank == 'A') aces++;
    }

    while (value > 21 && aces > 0) {
      value -= 10;
      aces--;
    }

    return value;
  }

  bool _isBlackjack(List<PlayingCard> hand) {
    return hand.length == 2 && _calculateHandValue(hand) == 21;
  }

  Future<void> _startGame() async {
    if (_currentBet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Place a bet first!'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _gameInProgress = true;
      _playerTurn = true;
      _showResult = false;
      _showConfetti = false;
      _showCoins = false;
      _playerHand = [];
      _dealerHand = [];
      _dealerMessage = "Dealing...";
      _originalBet = _currentBet; // Store original bet
    });

    // Deal cards with animation
    await _dealCard(_playerHand, true);
    await _dealCard(_dealerHand, true);
    await _dealCard(_playerHand, true);
    await _dealCard(_dealerHand, false); // Dealer's hole card

    setState(() {
      _dealerMessage = null;
    });

    // Check for blackjack
    if (_isBlackjack(_playerHand)) {
      _dealerHand[1].faceUp = true;
      if (_isBlackjack(_dealerHand)) {
        _endGame('Push!', Colors.yellow, multiplier: 1);
        _dealerMessage = "We both got 21!";
      } else {
        _endGame('BLACKJACK!', Colors.amber, multiplier: 2.5);
        _dealerMessage = _getRandomMessage(_dealerBlackjackMessages);
        _confettiType = ConfettiType.blackjack;
        _showConfetti = true;
        _showCoins = true;
      }
    }
  }

  Future<void> _dealCard(List<PlayingCard> hand, bool faceUp) async {
    setState(() => _isDealing = true);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      hand.add(_deck.draw(faceUp: faceUp));
      _isDealing = false;
    });
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _hit() async {
    await _dealCard(_playerHand, true);

    if (_calculateHandValue(_playerHand) > 21) {
      _endGame('BUST!', Colors.red);
      _dealerMessage = _getRandomMessage(_dealerWinMessages);
      _confettiType = ConfettiType.lose;
      _showConfetti = true;
    }
  }

  Future<void> _stand() async {
    setState(() {
      _playerTurn = false;
      _dealerThinking = true;
      _dealerMessage = "My turn...";
    });

    // Reveal dealer's hole card
    await Future.delayed(const Duration(milliseconds: 500));
    _dealerHand[1].faceUp = true;
    setState(() {});

    // Dealer draws until 17 or higher
    while (_calculateHandValue(_dealerHand) < 17) {
      setState(() => _dealerMessage = "I'll take another...");
      await Future.delayed(const Duration(milliseconds: 800));
      await _dealCard(_dealerHand, true);
    }

    setState(() => _dealerThinking = false);

    final playerValue = _calculateHandValue(_playerHand);
    final dealerValue = _calculateHandValue(_dealerHand);

    if (dealerValue > 21) {
      _endGame('Dealer Busts!', Colors.green, multiplier: 2);
      _dealerMessage = _getRandomMessage(_dealerLoseMessages);
      _confettiType = ConfettiType.win;
      _showConfetti = true;
      _showCoins = true;
    } else if (playerValue > dealerValue) {
      _endGame('You Win!', Colors.green, multiplier: 2);
      _dealerMessage = _getRandomMessage(_dealerLoseMessages);
      _confettiType = ConfettiType.win;
      _showConfetti = true;
      _showCoins = true;
    } else if (playerValue < dealerValue) {
      _endGame('Dealer Wins!', Colors.red);
      _dealerMessage = _getRandomMessage(_dealerWinMessages);
      _confettiType = ConfettiType.lose;
      _showConfetti = true;
    } else {
      _endGame('Push!', Colors.yellow, multiplier: 1);
      _dealerMessage = "It's a tie!";
    }
  }

  Future<void> _doubleDown() async {
    if (_chips >= _currentBet) {
      setState(() {
        _chips -= _currentBet;
        _currentBet *= 2;
        _originalBet = _currentBet;
      });
      await _dealCard(_playerHand, true);

      if (_calculateHandValue(_playerHand) > 21) {
        _endGame('BUST!', Colors.red);
        _dealerMessage = _getRandomMessage(_dealerWinMessages);
        _confettiType = ConfettiType.lose;
        _showConfetti = true;
      } else {
        await _stand();
      }
    }
  }

  void _endGame(String message, Color color, {double multiplier = 0}) {
    setState(() {
      _gameInProgress = false;
      _playerTurn = false;
      _showResult = true;
      _resultMessage = message;
      _resultColor = color;

      if (multiplier > 0) {
        _chips += (_currentBet * multiplier).round();
      }

      // BUG FIX: Reset current bet after game ends to prevent clearing lost bets
      _currentBet = 0;
      _originalBet = 0;
    });
    _resultAnimationController.reset();
    _resultAnimationController.forward();
  }

  void _placeBet(int amount) {
    if (!_gameInProgress && !_showResult && _chips >= amount) {
      setState(() {
        _chips -= amount;
        _currentBet += amount;
        _originalBet = _currentBet;
      });
    }
  }

  void _clearBet() {
    // Only allow clearing if game is not in progress AND result is not showing
    // This prevents the bug where you could reclaim lost bets
    if (!_gameInProgress && !_showResult && _currentBet > 0) {
      setState(() {
        _chips += _currentBet;
        _currentBet = 0;
        _originalBet = 0;
      });
    }
  }

  void _newRound() {
    setState(() {
      _currentBet = 0;
      _originalBet = 0;
      _showResult = false;
      _showConfetti = false;
      _showCoins = false;
      _playerHand = [];
      _dealerHand = [];
      _dealerMessage = _getRandomMessage(_dealerGreetings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Casino table background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF0D4F2B),
                  Color(0xFF0A3D22),
                  Color(0xFF072B18),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Table felt pattern
          CustomPaint(
            size: Size.infinite,
            painter: TableFeltPainter(),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar area
                _buildAppBar(),

                // Dealer area
                Expanded(
                  flex: 4,
                  child: _buildDealerArea(),
                ),

                // Center betting area
                _buildBettingPot(),

                // Player area
                Expanded(
                  flex: 3,
                  child: _buildPlayerArea(),
                ),

                // Controls
                _buildControls(),
              ],
            ),
          ),

          // Confetti overlay - IgnorePointer so it doesn't block touches
          IgnorePointer(
            child: ConfettiOverlay(
              isActive: _showConfetti,
              type: _confettiType,
              onComplete: () {
                if (mounted) setState(() => _showConfetti = false);
              },
            ),
          ),

          // Coin shower - IgnorePointer so it doesn't block touches
          IgnorePointer(
            child: CoinShower(
              isActive: _showCoins,
              onComplete: () {
                if (mounted) setState(() => _showCoins = false);
              },
            ),
          ),

          // Result overlay - IgnorePointer so buttons work
          if (_showResult)
            IgnorePointer(
              child: _buildResultOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'BLACKJACK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          AnimatedChipCounter(chips: _chips),
        ],
      ),
    );
  }

  Widget _buildDealerArea() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dealer avatar
          DealerWidget(
            message: _dealerMessage,
            isThinking: _dealerThinking,
            isDealing: _isDealing,
          ),
          const SizedBox(height: 8),

          // Dealer's hand
          if (_dealerHand.isNotEmpty) ...[
            Text(
              'Dealer${_dealerHand.any((c) => !c.faceUp) ? "" : " - ${_calculateHandValue(_dealerHand)}"}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            _buildCardHand(_dealerHand),
          ] else
            Text(
              'Dealer\'s cards',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBettingPot() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentBet > 0 || (_showResult && _originalBet > 0)) ...[
            ChipStack(amount: _showResult ? 0 : _currentBet),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Text(
                'BET: \$${_showResult ? 0 : _currentBet}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Text(
                'Place your bet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_playerHand.isNotEmpty) ...[
            Text(
              'You - ${_calculateHandValue(_playerHand)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            _buildCardHand(_playerHand),
          ] else
            Text(
              'Your cards',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardHand(List<PlayingCard> hand) {
    return SizedBox(
      height: 100,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hand.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Padding(
                padding: EdgeInsets.only(left: index > 0 ? 0 : 0),
                child: Transform.translate(
                  offset: Offset(index * -25.0, 0),
                  child: PlayingCardWidget(
                    key: ValueKey('${card.rank}_${card.suit}_$index'),
                    card: card,
                    entryDelay: index * 150,
                    slideFrom: const Offset(0, -1.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: _gameInProgress ? _buildGameControls() : _buildBettingControls(),
    );
  }

  Widget _buildBettingControls() {
    return Column(
      children: [
        // Chip buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ChipData.standardChips.map((chipData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PokerChipButton(
                chipData: chipData,
                enabled: !_showResult && _chips >= chipData.value,
                onTap: () => _placeBet(chipData.value),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              'Clear',
              Icons.clear,
              Colors.red.shade700,
              _currentBet > 0 && !_showResult ? _clearBet : null,
            ),
            if (_showResult)
              _buildControlButton(
                'New Round',
                Icons.refresh,
                Colors.blue.shade600,
                _newRound,
                large: true,
              )
            else
              _buildControlButton(
                'Deal',
                Icons.play_arrow,
                Colors.amber.shade700,
                _currentBet > 0 ? _startGame : null,
                large: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          'Hit',
          Icons.add_circle,
          Colors.green.shade600,
          _playerTurn ? _hit : null,
        ),
        _buildControlButton(
          'Stand',
          Icons.pan_tool,
          Colors.orange.shade700,
          _playerTurn ? _stand : null,
        ),
        _buildControlButton(
          'Double',
          Icons.exposure_plus_2,
          Colors.blue.shade600,
          _playerTurn && _playerHand.length == 2 && _chips >= _currentBet
              ? _doubleDown
              : null,
        ),
      ],
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool large = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed != null ? 1.0 : 0.4,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: large ? 24 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: large ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade700,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: large ? 28 : 16,
            vertical: large ? 14 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed != null ? 4 : 0,
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Center(
      child: ScaleTransition(
        scale: _resultAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _resultColor,
                _resultColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _resultColor.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Text(
            _resultMessage,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TableFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle texture pattern
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }

    // Draw table border arc
    final borderPaint = Paint()
      ..color = Colors.brown.shade900.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.4,
        size.width,
        size.height * 0.6,
      );

    canvas.drawPath(path, borderPaint);

    // Inner gold trim
    final goldPaint = Paint()
      ..color = Colors.amber.shade700.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerPath = Path()
      ..moveTo(20, size.height * 0.62)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.42,
        size.width - 20,
        size.height * 0.62,
      );

    canvas.drawPath(innerPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
