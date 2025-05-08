// lib/screens/manage_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cards'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.flashcards.length,
        itemBuilder: (ctx, i) {
          final card = provider.flashcards[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: provider.getCardColor(provider.getEmaForCard(card.id!)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                card.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _editCard(context, card),
                    tooltip: "Edit card",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _deleteCard(context, card),
                    tooltip: "Delete card",
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () => _editTodayPerformance(context, card),
                    tooltip: "Edit today's performance",
                  ),
                ],
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
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Card'),
        content: TextField(
          autofocus: true,
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
            onPressed: () {
              final text = (ctx.widget as AlertDialog)
                  .content as TextField;
              Navigator.pop(ctx, text.controller?.text);
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
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Card'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: card.text),
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
            onPressed: () {
              final text = (ctx.widget as AlertDialog)
                  .content as TextField;
              Navigator.pop(ctx, text.controller?.text);
            },
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
    final rating = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Today\'s Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fail'),
              leading: Radio<int>(
                value: 0,
                groupValue: currentRating,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
            ),
            ListTile(
              title: const Text('OK'),
              leading: Radio<int>(
                value: 1,
                groupValue: currentRating,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
            ),
            ListTile(
              title: const Text('Success'),
              leading: Radio<int>(
                value: 2,
                groupValue: currentRating,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (currentRating != null)
            TextButton(
              onPressed: () async {
                await provider.deleteTodayPerformance(card.id!);
                Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
        ],
      ),
    );
    if (rating != null) {
      await provider.updateTodayPerformance(card.id!, rating);
    }
  }
}
