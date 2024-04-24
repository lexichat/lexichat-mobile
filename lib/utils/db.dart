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
Future<Map<User, Conversation>> fetchUsersWithLatestConversation(
    Database db) async {
  final channelConversations = <String, Conversation>{};

  final channelDetails = await db.query(
    'channels',
    columns: ['id', 'channel_name'],
    distinct: true,
  );

  List<int> channelIDs =
      channelDetails.map((channel) => channel['id'] as int).toList();

  print("channelids: ${channelIDs}");
  Map<int, Conversation> mostRecentChannelsMessage =
      await _fetchMostRecentChannelsMessage(db, channelIDs);

  for (final channel in channelDetails) {
    final channelId = channel['id'] as int;
    channelConversations[channel['channel_name'].toString()] =
        mostRecentChannelsMessage[channelId] ?? Conversation.empty();
  }

  // Fetch user details
  List<User> users =
      await fetchUsersByUsernames(db, channelConversations.keys.toList());

  // Create a map with User as the key and Conversation as the value
  Map<User, Conversation> usersWithLatestConversation = {};
  for (var user in users) {
    final channelName = user.userName;
    if (channelConversations.containsKey(channelName)) {
      usersWithLatestConversation[user] = channelConversations[channelName]!;
    }
  }

  return usersWithLatestConversation;
}

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
    print("con conversations found in channel");
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
Future<void> CreateChannelIfNotExists(User otherUser, Database db) async {
  // check if userID exists from channel.channel_name
  String query = "SELECT channel_name FROM channels WHERE channel_name = ?";
  List<Map<String, dynamic>> result =
      await db.rawQuery(query, [otherUser.userName]);

  print("isNewChannel creation? ${result.length == 0}");

  // if exists, call readLatestMessagesFromChannel()
  if (result.length > 0) {
    return;
  } else {
    // Else, create channel
    int channelID = await _createChannelServer(otherUser.userID);
    print("channel id that was created: ${channelID}");
    if (channelID == -1) {
      return;
    }
    await _createChannelLocally(db, channelID, otherUser.userName);
    await _populateChannelUsersLocally(
        db, channelID, [otherUser.userID, config.userDetails.userID]);
  }
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
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

Future<int> _createChannelServer(String otherUserID) async {
  String apiUrl = config.BASE_API_URL! + '/api/v1/channels/create';

  Map<String, dynamic> requestBody = {
    'channel_name': otherUserID,
    'tonality_tag': '',
    'description': '',
    'users': [otherUserID, config.userDetails.userID]
  };

  String jsonBody = jsonEncode(requestBody);

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

Future<void> _createChannelLocally(
    Database db, int channelID, String channelName) async {
  try {
    await db.insert(
      "channels",
      {
        'channel_name': channelName,
        'id': channelID,
        'tonality_tag': '',
        'description': '',
        'created_at': DateTime.now().millisecondsSinceEpoch.toString()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    print("Error inserting channel ${e}");
  }
}

Future<void> _populateChannelUsersLocally(
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
  // Execute SELECT query to fetch channel data based on the channel name

  print("channel name: ${channelName}");
  List<Map<String, dynamic>> results = await db.query(
    'channels',
    where: 'channel_name = ?',
    whereArgs: [channelName],
    limit: 1, // Limit the query to return only one row
  );

  print("channel details: ${results}");

  // If results are empty, return null
  if (results.isEmpty) {
    return null;
  }

  // Otherwise, cast the first row of results to the Channel model

  Channel tmp = Channel.fromMap(results.first);
  print("tmp: ${tmp.toString()}");
  return tmp;
}
