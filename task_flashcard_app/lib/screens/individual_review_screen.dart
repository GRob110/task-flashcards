import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';

class IndividualReviewScreen extends StatelessWidget {
  final int cardId;
  final String text;
  const IndividualReviewScreen({
    super.key, required this.cardId, required this.text
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FlashcardProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Review Card')),
      body: FutureBuilder<int?>(
        future: provider.getTodayPerformanceRating(cardId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentRating = snapshot.data;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                if (currentRating != null) ...[
                  Text(
                    'You have already rated this card today.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await provider.deleteTodayPerformance(cardId);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete Today\'s Rating'),
                  ),
                ] else ...[
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          provider.recordPerformance(cardId, 0);
                          Navigator.pop(context);
                        },
                        child: const Text('Fail'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          provider.recordPerformance(cardId, 1);
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          provider.recordPerformance(cardId, 2);
                          Navigator.pop(context);
                        },
                        child: const Text('Success'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          provider.passCard(cardId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Pass'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          provider.skipCard(cardId);
                          Navigator.pop(context);
                        },
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
