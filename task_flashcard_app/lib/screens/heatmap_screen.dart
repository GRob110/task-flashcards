// lib/screens/heatmap_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../providers/flashcard_provider.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<FlashcardProvider>(context, listen: false).loadFlashcards();
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final theme = Theme.of(context);
    // Sort cards by EMA (best performing first)
    final cards = [...provider.flashcards]..sort((a, b) => 
      provider.getEmaForCard(b.id!).compareTo(provider.getEmaForCard(a.id!))
    );

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 364));
    final endDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 10));

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Heatmap')),
      body: cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cards yet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some cards to see their performance',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await provider.loadFlashcards();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            card.text,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FutureBuilder<Map<DateTime, int>>(
                          future: provider.getYearlyData(card.id!),
                          builder: (ctx, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final dataMap = snap.data ?? {};
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: HeatMap(
                                datasets: dataMap,
                                colorMode: ColorMode.color,
                                showText: false,
                                scrollable: true,
                                fontSize: 10,
                                size: 10,
                                startDate: startDate,
                                endDate: endDate,
                                showColorTip: false,
                                colorsets: const {
                                  -1: Colors.blue,
                                  0: Colors.red,
                                  1: Colors.orange,
                                  2: Colors.green,
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
