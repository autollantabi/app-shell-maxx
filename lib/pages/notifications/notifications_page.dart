import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/notifications_api.dart';
import '../../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  NotificationsResponse? _response;
  final List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await NotificationsApi.getMyNotifications(
        limit: 20,
        offset: 0,
        soloNoLeidas: true,
      );
      if (result.success && result.data != null) {
        final parsed = NotificationsResponse.fromJson(result.data!);
        setState(() {
          _response = parsed;
          _notifications
            ..clear()
            ..addAll(parsed.notifications);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message.isNotEmpty
              ? result.message
              : 'Error al cargar notificaciones';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification, int index) async {
    // Quitar de la lista localmente de inmediato para una UX fluida
    setState(() {
      _notifications.removeAt(index);
    });

    try {
      await NotificationsApi.markAsRead(notification.id);
    } catch (_) {
      // Si falla, reincorporar la notificación en su posición original
      if (mounted) {
        setState(() {
          _notifications.insert(index, notification);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 120,
        leading: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Image.asset(
            'assets/images/brand/2-LOGO-CLUB-SHELL-MAXX-.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ShellBook',
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _fetchNotifications,
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(
                        fontFamily: 'ShellHeavy',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: 70,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No hay nuevas notificaciones',
                      style: TextStyle(
                        fontFamily: 'ShellHeavy',
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        return Dismissible(
          key: ValueKey(notif.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _markAsRead(notif, index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.green,
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: _NotificationTile(notification: notif),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  Color _colorForEventType(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'CANJE_REGISTRADO':
        return const Color(0xFFE8A020);
      case 'PUNTOS_ACUMULADOS':
        return const Color(0xFF4CAF50);
      case 'CUMPLEANOS':
        return const Color(0xFFE91E63);
      default:
        return AppColors.primary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }

  Widget _iconAssetFor(NotificationModel n) {
    final combined = '${n.title} ${n.message} ${n.eventType}'.toLowerCase();
    if (combined.contains('puntos extras acreditados')) {
      return const Icon(Icons.star, color: Color(0xFFE8A020), size: 40);
    }
    if (combined.contains('canje') || combined.contains('producto')) {
      return Image.asset('assets/images/icons/gift.png', fit: BoxFit.contain);
    }
    return Image.asset('assets/images/icons/guys.png', fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForEventType(notification.eventType);
    final isUnread = !notification.isRead;

    return Container(
      color: isUnread ? color.withOpacity(0.05) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo de notificación
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: _iconAssetFor(notification),
              ),
            ),
            const SizedBox(width: 14),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'ShellHeavy',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: TextStyle(
                          fontFamily: 'ShellBook',
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontFamily: 'ShellBook',
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                ],
              ),
            ),
            // Indicador de no leída
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
