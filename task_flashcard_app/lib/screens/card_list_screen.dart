import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

class CardListScreen extends StatelessWidget {
  const CardListScreen({super.key});

  Future<void> _exportToCsv(BuildContext context) async {
    final provider = context.read<FlashcardProvider>();
    final cards = provider.sortedFlashcards;
    
    // Create CSV content
    final csvContent = StringBuffer();
    csvContent.writeln('Card ID,Text,EMA');
    
    for (var card in cards) {
      final ema = provider.getEmaForCard(card.id!);
      csvContent.writeln('${card.id},"${card.text}",$ema');
    }
    
    // Get the downloads directory
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access downloads directory')),
        );
      }
      return;
    }
    
    // Create the file
    final file = File('${directory.path}/flashcards_export.csv');
    await file.writeAsString(csvContent.toString());
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<FlashcardProvider>().sortedFlashcards;
    final provider = context.watch<FlashcardProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportToCsv(context),
            tooltip: "Export to CSV",
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
                    'Add some cards to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) {
                final c = cards[i];
                final cardColors = provider.getCardColor(provider.getEmaForCard(c.id!));
                return Card(
                  color: cardColors.$1,
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _editTodayPerformance(context, c),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: AutoSizeText(
                                c.text,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: cardColors.$2,
                                  fontWeight: FontWeight.bold,
                                ),
                                minFontSize: 10,
                                maxLines: 4,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: cardColors.$2),
                                onPressed: () => _editCard(context, c),
                                tooltip: "Edit card",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.delete, color: cardColors.$2),
                                onPressed: () => _deleteCard(context, c),
                                tooltip: "Delete card",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCard(BuildContext context) async {
    final textController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Task'),
        content: TextField(
          autofocus: true,
          controller: textController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter task description',
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.pop(ctx, textController.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await context.read<FlashcardProvider>().addFlashcard(text);
    }
  }

  Future<void> _editCard(BuildContext context, Flashcard card) async {
    final textController = TextEditingController(text: card.text);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Card'),
        content: TextField(
          autofocus: true,
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter card text',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await context.read<FlashcardProvider>().updateFlashcard(
        Flashcard(id: card.id, text: text),
      );
    }
  }

  Future<void> _deleteCard(BuildContext context, Flashcard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<FlashcardProvider>().deleteFlashcard(card.id!);
    }
  }

  Future<void> _editTodayPerformance(BuildContext context, Flashcard card) async {
    final provider = context.read<FlashcardProvider>();
    final currentRating = await provider.getTodayPerformanceRating(card.id!);
    print('Current rating for card ${card.id}: $currentRating');
    
    if (currentRating != null) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Card Already Rated Today'),
          content: const Text('You must delete today\'s rating before changing it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete Rating'),
            ),
          ],
        ),
      );
      
      if (shouldDelete == true) {
        print('Deleting current rating for card ${card.id}');
        await provider.deleteTodayPerformance(card.id!);
      }
      return;
    }

    int? selectedRating;
    final rating = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Today\'s Performance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Pass'),
                leading: Radio<int>(
                  value: -1,
                  groupValue: selectedRating,
                  onChanged: (value) {
                    print('Selected rating: $value');
                    setState(() => selectedRating = value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Fail'),
                leading: Radio<int>(
                  value: 0,
                  groupValue: selectedRating,
                  onChanged: (value) {
                    print('Selected rating: $value');
                    setState(() => selectedRating = value);
                  },
                ),
              ),
              ListTile(
                title: const Text('OK'),
                leading: Radio<int>(
                  value: 1,
                  groupValue: selectedRating,
                  onChanged: (value) {
                    print('Selected rating: $value');
                    setState(() => selectedRating = value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Success'),
                leading: Radio<int>(
                  value: 2,
                  groupValue: selectedRating,
                  onChanged: (value) {
                    print('Selected rating: $value');
                    setState(() => selectedRating = value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Cancelled rating selection');
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedRating == null 
                ? null 
                : () {
                    print('Saving rating: $selectedRating');
                    Navigator.pop(ctx, selectedRating);
                  },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    print('Dialog returned rating: $rating');
    if (rating != null) {
      print('Updating performance for card ${card.id} with rating $rating');
      await provider.updateTodayPerformance(card.id!, rating);
    }
  }
}
