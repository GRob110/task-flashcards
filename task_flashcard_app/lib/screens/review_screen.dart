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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.todaysFlashcards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'See all cards',
            onPressed: () => Navigator.pushNamed(context, '/all'),
          ),
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
        ? const Center(child: Text('No cards left to review today!'))
        : Column(
            children: [
              Expanded(
                child: CardSwiper(
                  controller: _controller,
                  cardsCount: cards.length,
                  numberOfCardsDisplayed: cards.length,
                  padding: const EdgeInsets.all(16),
                  cardBuilder: (ctx, index, h, v) {
                    final card = cards[index];
                    final ema = provider.getEmaForCard(card.id!);
                    final cardColor = provider.getCardColor(ema);
                    return Card(
                      color: cardColor,
                      elevation: 4,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            card.text,
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                  onSwipe: (prev, curr, direction) {
                    if (cards.isEmpty || prev == null || prev < 0 || prev >= cards.length) return true;
                    final id = cards[prev].id;
                    if (id == null) return true;
                    int rating;
                    switch (direction) {
                      case CardSwiperDirection.left:
                        rating = 0; break;
                      case CardSwiperDirection.right:
                        rating = 2; break;
                      default:
                        rating = 1; break;
                    }
                    provider.recordPerformance(id, rating);
                    setState(() {
                      if (cards.isEmpty) {
                        _currentIndex = 0;
                      } else if (curr != null && curr >= 0 && curr < cards.length) {
                        _currentIndex = curr;
                      } else if (_currentIndex >= cards.length) {
                        _currentIndex = cards.length - 1;
                      }
                    });
                    return true;
                  },
                ),
              ),

              // Skip button
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (cards.length <= 1) {
                        // Only one card, do nothing
                        return;
                      }
                      if (_currentIndex < cards.length - 1) {
                        _currentIndex++;
                        _controller.moveTo(_currentIndex);
                      } else {
                        _currentIndex = 0;
                        _controller.moveTo(_currentIndex);
                      }
                    });
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
              ),
            ],
          ),
    );
  }
}
