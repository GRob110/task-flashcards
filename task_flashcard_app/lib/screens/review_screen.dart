import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../providers/flashcard_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final CardSwiperController _controller = CardSwiperController();

  void _rateCard(FlashcardProvider provider, int cardId, int rating) {
    provider.recordPerformance(cardId, rating);
  }

  void _passCard(FlashcardProvider provider, int cardId) {
    provider.passCard(cardId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.todaysFlashcards;
    final theme = Theme.of(context);

    print('ReviewScreen: ${cards.length} cards to review');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.pushNamed(context, '/all'),
            tooltip: "View all cards",
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.pushNamed(context, '/heatmap'),
            tooltip: "View heatmap",
          ),
        ],
      ),
      body: cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All done for today!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : CardSwiper(
              controller: _controller,
              cardsCount: cards.length,
              numberOfCardsDisplayed: 1,
              padding: const EdgeInsets.all(16),
              allowedSwipeDirection: const AllowedSwipeDirection.all(),
              cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                if (index < 0 || index >= cards.length) {
                  print('Invalid card index: $index (total cards: ${cards.length})');
                  return null;
                }
                final card = cards[index];
                final ema = provider.getEmaForCard(card.id!);
                final cardColors = provider.getCardColor(ema);
                print('Building card ${card.id} at index $index');
                return Card(
                  color: cardColors.$1,
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        card.text,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: cardColors.$2,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
              onSwipe: (prev, curr, direction) {
                if (cards.isEmpty || prev == null || prev < 0 || prev >= cards.length) {
                  print('Invalid swipe: prev=$prev, curr=$curr, direction=$direction');
                  return true;
                }
                final id = cards[prev].id;
                if (id == null) return true;
                
                print('Swiping card $id in direction $direction');
                
                // Handle different swipe directions
                switch (direction) {
                  case CardSwiperDirection.left:
                    provider.recordPerformance(id, 0); // Fail
                    break;
                  case CardSwiperDirection.right:
                    provider.recordPerformance(id, 2); // Success
                    break;
                  case CardSwiperDirection.top:
                    provider.recordPerformance(id, 1); // OK
                    break;
                  case CardSwiperDirection.bottom:
                    provider.skipCard(id); // Skip
                    break;
                  default:
                    provider.skipCard(id);
                }
                return true;
              },
            ),
      bottomNavigationBar: cards.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RatingButton(
                    icon: Icons.skip_next,
                    label: 'Skip',
                    color: Colors.grey,
                    onTap: () {
                      if (cards.isNotEmpty) {
                        print('Skipping card ${cards.first.id} from button');
                        provider.skipCard(cards.first.id!);
                      }
                    },
                  ),
                  _RatingButton(
                    icon: Icons.check_circle,
                    label: 'Pass',
                    color: Colors.blue,
                    onTap: () {
                      if (cards.isNotEmpty) {
                        print('Passing card ${cards.first.id} from button');
                        _passCard(provider, cards.first.id!);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
