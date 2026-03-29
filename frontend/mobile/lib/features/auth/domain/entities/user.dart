class AppUser {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl = '',
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, email, name);
}
