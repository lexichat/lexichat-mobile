class Channel {
  final int id;
  final String channelName;
  final DateTime? createdAt;
  final String tonalityTag;
  final String description;

  Channel({
    required this.id,
    required this.channelName,
    required this.createdAt,
    required this.tonalityTag,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_name': channelName,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'tonality_tag': tonalityTag,
      'description': description,
    };
  }

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'],
      channelName: map['channel_name'],
      createdAt: map['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(map['created_at'])),
      tonalityTag: map['tonality_tag'],
      description: map['description'],
    );
  }
}

class Conversation {
  final String id;
  final int channelId;
  final DateTime createdAt;
  final String fromUserId;
  final String message;
  final String status;

  Conversation({
    required this.id,
    required this.channelId,
    required this.createdAt,
    required this.fromUserId,
    required this.message,
    required this.status,
  });

  @override
  String toString() {
    return 'Conversation(id: $id, channelId: $channelId, createdAt: $createdAt, fromUserId: $fromUserId, message: $message, status: $status)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_id': channelId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sender_user_id': fromUserId,
      'message': message,
      'status': status,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      channelId: map['channel_id'],
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(int.parse(map['created_at'])),
      fromUserId: map['sender_user_id'],
      message: map['message'],
      status: map['status'],
    );
  }
  factory Conversation.empty() {
    return Conversation(
      id: '',
      channelId: 0,
      createdAt: DateTime.now(),
      fromUserId: '',
      message: '',
      status: '',
    );
  }
}

class ChannelUser {
  final String channelId;
  final String userId;

  ChannelUser({
    required this.channelId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'channel_id': channelId,
      'user_id': userId,
    };
  }
}
