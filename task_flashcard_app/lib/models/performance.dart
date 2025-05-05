class Performance {
  final int? id;
  final int cardId;
  final DateTime date;
  final int rating; // 0=fail,1=ok,2=success

  Performance({
    this.id,
    required this.cardId,
    required this.date,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardId': cardId,
      'date': date.toIso8601String(),
      'rating': rating,
    };
  }

  factory Performance.fromMap(Map<String, dynamic> map) {
    return Performance(
      id: map['id'] as int?,
      cardId: map['cardId'] as int,
      date: DateTime.parse(map['date'] as String),
      rating: map['rating'] as int,
    );
  }
}
