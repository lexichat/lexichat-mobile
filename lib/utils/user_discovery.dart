import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lexichat/models/User.dart';
import 'package:lexichat/config/config.dart' as config;

Future<List<User>> discoverUsersByUserId(String partialUserId) async {
  final apiUrl = config.BASE_API_URL! +
      '/api/v1/users/discover?partialUserId=$partialUserId';

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic>? responseData = json.decode(response.body);
      print("response data: ${responseData}");
      if (responseData == null) {
        return [];
      }
      List<User> users =
          responseData.map((json) => User.fromJson(json)).toList();

      return users;
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load users: $e');
  }
}
