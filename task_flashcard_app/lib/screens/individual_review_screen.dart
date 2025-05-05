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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
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
                OutlinedButton(
                  onPressed: () {
                    provider.skipCard(cardId);
                    Navigator.pop(context);
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
