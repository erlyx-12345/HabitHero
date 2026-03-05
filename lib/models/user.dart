class UserProfile {
  final int? id;
  final String name;

  UserProfile({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}