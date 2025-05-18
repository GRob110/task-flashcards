import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Flashcard> _currentCards = [];
  bool _needsReset = false;

  @override
  void initState() {
    super.initState();
    _currentCards = context.read<FlashcardProvider>().todaysFlashcards;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsReset) {
      _currentCards = context.read<FlashcardProvider>().todaysFlashcards;
      _needsReset = false;
    }
  }

  void _rateCard(FlashcardProvider provider, int cardId, int rating) {
    provider.recordPerformance(cardId, rating);
    setState(() {
      _currentCards.removeWhere((c) => c.id == cardId);
    });
  }

  void _passCard(FlashcardProvider provider, int cardId) {
    provider.passCard(cardId);
    setState(() {
      _currentCards.removeWhere((c) => c.id == cardId);
    });
  }

  void _skipCard(FlashcardProvider provider, int cardId) {
    provider.skipCard(cardId);
    setState(() {
      final index = _currentCards.indexWhere((c) => c.id == cardId);
      if (index != -1) {
        final card = _currentCards.removeAt(index);
        _currentCards.add(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              _needsReset = true;
              await Navigator.pushNamed(context, '/all');
              if (mounted) {
                setState(() {
                  _currentCards = provider.todaysFlashcards;
                });
              }
            },
            tooltip: "View all cards",
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.pushNamed(context, '/heatmap'),
            tooltip: "View heatmap",
          ),
        ],
      ),
      body: _currentCards.isEmpty
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
          : Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _currentCards.first.text,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _currentCards.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RatingButton(
                        icon: Icons.check_circle,
                        label: 'Success',
                        color: Colors.green,
                        onTap: () {
                          if (_currentCards.isNotEmpty) {
                            _rateCard(provider, _currentCards.first.id!, 2);
                          }
                        },
                      ),
                      _RatingButton(
                        icon: Icons.help_outline,
                        label: 'OK',
                        color: Colors.orange,
                        onTap: () {
                          if (_currentCards.isNotEmpty) {
                            _rateCard(provider, _currentCards.first.id!, 1);
                          }
                        },
                      ),
                      _RatingButton(
                        icon: Icons.cancel,
                        label: 'Fail',
                        color: Colors.red,
                        onTap: () {
                          if (_currentCards.isNotEmpty) {
                            _rateCard(provider, _currentCards.first.id!, 0);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RatingButton(
                        icon: Icons.skip_next,
                        label: 'Skip',
                        color: Colors.grey,
                        onTap: () {
                          if (_currentCards.isNotEmpty) {
                            _skipCard(provider, _currentCards.first.id!);
                          }
                        },
                      ),
                      _RatingButton(
                        icon: Icons.check_circle,
                        label: 'Pass',
                        color: Colors.blue,
                        onTap: () {
                          if (_currentCards.isNotEmpty) {
                            _passCard(provider, _currentCards.first.id!);
                          }
                        },
                      ),
                    ],
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
