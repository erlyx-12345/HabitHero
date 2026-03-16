class DailyLog {
  final int? id;
  final int habitId;
  final String date;
  final bool completed;

  DailyLog({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  // Convert object → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date,
      'completed': completed ? 1 : 0,
    };
  }

  // Convert Map → object
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      habitId: map['habit_id'],
      date: map['date'],
      completed: map['completed'] == 1,
    );
  }
}
