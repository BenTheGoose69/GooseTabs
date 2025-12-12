import 'dart:math';
import 'package:flutter/material.dart';

// Card suits and values
enum Suit { hearts, diamonds, clubs, spades }

class PlayingCard {
  final String rank;
  final Suit suit;
  bool faceUp;

  PlayingCard(this.rank, this.suit, {this.faceUp = true});

  int get value {
    if (rank == 'A') return 11;
    if (['K', 'Q', 'J'].contains(rank)) return 10;
    return int.parse(rank);
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.hearts: return '♥';
      case Suit.diamonds: return '♦';
      case Suit.clubs: return '♣';
      case Suit.spades: return '♠';
    }
  }

  Color get suitColor {
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? Colors.red
        : Colors.black;
  }
}

class Deck {
  final List<PlayingCard> _cards = [];
  final Random _random = Random();

  Deck() {
    _initDeck();
  }

  void _initDeck() {
    _cards.clear();
    final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    for (final suit in Suit.values) {
      for (final rank in ranks) {
        _cards.add(PlayingCard(rank, suit));
      }
    }
    shuffle();
  }

  void shuffle() {
    for (int i = _cards.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  PlayingCard draw({bool faceUp = true}) {
    if (_cards.length < 15) _initDeck();
    final card = _cards.removeLast();
    card.faceUp = faceUp;
    return card;
  }
}

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen> with TickerProviderStateMixin {
  final Deck _deck = Deck();
  List<PlayingCard> _playerHand = [];
  List<PlayingCard> _dealerHand = [];

  int _chips = 1000;
  int _currentBet = 0;
  int _selectedBetAmount = 25;

  bool _gameInProgress = false;
  bool _playerTurn = false;
  bool _showResult = false;
  String _resultMessage = '';
  Color _resultColor = Colors.white;

  late AnimationController _dealAnimationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _dealAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _dealAnimationController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
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
        const SnackBar(content: Text('Place a bet first!')),
      );
      return;
    }

    setState(() {
      _gameInProgress = true;
      _playerTurn = true;
      _showResult = false;
      _playerHand = [];
      _dealerHand = [];
    });

    // Deal cards with animation
    await _dealCard(_playerHand, true);
    await _dealCard(_dealerHand, true);
    await _dealCard(_playerHand, true);
    await _dealCard(_dealerHand, false); // Dealer's hole card

