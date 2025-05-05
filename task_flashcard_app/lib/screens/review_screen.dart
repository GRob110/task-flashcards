// lib/screens/review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.todaysFlashcards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '/manage'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.pushNamed(context, '/heatmap'),
          ),
        ],
      ),
      body: cards.isEmpty
          ? const Center(child: Text('No flashcards yet. Add some!'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: CardSwiper(
                controller: _controller,
                cardsCount: cards.length,
                // REQUIRED: build each card
                cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
                  final card = cards[index];
                  return Card(
                    elevation: 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          card.text,
                          style: const TextStyle(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
                // OPTIONAL: adjust how many cards are stacked, padding, etc.
                numberOfCardsDisplayed: 3,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                // REQUIRED: handle each swipe and return true to accept it
                onSwipe: (
                  int previousIndex,
                  int? currentIndex,
                  CardSwiperDirection direction,
                ) {
                  final swipedCard = cards[previousIndex];
                  int rating;
                  switch (direction) {
                    case CardSwiperDirection.left:
                      rating = 0;   // fail
                      break;
                    case CardSwiperDirection.right:
                      rating = 2;   // success
                      break;
                    default:
                      rating = 1;   // ok (up/down)
                  }
                  provider.recordPerformance(swipedCard.id!, rating);
                  return true;
                },
              ),
            ),
    );
  }
}
