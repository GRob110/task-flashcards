// lib/screens/manage_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  Future<void> _showAddEditDialog(
    BuildContext context, {
    Flashcard? card,
  }) {
    final isEditing = card != null;
    final textCtrl = TextEditingController(text: card?.text ?? '');

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Flashcard' : 'Add Flashcard'),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(labelText: 'Card Text'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textCtrl.text.trim();
              if (text.isNotEmpty) {
                final provider = context.read<FlashcardProvider>();
                if (isEditing) {
                  provider.updateFlashcard(
                    Flashcard(id: card.id, text: text),
                  );
                } else {
                  provider.addFlashcard(text);
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final cards = provider.flashcards;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Flashcards')),
      body: cards.isEmpty
          ? const Center(child: Text('No flashcards. Tap + to add one.'))
          : ListView.builder(
              itemCount: cards.length,
              itemBuilder: (ctx, i) {
                final card = cards[i];
                return Dismissible(
                  key: ValueKey(card.id),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    provider.deleteFlashcard(card.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flashcard deleted')),
                    );
                  },
                  child: ListTile(
                    tileColor: provider.getCardColor(provider.getEmaForCard(card.id!)),
                    title: Text(card.text),
                    onTap: () => _showAddEditDialog(context, card: card),
                    trailing: provider.completedToday.contains(card.id)
                        ? IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: "Edit today's performance",
                            onPressed: () async {
                              int? currentRating = await provider.getTodayPerformanceRating(card.id!);
                              String ratingText;
                              if (currentRating == 0) {
                                ratingText = 'Current: Fail';
                              } else if (currentRating == 1) {
                                ratingText = 'Current: OK';
                              } else if (currentRating == 2) {
                                ratingText = 'Current: Success';
                              } else {
                                ratingText = 'Current: Unknown';
                              }
                              final action = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Edit Today's Performance"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ratingText, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      const Text('Change or delete today\'s performance for this card:'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, 'fail'),
                                      child: const Text('Fail'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, 'ok'),
                                      child: const Text('OK'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, 'success'),
                                      child: const Text('Success'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, 'delete'),
                                      child: const Text('Delete'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, null),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (action == 'fail') {
                                await provider.updateTodayPerformance(card.id!, 0);
                              } else if (action == 'ok') {
                                await provider.updateTodayPerformance(card.id!, 1);
                              } else if (action == 'success') {
                                await provider.updateTodayPerformance(card.id!, 2);
                              } else if (action == 'delete') {
                                await provider.deleteTodayPerformance(card.id!);
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
