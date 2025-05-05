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
                    title: Text(card.text),
                    onTap: () => _showAddEditDialog(context, card: card),
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
