class Channel {
  final String id;
  final DateTime createdAt;
  final String tonalityTag;
  final String description;

  Channel({
    required this.id,
    required this.createdAt,
    required this.tonalityTag,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.millisecondsSinceEpoch,
      'tonality_tag': tonalityTag,
      'description': description,
    };
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'channel_id': channelId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'from_user_id': fromUserId,
      'message': message,
      'status': status,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      channelId: map['channel_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      fromUserId: map['from_user_id'],
      message: map['message'],
      status: map['status'],
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
