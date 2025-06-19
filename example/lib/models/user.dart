class User {
  final String id;
  final String name;
  final String email;
  final bool active;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.active,
    required this.createdAt,
  });

  @override
  String toString() => 'User($name, $email)';
}