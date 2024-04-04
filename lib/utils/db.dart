import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:lexichat/models/Chat.dart';

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
      sender_user_id  INTEGER,
      message         TEXT,
      status          TEXT,

    FOREIGN KEY (channel_id) REFERENCES channels(id),
    FOREIGN KEY (sender_user_id) REFERENCES users(id)
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
    await txn.insert('conversations', conversation.toMap());
  });
}

// Update status
Future<void> updateStatus(
    Database db, String conversationId, String status) async {
  await db.update(
    'conversations',
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
Future<Map<String, Conversation>> readChannelsWithLatestMessage(
    Database db) async {
  final channelsWithLatestMessage = <String, Conversation>{};

  final channelIds = await db.query(
    'conversations',
    columns: ['channel_id'],
    distinct: true,
  );

  for (final channelId in channelIds) {
    final latestMessage = await db.query(
      'conversations',
      where: 'channel_id = ?',
      whereArgs: [channelId['channel_id']],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (latestMessage.isNotEmpty) {
      channelsWithLatestMessage[channelId['channel_id'].toString()] =
          Conversation.fromMap(latestMessage.first);
    }
  }

  return channelsWithLatestMessage;
}

// Read latest n messages from a channel
Future<List<Conversation>> readLatestMessagesFromChannel(
    Database db, int channelId, int limit) async {
  final conversations = await db.query(
    'conversations',
    where: 'channel_id = ?',
    whereArgs: [channelId],
    orderBy: 'created_at DESC',
    limit: limit,
  );
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
