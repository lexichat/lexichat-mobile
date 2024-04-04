import 'package:flutter/material.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/screens/llm_setup.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:lexichat/utils/user_discovery.dart';

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
    return Scaffold(
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
          : ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ProfileTile(
                  profileImage: '',
                  username: 'User $index',
                  lastMessage: 'This is the last message from user $index',
                  time: '10:30 AM',
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
          return ListTile(
            leading: CircleAvatar(
              child: Text(user.userName[0]),
            ),
            title: Text(user.userName),
            subtitle: Text(user.phoneNumber),
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
          // Add more options here
        ],
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final String profileImage;
  final String username;
  final String lastMessage;
  final String time;

  const ProfileTile({
    required this.profileImage,
    required this.username,
    required this.lastMessage,
    required this.time,
  });

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
              builder: (context) => ChatScreen(profileName: username),
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
                    username[0],
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
                      username,
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
  final String profileName;

  ChatScreen({required this.profileName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [
    {
      "from_user_id": "User 0",
      "message": "Hello, this is a long message. how you doing, im doing great",
      "created_at": DateTime.now(),
      "status": "read"
    },
    {
      "from_user_id": "User 1",
      "message": """
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
""",
      "created_at": DateTime.now(),
      "status": "delivered"
    },
  ];

  late TextEditingController _messagingController;

  @override
  void initState() {
    super.initState();
    _messagingController = TextEditingController();
    // fetchMessagesReverseChronologically();
  }

  @override
  void dispose() {
    _messagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg3,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.profileName),
        backgroundColor: bg1,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              // reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return MessageTile(
                  message: messages[index]["message"],
                  isCurrentUser:
                      messages[index]["from_user_id"] == widget.profileName,
                  status: messages[index]["status"],
                  timestamp: messages[index]["created_at"].toString(),
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
                    decoration: InputDecoration(
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
                    onPressed: () {
                      // Send message
                      sendMessage(_messagingController.text);
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

  void sendMessage(String message) {
    setState(() {
      messages.add(
        {
          "from_user_id": widget.profileName,
          "message": message,
          "created_at": DateTime.now(),
          "status": "pending",
        },
      );
    });
    _messagingController.clear();
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
    if (status == 'pending') {
      return const Icon(
        ChatIcons.accessTime,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == 'sent') {
      return const Icon(
        ChatIcons.done,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == 'delivered') {
      return const Icon(
        ChatIcons.doneAll,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == 'read') {
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