    // Check for blackjack
    if (_isBlackjack(_playerHand)) {
      _dealerHand[1].faceUp = true;
      if (_isBlackjack(_dealerHand)) {
        _endGame('Push!', Colors.yellow);
      } else {
        _endGame('Blackjack! You win!', Colors.green, multiplier: 2.5);
      }
    }
  }

  Future<void> _dealCard(List<PlayingCard> hand, bool faceUp) async {
    _dealAnimationController.reset();
    await _dealAnimationController.forward();
    setState(() {
      hand.add(_deck.draw(faceUp: faceUp));
    });
  }

  Future<void> _hit() async {
    await _dealCard(_playerHand, true);

    if (_calculateHandValue(_playerHand) > 21) {
      _endGame('Bust! You lose!', Colors.red);
    }
  }

  Future<void> _stand() async {
    setState(() => _playerTurn = false);

    // Reveal dealer's hole card
    _dealerHand[1].faceUp = true;
    setState(() {});

    // Dealer draws until 17 or higher
    while (_calculateHandValue(_dealerHand) < 17) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _dealCard(_dealerHand, true);
    }

    final playerValue = _calculateHandValue(_playerHand);
    final dealerValue = _calculateHandValue(_dealerHand);

    if (dealerValue > 21) {
      _endGame('Dealer busts! You win!', Colors.green, multiplier: 2);
    } else if (playerValue > dealerValue) {
      _endGame('You win!', Colors.green, multiplier: 2);
    } else if (playerValue < dealerValue) {
      _endGame('Dealer wins!', Colors.red);
    } else {
      _endGame('Push!', Colors.yellow, multiplier: 1);
    }
  }

  Future<void> _doubleDown() async {
    if (_chips >= _currentBet) {
      setState(() {
        _chips -= _currentBet;
        _currentBet *= 2;
      });
      await _dealCard(_playerHand, true);

      if (_calculateHandValue(_playerHand) > 21) {
        _endGame('Bust! You lose!', Colors.red);
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
    });
    _resultAnimationController.reset();
    _resultAnimationController.forward();
  }

  void _placeBet(int amount) {
    if (!_gameInProgress && _chips >= amount) {
      setState(() {
        _chips -= amount;
        _currentBet += amount;
      });
    }
  }

  void _clearBet() {
    if (!_gameInProgress) {
      setState(() {
        _chips += _currentBet;
        _currentBet = 0;
      });
    }
  }

  void _newRound() {
    setState(() {
      _currentBet = 0;
      _showResult = false;
      _playerHand = [];
      _dealerHand = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4F2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D22),
        title: const Text('🃏 Blackjack'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_chips',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dealer's area
          Expanded(
            flex: 3,
            child: _buildHandArea(
              'Dealer',
              _dealerHand,
              _calculateHandValue(_dealerHand),
              isDealer: true,
            ),
          ),

          // Result display
          if (_showResult)
            ScaleTransition(
              scale: _resultAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: _resultColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _resultColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  _resultMessage,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Player's area
          Expanded(
            flex: 3,
            child: _buildHandArea(
              'You',
              _playerHand,
              _calculateHandValue(_playerHand),
            ),
          ),

          // Controls area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A3D22),
              border: Border(
                top: BorderSide(color: Colors.green.shade900, width: 2),
              ),
            ),
            child: _gameInProgress ? _buildGameControls() : _buildBettingControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandArea(String label, List<PlayingCard> hand, int value, {bool isDealer = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label${hand.isNotEmpty ? " - $value" : ""}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: hand.isEmpty
              ? Center(
                  child: Text(
                    isDealer ? 'Dealer\'s cards' : 'Your cards',
                    style: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                )
              : _buildCardRow(hand),
        ),
      ],
    );
  }

  Widget _buildCardRow(List<PlayingCard> hand) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: hand.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(index * -30.0, 0),
                  child: Transform.scale(
                    scale: value,
                    child: _buildCard(card),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(PlayingCard card) {
    return Container(
      width: 80,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: card.faceUp ? Colors.white : const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: card.faceUp
          ? Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Column(
                    children: [
                      Text(
                        card.rank,
                        style: TextStyle(
                          color: card.suitColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        card.suitSymbol,
                        style: TextStyle(
                          color: card.suitColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    card.suitSymbol,
                    style: TextStyle(
                      color: card.suitColor,
                      fontSize: 40,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: Column(
                      children: [
                        Text(
                          card.rank,
                          style: TextStyle(
                            color: card.suitColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.suitSymbol,
                          style: TextStyle(
                            color: card.suitColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text(
                    '🎴',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBettingControls() {
    return Column(
      children: [
        // Current bet display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bet: ', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text(
                '\$$_currentBet',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chip buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChipButton(5, Colors.red),
            _buildChipButton(25, Colors.green),
            _buildChipButton(100, Colors.blue),
            _buildChipButton(500, Colors.purple),
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _currentBet > 0 ? _clearBet : null,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            if (_showResult)
              ElevatedButton.icon(
                onPressed: _newRound,
                icon: const Icon(Icons.refresh),
                label: const Text('New Round'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _currentBet > 0 && !_showResult ? _startGame : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Deal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipButton(int value, Color color) {
    return GestureDetector(
      onTap: () => _placeBet(value),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '\$$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton('Hit', Icons.add_circle, Colors.green, _playerTurn ? _hit : null),
        _buildActionButton('Stand', Icons.pan_tool, Colors.orange, _playerTurn ? _stand : null),
        _buildActionButton(
          'Double',
          Icons.exposure_plus_2,
          Colors.blue,
          _playerTurn && _playerHand.length == 2 && _chips >= _currentBet ? _doubleDown : null,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
