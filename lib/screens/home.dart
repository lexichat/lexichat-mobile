import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lexichat/models/Chat.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/screens/ai_chat.dart';
import 'package:lexichat/screens/llm_setup.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:lexichat/utils/db.dart';
import 'package:lexichat/utils/user_discovery.dart';
import 'package:lexichat/utils/ws_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:lexichat/config/config.dart' as config;

const bg1 = Color(0xFFF5F5F5);
const bg2 = Color(0xFFF5F5DC);
const bg3 = Color(0xFFFBF7F2);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  List<User> _searchResults = [];
  Map<User, Conversation> _userProfilesWithLatestMessage = {};
  Map<int, Channel> _allChannelsCache = {};
  Map<String, User> _allUsersCache = {};
  bool _isLoading = true;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _newUserChatSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles(DBClient);
    _populateChannelCache(DBClient);
    _populateUsersCache(DBClient);

    _messageSubscription =
        config.wsManager.messageStream.listen(_handleReceivingMessages);
    _newUserChatSubscription =
        config.fcmManager.newUserChatStream.listen(_handleIncomingNewUserChat);
  }

  void _fetchUserProfiles(Database db) async {
    _userProfilesWithLatestMessage = await fetchUsersWithLatestConversation(db);
    // sort by timestamp of message DESC
    sortUserProfileMessagesByDESCTimeStamp();
    print("user profiles with latest message");
    print(_userProfilesWithLatestMessage);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleReceivingMessages(Conversation message) async {
    // fetch user details from userid
    User user = _allUsersCache[message.fromUserId]!;
    print("user cache hit ${user.userID}");
    // update from utc to user's time zone
    message.createdAt = message.createdAt.toLocal();

    print("incoming message: ${message}");

    setState(() {
      _userProfilesWithLatestMessage[user] = message;
      sortUserProfileMessagesByDESCTimeStamp();
    });
  }

  Future<void> _handleIncomingNewUserChat(
      Map<User, Conversation> otherUserFirstMsg) async {
    User otherUser = otherUserFirstMsg.keys.first;
    Conversation firstMessage = otherUserFirstMsg[otherUser]!;
    firstMessage.createdAt = firstMessage.createdAt.toLocal();

    setState(() {
      _userProfilesWithLatestMessage[otherUser] = firstMessage;
      sortUserProfileMessagesByDESCTimeStamp();
      _allUsersCache[otherUser.userID] = otherUser;
    });
  }

  void _populateChannelCache(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query('channels');
    for (final map in maps) {
      final channel = Channel.fromMap(map);
      _allChannelsCache[channel.id] = channel;
    }
  }

  void _populateUsersCache(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query('users');
    for (final map in maps) {
      final user = User.fromJson(map);
      _allUsersCache[user.userID] = user;
    }
  }

  void updateUserProfilesWithLatestMessage(
      User user, Conversation conversation) {
    setState(() {
      _userProfilesWithLatestMessage[user] = conversation;
      sortUserProfileMessagesByDESCTimeStamp();
    });
    print("_userProfilesWithLatestMessage: ${_userProfilesWithLatestMessage}");
  }

  void sortUserProfileMessagesByDESCTimeStamp() {
    _userProfilesWithLatestMessage = Map.fromEntries(
      _userProfilesWithLatestMessage.entries.toList()
        ..sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt)),
    );
  }

  void _toggleSearching() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchResults = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container()
        : Scaffold(
            backgroundColor: bg3,
            appBar: MyAppBar(
              isSearching: _isSearching,
              onSearch: (query) {
                setState(() {
                  _isSearching = true;
                  _searchQuery = query;
                });
                _performSearch(query);
              },
              onClearSearch: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchResults = [];
                });
                // _toggleSearching();
              },
              toggleSearching: _toggleSearching,
            ),
            drawer: MoreOptionsDrawer(),
            body: _isSearching
                ? Container(
                    child: showSearchResults(),
                  )
                : _userProfilesWithLatestMessage.length == 0
                    ? Center(
                        child: Text('Search for people and start chatting'),
                      )
                    : ListView.builder(
                        itemCount: _userProfilesWithLatestMessage.length,
                        itemBuilder: (context, index) {
                          final channelLastMessage =
                              _userProfilesWithLatestMessage.values
                                  .elementAt(index);
                          String lastMessage = channelLastMessage.message == ""
                              ? "No past messages found with user"
                              : channelLastMessage.message;
                          return ProfileTile(
                            user: _userProfilesWithLatestMessage.keys
                                .elementAt(index),
                            lastMessage: lastMessage,
                            time: DateFormat('hh:mm a')
                                .format((channelLastMessage.createdAt)),
                            updateUserProfileCallback:
                                updateUserProfilesWithLatestMessage,
                          );
                        },
                      ),
          );
  }

  Widget showSearchResults() {
    if (_searchQuery.length < 3) {
      return Center(
        child: Text('Please enter at least 3 characters to search'),
      );
    } else if (_searchResults.isEmpty) {
      return Center(
        child: Text('No results found for "$_searchQuery"'),
      );
    } else {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return GestureDetector(
            onTap: () async {
              // navigate and show chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    otherUser: user,
                    updateUserProfileCallback:
                        updateUserProfilesWithLatestMessage,
                  ),
                ),
              );
              print("clicked on user ${user.userID}");
            },
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.userName[0]),
              ),
              title: Text(user.userName),
              subtitle: Text(user.phoneNumber),
            ),
          );
        },
      );
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      if (query.length < 3) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      final users = await discoverUsersByUserId(query);
      setState(() {
        _searchResults = users;
      });
    } catch (e) {
      print('Error searching for users: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _newUserChatSubscription.cancel();
    super.dispose();
  }
}

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSearch;
  final VoidCallback onClearSearch;
  final bool isSearching;
  final VoidCallback toggleSearching;

  MyAppBar(
      {required this.onSearch,
      required this.onClearSearch,
      required this.isSearching,
      required this.toggleSearching});

  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: bg1,
      elevation: 0,
      title: widget.isSearching
          ? TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Profile',
                border: InputBorder.none,
              ),
              autofocus: true,
              onChanged: widget.onSearch,
            )
          : Text('LexiChat'),
      actions: <Widget>[
        widget.isSearching
            ? IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: Colors.black,
                ),
                onPressed: () {
                  _searchController.clear();
                  widget.onClearSearch();
                },
              )
            : IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    widget.toggleSearching();
                    if (widget.isSearching) {
                      _searchController.clear();
                    }
                  });
                },
              )
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class MoreOptionsDrawer extends StatelessWidget {
  const MoreOptionsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: Text('Home'),
            leading: Icon(Icons.home),
          ),
          ListTile(
            title: Text('Profile'),
            leading: Icon(Icons.person),
          ),
          Divider(),
          ListTile(
            title: Text('LLM SetUp'),
            leading: Icon(Icons.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LLMSetupScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Chat with AI'),
            leading: Icon(Icons.bolt),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AIChatScreen()),
              );
            },
          ),
          // Add more options here
        ],
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final User user;
  final String lastMessage;
  final String time;
  final Function(User, Conversation) updateUserProfileCallback;

  const ProfileTile(
      {required this.user,
      required this.lastMessage,
      required this.time,
      required this.updateUserProfileCallback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.2),
      child: InkWell(
        onTap: () {
          // fetch messages from db in reverse chronological order and pass it to ChatScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUser: user,
                updateUserProfileCallback: updateUserProfileCallback,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 30,
                  child: Text(
                    user.userName[0],
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  time,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final User otherUser;
  final Function(User, Conversation) updateUserProfileCallback;

  ChatScreen(
      {required this.otherUser, required this.updateUserProfileCallback});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Conversation> messages = [];
  late Channel channelDetails;

  late TextEditingController _messagingController;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _messageStatusUpdatesSubscription;

  bool _isLoading = true;
  bool _isCreateNewUserChat = false;

  @override
  void initState() {
    super.initState();
    _messagingController = TextEditingController();
    initializeData();

    _messageSubscription =
        config.wsManager.messageStream.listen(handleReceivingMessages);

    _messageStatusUpdatesSubscription = config
        .wsManager.messageStatusUpdateStream
        .listen(handleMessageStatusUpdates);
  }

  initializeData() async {
    print("other user's name ${widget.otherUser.userName}");
    // Channel? _channelDetails =
    // await _fetchChannelDetails(DBClient, widget.otherUser.userName);

    // if (_channelDetails == null) {
    //   _isCreateNewUserChat = true;
    // }

    // messages = await _fetchMessagesReverseChronologically(
    //     DBClient, _channelDetails?.id ?? -1);

    // messages = messages.reversed.toList();

    // print("messages: ${messages}");

    // setState(() {
    //   if (_channelDetails != null) {
    //     // channelDetails.channelName = "";
    //     channelDetails = _channelDetails;
    //   }
    // });
    Channel? _channelDetails =
        await _fetchChannelDetailsByUserID(DBClient, widget.otherUser.userID);

    messages = await _fetchMessagesReverseChronologically(
        DBClient, _channelDetails?.id ?? -1);

    messages = messages.reversed.toList();

    print("messages: ${messages}");

    if (_channelDetails == null) {
      print("new user chat is set to true");
      _isCreateNewUserChat = true;
    }
    setState(() {
      if (_channelDetails != null) {
        channelDetails = _channelDetails;
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _messagingController.dispose();
    _messageSubscription.cancel();
    _messageStatusUpdatesSubscription.cancel();
    super.dispose();
  }

  Future<void> handleReceivingMessages(Conversation message) async {
    // handle receiving and updating ui
    if (message.fromUserId == widget.otherUser.userID) {
      print("message is being read. ${message}");
      // update timezone to local
      message.createdAt = message.createdAt.toLocal();
      setState(() {
        messages.add(message);
      });
      // widget.updateUserProfileCallback(widget.otherUser, message);
    }
  }

  Future<void> handleMessageStatusUpdates(InBoundMessageAck ack) async {
    if (messages.any((message) => message.id == ack.messageID)) {
      print("message found for status update");
      Conversation msg =
          messages.firstWhere((message) => message.id == ack.messageID);
      setState(() {
        msg.status = ack.status;
      });
    }
  }

  Future<Channel?> _fetchChannelDetails(Database db, String channelName) async {
    Channel? channelDetails = await fetchChannelDataByName(db, channelName);
    // if (channelDetails == null) {
    //   throw Exception("Failed to fetch channel details");
    // }
    return channelDetails;
  }

  Future<Channel?> _fetchChannelDetailsByUserID(
      Database db, String userID) async {
    Channel? channelDetails = await fetchChannelDetailsFromUserID(db, userID);
    print("channel_details:  $channelDetails");
    return channelDetails;
  }

  Future<List<Conversation>> _fetchMessagesReverseChronologically(
      Database db, int channelID) async {
    if (channelID == -1) {
      return [];
    }
    final int _messagesPerBatch = 100;
    int _nextOffSet = 0;
    List<Conversation> latestMessagesFromChannelName =
        await readLatestMessagesFromChannelName(
            db, channelID, _messagesPerBatch, _nextOffSet);
    return latestMessagesFromChannelName;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container()
        : Scaffold(
            backgroundColor: bg3,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(widget.otherUser.userName),
              backgroundColor: bg1,
              elevation: 0,
            ),
            body: Column(
              children: [
                Expanded(
                  child: (messages.length == 0)
                      ? Center(child: Text("Start Chatting"))
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return MessageTile(
                              message: message.message,
                              isCurrentUser:
                                  message.fromUserId != widget.otherUser.userID,
                              status: message.status,
                              timestamp: message.createdAt.toString(),
                            );
                          },
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messagingController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: bg3,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: bg3,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            // check to create channel mechanism here
                            if (_isCreateNewUserChat) {
                              print("START: createChannelMechanism");
                              Conversation message =
                                  await _createChannelMechanism(
                                      _messagingController.text,
                                      Uuid().v4().toString());
                              print("END: createChannelMechanism");
                              _messagingController.clear();
                              FocusManager.instance.primaryFocus?.unfocus();
                              message.status = MessageStatuses.sent.toString();
                              setState(() {
                                messages.add(message);
                              });
                              widget.updateUserProfileCallback(
                                  widget.otherUser, message);
                              //await update local db
                              writeConversation(DBClient, message);

                              return;
                            }
                            sendMessage(Conversation(
                                id: Uuid().v4().toString(),
                                channelId: channelDetails.id,
                                createdAt: DateTime.now(),
                                fromUserId: config.userDetails.userID,
                                message: _messagingController.text,
                                status: MessageStatuses.pending.toString()));
                            FocusManager.instance.primaryFocus?.unfocus();
                            ;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  void sendMessage(Conversation message) {
    print("message id: ${message.id}");
    setState(() {
      messages.add(message);
    });
    widget.updateUserProfileCallback(widget.otherUser, message);
    //await update local db
    writeConversation(DBClient, message);

    // await pushMessageToServer()
    config.wsManager.sendMessage(
        OutBoundMessage(Message: message.message, MessageID: message.id),
        message.channelId);
    _messagingController.clear();
  }

  Future<Conversation> _createChannelMechanism(
      String firstMessage, String messageID) async {
    List<Future> futures = [
      InitiateCreationOfChannelIfNotExists(
          widget.otherUser, firstMessage, messageID, DBClient),
      PopulateUserTableIfNotExists(widget.otherUser, DBClient)
    ];

    List<dynamic> results = await Future.wait(futures);
    int channelID = results[0] as int;

    // update ws manager
    if (channelID != -1) {
      await config.wsManager.addNewWSConnection(channelID);
      setState(() {
        _isCreateNewUserChat = false;
        channelDetails = Channel(
            id: channelID,
            channelName: widget.otherUser.userName,
            createdAt: DateTime.now());
      });
      return Conversation(
          id: messageID,
          channelId: channelID,
          createdAt: DateTime.now(),
          fromUserId: config.userDetails.userID,
          message: firstMessage,
          status: MessageStatuses.pending.toString());
    }
    throw Exception("Failed to create channel. Try again");
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String status;
  final String timestamp;

  MessageTile({
    required this.message,
    required this.isCurrentUser,
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final msgTextStyle = TextStyle(
      color: isCurrentUser ? Colors.white : Colors.black,
      fontSize: 14,
    );

    final msgContainerWidthAddition = 50;

    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: getTextWidth(message, msgTextStyle) +
                            msgContainerWidthAddition >
                        mediaQuery.size.width * 0.7
                    ? mediaQuery.size.width * 0.7
                    : getTextWidth(message, msgTextStyle) +
                        msgContainerWidthAddition,
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blueGrey : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: isCurrentUser
                        ? Radius.circular(16.0)
                        : Radius.circular(0.0),
                    bottomRight: isCurrentUser
                        ? Radius.circular(0.0)
                        : Radius.circular(16.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    message,
                    style: msgTextStyle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(DateTime.parse(timestamp)),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    ),
                    if (isCurrentUser)
                      SizedBox(
                        width: 4.0,
                        child: getStatusIcon(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double getTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final tp =
        TextPainter(text: textSpan, textDirection: painting.TextDirection.ltr);
    tp.layout();
    return tp.width;
  }

  Widget getStatusIcon(String status) {
    if (status == MessageStatuses.pending.toString()) {
      return const Icon(
        ChatIcons.accessTime,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.sent.toString()) {
      return const Icon(
        ChatIcons.done,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.delivered.toString()) {
      return const Icon(
        ChatIcons.doneAll,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.read.toString()) {
      return const Icon(
        ChatIcons.doneAll,
        color: Colors.green,
        size: 16.0,
      );
    }
    return SizedBox();
  }
}

class ChatIcons {
  ChatIcons._();

  static const _kFontFam = 'ChatIcons';
  static const String? _kFontPkg = null;

  static const IconData done =
      IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);
  static const IconData doneAll =
      IconData(0xe801, fontFamily: _kFontFam, fontPackage: _kFontPkg);
  static const IconData accessTime =
      IconData(0xe802, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}
