// lib/screens/heatmap_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:provider/provider.dart';
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
    final cards = provider.flashcards;

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
          ? const Center(child: Text('No flashcards to show heatmap.'))
          : RefreshIndicator(
              onRefresh: () async {
                await provider.loadFlashcards();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return FutureBuilder<Map<DateTime, int>>(
                    future: provider.getYearlyData(card.id!),
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final dataMap = snap.data ?? {};
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                //height: 120, // Increased to prevent overflow
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
                                    0: Colors.red,
                                    1: Colors.orange,
                                    2: Colors.green,
                                  },
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
            ),
    );
  }
}
