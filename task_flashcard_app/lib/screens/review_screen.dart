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
                  numberOfCardsDisplayed: 3,
                  padding: const EdgeInsets.all(16),
                  cardBuilder: (ctx, index, h, v) {
                    final card = cards[index];
                    return Card(
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
                    // record fail / ok / success
                    final id = cards[prev].id!;
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
                    // update the “current” index for Skip button
                    setState(() {
                      _currentIndex = curr ?? _currentIndex;
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
                    final id = cards[_currentIndex].id!;
                    provider.skipCard(id);
                    // no DB write for skip
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
