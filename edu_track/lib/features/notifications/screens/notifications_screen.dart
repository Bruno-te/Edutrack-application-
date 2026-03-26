import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/bloc/auth_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<NotificationModel>> _stream;
  late String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.user.id;
      _stream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map(NotificationModel.fromFirestore)
              .toList());
    } else {
      _stream = const Stream.empty();
      _userId = '';
    }
  }

  Future<void> _markAllRead(List<NotificationModel> notifs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in notifs.where((n) => !n.isRead)) {
      batch.update(
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(n.id),
        {'isRead': true},
      );
    }
    await batch.commit();
  }

  Future<void> _markRead(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _stream,
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              final unread =
                  snap.data!.where((n) => !n.isRead).toList();
              if (unread.isEmpty) return const SizedBox();
              return TextButton.icon(
                onPressed: () => _markAllRead(snap.data!),
                icon: const Icon(Icons.done_all,
                    color: Colors.white, size: 18),
                label: const Text('Mark All Read',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              subtitle:
                  'You\'ll see grade updates, attendance alerts, and assignment reminders here.',
            );
          }

          final notifs = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) => _NotifCard(
              notif: notifs[i],
              onTap: () => _markRead(notifs[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.grade:
        return Icons.grade_outlined;
      case NotificationType.attendance:
        return Icons.how_to_reg_outlined;
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.grade:
        return AppColors.primary;
      case NotificationType.attendance:
        return AppColors.success;
      case NotificationType.assignment:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.white
              : _color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : _color.withOpacity(0.3),
          ),
          boxShadow: notif.isRead
              ? []
              : [
                  BoxShadow(
                    color: _color.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.body,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif.createdAt),
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d, y').format(dt);
  }
}
