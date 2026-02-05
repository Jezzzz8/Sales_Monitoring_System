import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/notifications_data.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive.dart';

class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  final Set<String> _selectedNotifications = {};
  bool _isSelectionMode = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode(bool enabled) {
    setState(() {
      _isSelectionMode = enabled;
      if (!enabled) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String id) {
    setState(() {
      if (_selectedNotifications.contains(id)) {
        _selectedNotifications.remove(id);
        if (_selectedNotifications.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotifications.add(id);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      }
    });
  }

  void _selectAllNotifications() {
    setState(() {
      _selectedNotifications.clear();
      _selectedNotifications.addAll(
        NotificationsData.notifications.map((n) => n.id),
      );
      _isSelectionMode = true;
    });
  }

  void _deselectAllNotifications() {
    setState(() {
      _selectedNotifications.clear();
      _isSelectionMode = false;
    });
  }

  void _markSelectedAsRead() {
    setState(() {
      for (final id in _selectedNotifications) {
        NotificationsData.markAsRead(id);
      }
      _selectedNotifications.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelectedNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
          'Are you sure you want to delete ${_selectedNotifications.length} notification(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                NotificationsData.notifications.removeWhere(
                  (n) => _selectedNotifications.contains(n.id),
                );
                _selectedNotifications.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(NotificationItem notification) {
    if (_isSelectionMode) {
      _toggleNotificationSelection(notification.id);
    } else {
      // Single tap action - mark as read
      setState(() {
        NotificationsData.markAsRead(notification.id);
      });
    }
  }

  void _onNotificationLongPress(NotificationItem notification) {
    if (!_isSelectionMode) {
      _toggleSelectionMode(true);
      _toggleNotificationSelection(notification.id);
    }
  }

  void _showNotificationActionSheet(NotificationItem notification) {
    final theme = ThemeProvider.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Responsive.getPaddingSize(context) * 2),
          topRight: Radius.circular(Responsive.getPaddingSize(context) * 2),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Responsive.getPaddingSize(context) * 2),
            topRight: Radius.circular(Responsive.getPaddingSize(context) * 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.getSubtitleColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: Responsive.getSpacing(context).height),
            Text(
              notification.title,
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.getSmallSpacing(context).height),
            Text(
              notification.message,
              style: theme.bodyMedium.copyWith(
                color: theme.getSubtitleColor(),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.getGroupSpacing(context)),
            ListTile(
              leading: Icon(
                notification.isRead 
                  ? Icons.markunread_outlined 
                  : Icons.check_circle_outline,
                color: theme.primaryColor,
              ),
              title: Text(
                notification.isRead ? 'Mark as Unread' : 'Mark as Read',
                style: theme.bodyMedium.copyWith(
                  color: theme.getTextColor(),
                ),
              ),
              onTap: () {
                setState(() {
                  notification.isRead = !notification.isRead;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.errorColor,
              ),
              title: Text(
                'Delete',
                style: theme.bodyMedium.copyWith(
                  color: theme.errorColor,
                ),
              ),
              onTap: () {
                setState(() {
                  NotificationsData.notifications.removeWhere(
                    (n) => n.id == notification.id,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share_outlined,
                color: theme.getTextColor(),
              ),
              title: Text(
                'Share',
                style: theme.bodyMedium.copyWith(
                  color: theme.getTextColor(),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sharing functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (isMobile ? 0.8 : 0.7),
        minWidth: MediaQuery.of(context).size.width * (isMobile ? 1.0 : 0.9),
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(Responsive.getPaddingSize(context) * 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Responsive.getPaddingSize(context) * 2),
                topRight: Radius.circular(Responsive.getPaddingSize(context) * 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: () => _toggleSelectionMode(false),
                        tooltip: 'Cancel selection',
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isSelectionMode 
                        ? '${_selectedNotifications.length} selected'
                        : 'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Show unread count only when NOT in selection mode
                    if (!_isSelectionMode && NotificationsData.unreadCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getFontSize(context, mobile: 6, tablet: 8, desktop: 10),
                          vertical: Responsive.getFontSize(context, mobile: 4, tablet: 6, desktop: 8),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${NotificationsData.unreadCount} new',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    
                    // Selection mode actions
                    if (_isSelectionMode) ...[
                      IconButton(
                        icon: Icon(
                          _selectedNotifications.length == NotificationsData.notifications.length
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank_outlined,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: _selectedNotifications.length == NotificationsData.notifications.length
                          ? _deselectAllNotifications
                          : _selectAllNotifications,
                        tooltip: _selectedNotifications.length == NotificationsData.notifications.length
                          ? 'Deselect all'
                          : 'Select all',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.done_all,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: _markSelectedAsRead,
                        tooltip: 'Mark selected as read',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: _deleteSelectedNotifications,
                        tooltip: 'Delete selected',
                      ),
                    ] else ...[
                      // Normal mode actions (when not in selection mode)
                      IconButton(
                        icon: Icon(
                          Icons.done_all,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: () {
                          setState(() {
                            NotificationsData.markAllAsRead();
                          });
                        },
                        tooltip: 'Mark all as read',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: Responsive.getIconSize(context, multiplier: 0.9),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: NotificationsData.notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(Responsive.getPaddingSize(context) * 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: Responsive.getIconSize(context, multiplier: 3.0),
                            color: theme.getSubtitleColor(),
                          ),
                          SizedBox(height: Responsive.getSpacing(context).height),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                              fontWeight: FontWeight.bold,
                              color: theme.getSubtitleColor(),
                            ),
                          ),
                          SizedBox(height: Responsive.getSmallSpacing(context).height),
                          Text(
                            'When you have notifications, they\'ll appear here',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                              color: theme.getSubtitleColor(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(Responsive.getPaddingSize(context) * 0.8),
                    itemCount: NotificationsData.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = NotificationsData.notifications[index];
                      return _buildNotificationItem(notification, theme);
                    },
                  ),
          ),

          // Selection mode actions (bottom bar) - Only show when in selection mode
          if (_isSelectionMode && _selectedNotifications.isNotEmpty)
            Container(
              padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedNotifications.length} selected',
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _markSelectedAsRead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getPaddingSize(context),
                            vertical: Responsive.getFontSize(context, mobile: 8, tablet: 10, desktop: 12),
                          ),
                        ),
                        icon: Icon(
                          Icons.done_all,
                          size: Responsive.getIconSize(context, multiplier: 0.8),
                        ),
                        label: Text(
                          'Mark as read',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                      OutlinedButton.icon(
                        onPressed: _deleteSelectedNotifications,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.errorColor,
                          side: BorderSide(color: theme.errorColor),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.getPaddingSize(context),
                            vertical: Responsive.getFontSize(context, mobile: 8, tablet: 10, desktop: 12),
                          ),
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          size: Responsive.getIconSize(context, multiplier: 0.8),
                        ),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, AppTheme theme) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.system:
        icon = Icons.settings_outlined;
        color = Colors.blue;
        break;
      case NotificationType.order:
        icon = Icons.shopping_cart_outlined;
        color = Colors.green;
        break;
      case NotificationType.inventory:
        icon = Icons.inventory_2_outlined;
        color = Colors.orange;
        break;
      case NotificationType.payment:
        icon = Icons.payments_outlined;
        color = Colors.purple;
        break;
    }

    final isSelected = _selectedNotifications.contains(notification.id);

    return GestureDetector(
      onLongPress: () => _onNotificationLongPress(notification),
      onTap: () => _onNotificationTap(notification),
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: Responsive.getFontSize(context, mobile: 4, tablet: 6, desktop: 8),
          horizontal: 0,
        ),
        color: notification.isRead 
          ? theme.surfaceColor 
          : theme.primaryColor.withOpacity(0.05),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.getPaddingSize(context)),
          side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
        ),
        child: Container(
          padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox - ONLY SHOWN IN SELECTION MODE
              if (_isSelectionMode)
                Padding(
                  padding: EdgeInsets.only(
                    right: Responsive.getPaddingSize(context),
                    top: Responsive.getPaddingSize(context) * 0.5,
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleNotificationSelection(notification.id),
                    activeColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              
              // Notification icon
              Container(
                width: Responsive.getIconSize(context, multiplier: 1.5),
                height: Responsive.getIconSize(context, multiplier: 1.5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.getIconSize(context, multiplier: 0.8),
                ),
              ),
              
              SizedBox(width: Responsive.getPaddingSize(context)),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.bodyMedium.copyWith(
                              fontWeight: notification.isRead 
                                ? FontWeight.normal 
                                : FontWeight.w600,
                              fontSize: Responsive.getFontSize(
                                context, 
                                mobile: 14, 
                                tablet: 15, 
                                desktop: 16,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: theme.bodySmall.copyWith(
                            color: theme.getSubtitleColor(),
                            fontSize: Responsive.getFontSize(
                              context, 
                              mobile: 10, 
                              tablet: 11, 
                              desktop: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: Responsive.getSmallSpacing(context).height),
                    
                    Text(
                      notification.message,
                      style: theme.bodyMedium.copyWith(
                        color: theme.getSubtitleColor(),
                        fontSize: Responsive.getFontSize(
                          context, 
                          mobile: 12, 
                          tablet: 13, 
                          desktop: 14,
                        ),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: Responsive.getSmallSpacing(context).height),
                    
                    // Action buttons (like Facebook) - only show when NOT in selection mode
                    if (!_isSelectionMode)
                      Row(
                        children: [
                          if (!notification.isRead)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getFontSize(context, mobile: 6, tablet: 8, desktop: 10),
                                vertical: Responsive.getFontSize(context, mobile: 2, tablet: 4, desktop: 6),
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'NEW',
                                style: theme.bodySmall.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.getFontSize(
                                    context, 
                                    mobile: 10, 
                                    tablet: 11, 
                                    desktop: 12,
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: theme.getSubtitleColor(),
                              size: Responsive.getIconSize(context, multiplier: 0.8),
                            ),
                            onPressed: () => _showNotificationActionSheet(notification),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'More options',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Unread indicator - only show when NOT in selection mode
              if (!notification.isRead && !_isSelectionMode)
                Container(
                  width: Responsive.getIconSize(context, multiplier: 0.3),
                  height: Responsive.getIconSize(context, multiplier: 0.3),
                  margin: EdgeInsets.only(left: Responsive.getPaddingSize(context)),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}