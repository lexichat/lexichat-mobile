class User {
  final String userID;
  final String userName;
  final String phoneNumber;
  final String fcmToken;
  final List<int>? profilePicture;
  final String? createdAt;

  User({
    required this.userID,
    required this.userName,
    required this.phoneNumber,
    required this.fcmToken,
    required this.profilePicture,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'userid': userID,
        'username': userName,
        'phone_number': phoneNumber,
        'fcm_token': fcmToken,
        'profile_picture': profilePicture,
        if (createdAt != null) 'created_at': createdAt,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userid'],
      userName: json['username'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'],
    );
  }
}
