class NotificationActor {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final int? roleId;

  NotificationActor({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    this.roleId,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['ID'] ?? json['id'] ?? '',
      name: json['NAME'] ?? json['name'] ?? '',
      lastName: json['LASTNAME'] ?? json['lastName'] ?? '',
      email: json['EMAIL'] ?? json['email'] ?? '',
      roleId: json['ROLE_ID'] ?? json['roleId'],
    );
  }

  String get fullName {
    final ln = lastName.trim();
    return ln.isNotEmpty ? '${name.trim()} $ln' : name.trim();
  }
}

class NotificationModel {
  final int id;
  final String recipientUserId;
  final String actorUserId;
  final String eventType;
  final String title;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotificationActor? actor;

  NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.actorUserId,
    required this.eventType,
    required this.title,
    required this.message,
    this.metadata,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.actor,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['ID'] ?? json['id'] ?? 0,
      recipientUserId: json['RECIPIENT_USER_ID'] ?? json['recipientUserId'] ?? '',
      actorUserId: json['ACTOR_USER_ID'] ?? json['actorUserId'] ?? '',
      eventType: json['EVENT_TYPE'] ?? json['eventType'] ?? '',
      title: json['TITLE'] ?? json['title'] ?? '',
      message: json['MESSAGE'] ?? json['message'] ?? '',
      metadata: json['METADATA'] != null
          ? Map<String, dynamic>.from(json['METADATA'])
          : null,
      isRead: json['IS_READ'] ?? json['isRead'] ?? false,
      readAt: json['READ_AT'] != null
          ? DateTime.tryParse(json['READ_AT'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      actor: json['ACTOR'] != null
          ? NotificationActor.fromJson(json['ACTOR'] as Map<String, dynamic>)
          : null,
    );
  }
}

class NotificationsResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;

  NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final notifsList = (data['notifications'] as List<dynamic>? ?? [])
        .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();

    return NotificationsResponse(
      notifications: notifsList,
      total: data['total'] ?? 0,
      unreadCount: data['unreadCount'] ?? 0,
      limit: data['limit'] ?? 20,
      offset: data['offset'] ?? 0,
    );
  }
}
