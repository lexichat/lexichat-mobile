class User {
  late final String userID;
  late final String userName;
  late final String phoneNumber;
  late final String fcmToken;
  late final List<int>? profilePicture;
  late final String? createdAt;

  User({
    required this.userID,
    required this.userName,
    required this.phoneNumber,
    required this.fcmToken,
    required this.profilePicture,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userID == other.userID;

  @override
  int get hashCode => userID.hashCode;

  @override
  String toString() {
    return 'User(userID: $userID, userName: $userName, phoneNumber: $phoneNumber, fcmToken: $fcmToken, profilePicture: $profilePicture, createdAt: $createdAt)';
  }

  Map<String, dynamic> toJson() => {
        'user_id': userID,
        'user_name': userName,
        'phone_number': phoneNumber,
        'fcm_token': fcmToken,
        'profile_picture': profilePicture,
        if (createdAt != null) 'created_at': createdAt,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['user_id'],
      userName: json['user_name'],
      phoneNumber: json['phone_number'],
      profilePicture:
          json['profile_picture'] == "" ? null : json['profile_picture'],
      fcmToken: json['fcm_token'] ?? "NA",
      createdAt: json['created_at'],
    );
  }
}
