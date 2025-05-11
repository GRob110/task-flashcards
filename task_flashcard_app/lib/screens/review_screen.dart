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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.todaysFlashcards;
    final theme = Theme.of(context);

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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '/manage'),
            tooltip: "Manage cards",
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
              cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                if (index < 0 || index >= cards.length) return null;
                final card = cards[index];
                final ema = provider.getEmaForCard(card.id!);
                final cardColor = provider.getCardColor(ema);
                return Card(
                  color: cardColor,
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        card.text,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
              onSwipe: (prev, curr, direction) {
                if (cards.isEmpty || prev < 0 || prev >= cards.length) return true;
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
                    icon: Icons.close,
                    label: 'Fail',
                    color: Colors.red,
                    onTap: () => _rateCard(provider, cards.first.id!, 0),
                  ),
                  _RatingButton(
                    icon: Icons.check,
                    label: 'OK',
                    color: Colors.orange,
                    onTap: () => _rateCard(provider, cards.first.id!, 1),
                  ),
                  _RatingButton(
                    icon: Icons.star,
                    label: 'Success',
                    color: Colors.green,
                    onTap: () => _rateCard(provider, cards.first.id!, 2),
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
