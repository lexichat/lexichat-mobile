import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexichat/models/User.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:lexichat/models/Chat.dart';
import 'package:lexichat/config/config.dart' as config;

late Database DBClient;

Future<Database> connectToDatabase(String dbName) async {
  final databasePath = await getDatabasesPath();
  return openDatabase(
    join(databasePath, dbName),
    onCreate: (db, version) async {
      await createTables(db);
    },
    version: 1,
  );
}

Future<void> initializeAndConnectDB(String dbName) async {
  var dbClient = await connectToDatabase(dbName);
  createTables(dbClient);
  // return dbClient;
  DBClient = dbClient;
  print("dbclient ${DBClient}");
}

// Create tables if not exists (create indexes)
Future<void> createTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id              INTEGER       PRIMARY KEY,
      user_id         TEXT          UNIQUE, 
      user_name       TEXT,
      phone_number    TEXT,
      fcm_token       TEXT,
      profile_picture BLOB,
      created_at      TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS channels (
      id              INTEGER  PRIMARY KEY,
      channel_name    TEXT,
      created_at      TEXT,
      tonality_tag    TEXT,
      description     TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS messages (
      id              TEXT    PRIMARY KEY,
      channel_id      INTEGER,
      created_at      TEXT,
      sender_user_id  TEXT,
      message         TEXT,
      status          TEXT,

    FOREIGN KEY (channel_id) REFERENCES channels(id),
    FOREIGN KEY (sender_user_id) REFERENCES users(user_id)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS channel_users (
      channel_id INTEGER,
      user_id    TEXT,
    FOREIGN KEY (channel_id) REFERENCES channels(id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    PRIMARY KEY (channel_id, user_id)
    )
  ''');

  // Index on channel_id, created_at DESC
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_channel_id_created_at ON messages (channel_id, created_at DESC);
  ''');
}

// Write conversation
Future<void> writeConversation(Database db, Conversation conversation) async {
  await db.transaction((txn) async {
    await txn.insert('messages', conversation.toMap());
  });
}

// Update status
Future<void> updateStatus(
    Database db, String conversationId, String status) async {
  await db.update(
    'messages',
    {'status': status},
    where: 'id = ?',
    whereArgs: [conversationId],
  );
}

// Read messages
Future<List<Conversation>> readMessages(Database db, int channelId) async {
  final conversations = await db.query(
    'conversations',
    where: 'channel_id = ?',
    whereArgs: [channelId],
    orderBy: 'created_at DESC',
  );
  return conversations.map((map) => Conversation.fromMap(map)).toList();
}

// Read channel_id and its latest message
// Future<Map<User, Conversation>> fetchUsersWithLatestConversation(
//     Database db) async {
//   // final channelConversations = <String, Conversation>{};

//   final channelDetails = await db.query(
//     'channels',
//     columns: ['id', 'channel_name'],
//     distinct: true,
//   );

//   List<int> channelIDs =
//       channelDetails.map((channel) => channel['id'] as int).toList();

//   print("channelids: ${channelIDs}");
//   Map<int, Conversation> mostRecentChannelsMessage =
//       await _fetchMostRecentChannelsMessage(db, channelIDs);

//   // for (final channel in channelDetails) {
//   //   final channelId = channel['id'] as int;
//   //   channelConversations[channel['channel_name'].toString()] =
//   //       mostRecentChannelsMessage[channelId] ?? Conversation.empty();
//   // }

//   // Fetch user details
//   List<User> users =
//       // await fetchUsersByUsernames(db, channelConversations.keys.toList());
//       await fetchAllUsersFromChannelUsers(db, channelIDs);

//   // Create a map with User as the key and Conversation as the value
//   Map<User, Conversation> usersWithLatestConversation = {};
//   // for (var user in users) {
//   //   final channelName = user.userName;
//   //   if (channelConversations.containsKey(channelName)) {
//   //     usersWithLatestConversation[user] = channelConversations[channelName]!;
//   //   }
//   // }

//   return usersWithLatestConversation;
// }
Future<Map<User, Conversation>> fetchUsersWithLatestConversation(
    Database db) async {
  Map<int, Channel> channelDetails = await fetchAllChannels(db);
  print("channelids: ${channelDetails.keys}");

  Map<int, Conversation> mostRecentChannelsMessage =
      await _fetchMostRecentChannelsMessage(db, channelDetails.keys.toList());

  Map<int, User> channelUserMapping =
      await fetchUsersByChannelId(db, channelDetails.keys.toList());

  Map<User, Conversation> usersWithLatestConversation = {};

  channelUserMapping.forEach((channelId, user) {
    if (mostRecentChannelsMessage.containsKey(channelId)) {
      usersWithLatestConversation[user] = mostRecentChannelsMessage[channelId]!;
    }
  });

  return usersWithLatestConversation;
}

Future<Map<int, User>> fetchUsersByChannelId(
    Database db, List channelIds) async {
  final results = await db.query(
    'channel_users',
    columns: ['channel_id', 'user_id'],
    where: 'channel_id IN (${channelIds.join(',')})',
  );

  final usersByIdMap = <int, User>{};

  for (final row in results) {
    final channelId = row['channel_id'] as int;
    final userId = row['user_id'] as String;

    if (!usersByIdMap.containsKey(channelId)) {
      final userResults = await db.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final user = User.fromJson(userResults.first);

      usersByIdMap[channelId] = user;
    }
  }

  return usersByIdMap;
}
// Future<Map<User, Conversation>> fetchUsersWithLatestConversation(
//     Database db) async {
//   final Map<User, Conversation> usersWithLatestConversation = {};

//   String rawQuery = """
//     SELECT
//       channel_users.channel_id,
//       channel_users.user_id,
//       COALESCE(
//         (
//           SELECT channels.channel_name
//           FROM channels
//           WHERE channel_users.channel_id = channels.id
//         ),
//         users.user_name
//       ) AS channel_name,
//       users.* ,
//       (
//         SELECT *
//         FROM messages AS m
//         WHERE m.channel_id = channel_users.channel_id
//         ORDER BY m.created_at DESC
//         LIMIT 1
//       ) AS latest_message
//     FROM channel_users
//     INNER JOIN users ON channel_users.user_id = users.user_id
//     WHERE channel_users.user_id <> ?;
//   """;

//   List<Map<String, dynamic>> results =
//       await db.rawQuery(rawQuery, [config.userDetails.userID]);

//   for (Map<String, dynamic> result in results) {
//     User user = User.fromJson(result['user_details']);
//     Conversation conversation = Conversation.fromMap(result['latest_message']);
//     usersWithLatestConversation[user] = conversation;
//   }

//   return usersWithLatestConversation;
// }

// Future<Map<User, Conversation>> fetchUsersWithLatestConversation(
//     Database db) async {
//   final Map<User, Conversation> usersWithLatestConversation = {};

//   String query = '''
// SELECT
//       u.*,
//       (
//         SELECT
//           json_object(
//             'id', m.id,
//             'message', m.message,
//             'created_at', m.created_at,
//             'channel_id', m.channel_id,
//             'sender_user_id', m.sender_user_id,
//             'status', m.status
//           )
//         FROM
//           messages m
//         WHERE
//           m.channel_id = cu.channel_id
//         ORDER BY
//           m.created_at DESC
//         LIMIT
//           1
//       ) AS latest_message
//     FROM
//       channel_users cu
//       INNER JOIN users u ON cu.user_id = u.user_id
//     WHERE
//       cu.user_id <> ?
//   ''';

//   final List<Map<String, dynamic>> results =
//       await db.rawQuery(query, [config.userDetails.userID]);

//   for (final Map<String, dynamic> result in results) {
//     final Map<String, dynamic> userDetails = Map.from(result)
//       ..remove('latest_message');
//     final User user = User.fromJson(userDetails);
//     final Conversation conversation =
//         Conversation.fromMap(result['latest_message']);

//     usersWithLatestConversation[user] = conversation;
//   }

//   return usersWithLatestConversation;
// }

Future<Map<int, Conversation>> _fetchMostRecentChannelsMessage(
    Database db, List<int> channelIDs) async {
  Map<int, Conversation> mostRecentChannelsMessage = {};

  for (final channelID in channelIDs) {
    List<Conversation> pastChannelMessages =
        await readLatestMessagesFromChannel(db, channelID, 1);
    if (pastChannelMessages.isNotEmpty) {
      Conversation mostRecentChannelMessage = pastChannelMessages[0];
      mostRecentChannelsMessage[channelID] = mostRecentChannelMessage;
    }
  }
  print("most recent channel msg ${mostRecentChannelsMessage}");

  return mostRecentChannelsMessage;
}

Future<List<User>> fetchUsersByUsernames(
    Database db, List<String> usernames) async {
  List<User> users = [];

  for (String username in usernames) {
    List<Map<String, dynamic>> userResult = await db.query(
      'users',
      where: 'user_name = ?',
      whereArgs: [username],
    );

    if (userResult.isNotEmpty) {
      Map<String, dynamic> userData = userResult.first;
      User user = User(
        userID: userData['user_id'],
        userName: userData['user_name'],
        phoneNumber: userData['phone_number'],
        fcmToken: userData['fcm_token'],
        profilePicture: userData['profile_picture'],
        createdAt: userData['created_at'],
      );
      users.add(user);
    }
  }

  return users;
}

// Read latest n messages from a channel
Future<List<Conversation>> readLatestMessagesFromChannel(
    Database db, int channelId, int limit) async {
  final conversations = await db.query(
    'messages',
    where: 'channel_id = ?',
    whereArgs: [channelId],
    orderBy: 'created_at DESC',
    limit: limit,
  );
  if (conversations.length == 0) {
    print("no conversations found in channel");
    return conversations.map((map) => Conversation.fromMap(map)).toList();
  }
  print(conversations.first);
  print(Conversation.fromMap(conversations.first));
  return conversations.map((map) => Conversation.fromMap(map)).toList();
}

Future<List<Conversation>> readLatestMessagesFromChannelName(
    Database db, int channelID, int limit, int offset) async {
  final conversations = await db.query('messages',
      where: 'channel_id = ?',
      whereArgs: [channelID],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset);
  return conversations.map((map) => Conversation.fromMap(map)).toList();
}

// Search string in messages
Future<List<Conversation>> searchMessagesInChannel(
  Database db,
  int channelId,
  String searchString,
) async {
  final conversations = await db.query(
    'conversations',
    where: 'channel_id = ? AND message LIKE ?',
    whereArgs: [channelId, '%$searchString%'],
    orderBy: 'created_at DESC',
  );
  return conversations.map((map) => Conversation.fromMap(map)).toList();
}

// create channel with user if not exists
Future<int> InitiateCreationOfChannelIfNotExists(User otherUser,
    String firstMessageContent, String messageID, Database db) async {
  // check if userID exists from channel.channel_name
  // String query = "SELECT channel_name FROM channels WHERE channel_name = ?";
  // List<Map<String, dynamic>> result =
  //     await db.rawQuery(query, [otherUser.userName]);

  // print("isNewChannel creation? ${result.length == 0}");

  print("creating new channel");

  // if exists, call readLatestMessagesFromChannel()
  // if (result.length > 0) {
  //   return -1;
  // } else {
  // Else, create channel
  int channelID = await _createChannelServer(
      otherUser.userID, firstMessageContent, messageID);
  print("channel id that was created: ${channelID}");
  if (channelID == -1) {
    return -1;
  }
  await populateChannelAndChannelUsersLocally(
      db, channelID, "", otherUser.userID);
  await populateChannelUsersLocally(
      db, channelID, [otherUser.userID, config.userDetails.userID]);
  return channelID;
}

// populate user table if not present
Future<void> PopulateUserTableIfNotExists(User newUser, Database db) async {
  // Check if the user already exists in the table
  List<Map<String, dynamic>> existingUser = await db.query(
    'users',
    where: 'user_id = ?',
    whereArgs: [newUser.userID],
  );

  // If the user doesn't exist, insert the new user
  if (existingUser.isEmpty) {
    await db.insert(
      'users',
      newUser.toJson(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    print("new user inserted in local db");
  }
}

Future<int> _createChannelServer(
    String otherUserID, String firstMessageContent, String messageID) async {
  String apiUrl = config.BASE_API_URL! + '/api/v1/channels/create';

  Map<String, dynamic> requestBody = {
    'channel_name': '',
    'tonality_tag': '',
    'description': '',
    'users': [otherUserID, config.userDetails.userID],
    'sender_user_id': config.userDetails.userID,
    'first_message': firstMessageContent,
    'message_id': messageID
  };

  String jsonBody = jsonEncode(requestBody);

  print("/create-channel data: ${jsonBody}");

  var response = await http.post(
    Uri.parse(apiUrl),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonBody,
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Channel created successfully');

    Map<String, dynamic> responseData = jsonDecode(response.body);

    int channelId = responseData['channel_id'];
    // List<String> userIds = responseData['user_ids'];
    return channelId;
  } else {
    print('Failed to create channel. Status code: ${response.statusCode}');
    return -1;
  }
}

Future<void> populateChannelAndChannelUsersLocally(
    Database db, int channelID, String channelName, String otherUserID) async {
  try {
    await db.insert(
      "channels",
      {
        'channel_name': '',
        'id': channelID,
        'tonality_tag': '',
        'description': '',
        'created_at': DateTime.now().toString()
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    print("channel created");

    await db.insert(
      "channel_users",
      {'channel_id': channelID, 'user_id': otherUserID},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  } catch (e) {
    print("Error inserting channel ${e}");
  }
}

Future<void> PopulateChannelLocally(Database db, Channel channel) async {
  try {
    await db.insert(
      "channels",
      {
        'channel_name': channel.channelName,
        'id': channel.id,
        'tonality_tag': channel.tonalityTag,
        'description': channel.description,
        'created_at': channel.createdAt ??
            DateTime.now().millisecondsSinceEpoch.toString()
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  } catch (e) {
    print("Error inserting channel ${e}");
  }
}

Future<void> populateChannelUsersLocally(
  Database db,
  int channelId,
  List<String> userIds,
) async {
  try {
    final batch = db.batch();
    for (final userId in userIds) {
      batch.insert(
        'channel_users',
        {
          'channel_id': channelId,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(continueOnError: true);
  } catch (e) {
    print('Error inserting channel users: $e');
  }
}

Future<Channel?> fetchChannelDataByName(Database db, String channelName) async {
  List<Map<String, dynamic>> results = await db.query(
    'channels',
    where: 'channel_name = ?',
    whereArgs: [channelName],
    limit: 1,
  );
  print("channel details: ${results}");

  // If results are empty, return null
  if (results.isEmpty) {
    return null;
  }

  return Channel.fromMap(results.first);
}

Future<Channel?> fetchChannelDataByChannelID(Database db, int channelID) async {
  List<Map<String, dynamic>> results = await db.query(
    'channels',
    where: 'id = ?',
    whereArgs: [channelID],
    limit: 1,
  );
  print("channel details: ${results}");

  // If results are empty, return null
  if (results.isEmpty) {
    return null;
  }

  return Channel.fromMap(results.first);
}

Future<List<int>> fetchAllChannelIds(Database db) async {
  List<Map<String, dynamic>> results =
      await db.query('channels', columns: ['id']);

  List<int> channelIds = results.map((row) => row['id'] as int).toList();

  return channelIds;
}

Future<Map<int, Channel>> fetchAllChannels(Database db) async {
  final Map<int, Channel> channels = {};
  final List<Map<String, dynamic>> maps = await db.query('channels');

  for (final map in maps) {
    final channel = Channel.fromMap(map);
    channels[channel.id] = channel;
  }

  return channels;
}

Future<void> initiateCreationOfNewUserChat(
    Database db, Channel channel, User newUser) async {
  // update channels, channel_users, user tables
}

Future<List<User>> fetchAllUsersFromChannelUsers(
    Database db, List<int> channelIDs) {
  final sql = '''
    SELECT DISTINCT users.*
    FROM channel_users
    INNER JOIN users on channel_users.user_id = users.user_id
    WHERE channel_id IN (${channelIDs.join(',')}) AND users.user_id <> (${config.userDetails.userID})
  ''';

  return db.query(sql).then((results) {
    return results.map((rawUser) => User.fromJson(rawUser)).toList();
  });
}

Future<Channel?> fetchChannelDetailsFromUserID(
    Database db, String userID) async {
  final results = await db.query(
    'channel_users',
    where: 'user_id = ?',
    whereArgs: [userID],
  );

  if (results.isEmpty) return null;

  final channelId = results.first['channel_id'] as int;
  final channelDetails = await fetchChannelDataByChannelID(db, channelId);
  return channelDetails;
}
