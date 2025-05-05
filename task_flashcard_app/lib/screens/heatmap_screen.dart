// lib/screens/heatmap_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.flashcards;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Heatmap')),
      body: cards.isEmpty
          ? const Center(child: Text('No flashcards to show heatmap.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return FutureBuilder<Map<DateTime,int>>(
                  future: provider.getYearlyData(card.id!),
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final dataMap = snap.data ?? {};
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              card.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: HeatMapCalendar(
                                // your performance data
                                datasets: dataMap,                
                                // REQUIRED: map each rating to a color
                                colorsets: const {
                                  0: Colors.red,       // failed
                                  1: Colors.orange,    // ok
                                  2: Colors.green,     // success
                                },
                                // optional styling
                                defaultColor: Colors.grey[200],
                                textColor: Colors.black,
                                colorMode: ColorMode.color,
                                flexible: true,
                                size: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
