class User {
  final String? id;
  final String username;
  final String phoneNumber;
  final List<int> profilePicture;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.phoneNumber,
    required this.profilePicture,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'phone_number': phoneNumber,
        'profile_picture': profilePicture,
        if (createdAt != null) 'created_at': createdAt,
      };
}
