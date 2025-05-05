class Flashcard {
  final int? id;
  final String text;

  Flashcard({this.id, required this.text});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      text: map['text'] as String,
    );
  }
}
