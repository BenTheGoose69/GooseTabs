import 'dart:math';
import 'package:flutter/material.dart';

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
      case Suit.hearts:
        return '\u2665';
      case Suit.diamonds:
        return '\u2666';
      case Suit.clubs:
        return '\u2663';
      case Suit.spades:
        return '\u2660';
    }
  }

  Color get suitColor {
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? Colors.red.shade700
        : Colors.grey.shade900;
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
}

class Deck {
  final List<PlayingCard> _cards = [];
  final Random _random = Random();

  Deck() {
    _initDeck();
  }

  void _initDeck() {
    _cards.clear();
    final ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K'
    ];
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

  int get cardsRemaining => _cards.length;
}
