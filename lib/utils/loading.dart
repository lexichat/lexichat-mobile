import 'package:lexichat/config/config.dart' as config;
import 'package:lexichat/models/User.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalUserState {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String prefix = "UserDetails";

  // Method to update user details in local storage
  static Future<void> updateUserDetails(User user) async {
    await _storage.write(key: prefix + 'userID', value: user.userID);
    await _storage.write(key: prefix + 'phoneNumber', value: user.phoneNumber);
    await _storage.write(key: prefix + 'userName', value: user.userName);
    await _storage.write(key: prefix + 'fcmToken', value: user.fcmToken);
    await _storage.write(
        key: prefix + 'profilePicture', value: user.profilePicture.toString());
    await _storage.write(
        key: prefix + 'createdAt', value: user.createdAt ?? '');

    config.userDetails = user;
  }

  // Method to get user details from local storage
  Future<User?> _getUserDetails() async {
    String? userID = await _storage.read(key: prefix + 'userID');
    String? userName = await _storage.read(key: prefix + 'userName');
    String? phoneNumber = await _storage.read(key: prefix + 'phoneNumber');
    String? fcmToken = await _storage.read(key: prefix + 'fcmToken');
    String? profilePictureString =
        await _storage.read(key: prefix + 'profilePicture');
    List<int>? profilePicture = null;
    String? createdAt = await _storage.read(key: prefix + 'createdAt');

    if (userID != null &&
        userName != null &&
        phoneNumber != null &&
        fcmToken != null &&
        createdAt != null) {
      return User(
        userID: userID,
        userName: userName,
        phoneNumber: phoneNumber,
        fcmToken: fcmToken,
        profilePicture: profilePicture,
        createdAt: createdAt,
      );
    } else {
      return null;
    }
  }

  static Future<User> fetchUserConfigData() async {
    final localUserState = LocalUserState();
    User? user = await localUserState._getUserDetails();

    try {
      if (user == null) {
        print("error reading user details");
        throw Exception('Failed to retrieve user details');
      }

      config.userDetails = user;
      print("myuserid: ${config.userDetails.userID}");
      return user;
    } catch (e) {
      throw Exception("Failed to populate user details in global config");
    }
  }
}
