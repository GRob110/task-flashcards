import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import 'individual_review_screen.dart';

class CardListScreen extends StatelessWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<FlashcardProvider>().flashcards;
    final provider = context.watch<FlashcardProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('All Flashcards')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.1,
          crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final c = cards[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IndividualReviewScreen(
                  cardId: c.id!, text: c.text
                ),
              ),
            ),
            child: Card(
              color: provider.getCardColor(provider.getEmaForCard(c.id!)),
              elevation: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    c.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
