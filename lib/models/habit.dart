class Habit {
  final int? id;
  final String name;
  final String description;
  final String? category; // Optional category
  final String createdAt;

  Habit({
    this.id,
    required this.name,
    required this.description,
    this.category,
    required this.createdAt,
  });

  // Convert Habit object → Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'created_at': createdAt,
    };
  }

  // Convert Map → Habit object
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      createdAt: map['created_at'],
    );
  }
}
