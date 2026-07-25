import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/widget_support.dart';

class OrderChatPage extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String driverId;
  final String customerName;
  final String driverName;
  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;
  final Color primaryColor;

  const OrderChatPage({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.driverId,
    required this.customerName,
    required this.driverName,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    required this.primaryColor,
  });

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  final DatabaseMethods _database = DatabaseMethods();

  bool _sending = false;
  bool _ready = false;
  String? _setupError;

  bool get _isCustomer => widget.currentUserRole.toLowerCase() == 'customer';

  String get _chatId => _database.accountChatId(
    widget.customerId,
    widget.driverId,
  );

  String get _otherPartyName => _isCustomer
      ? (widget.driverName.isNotEmpty ? widget.driverName : 'Driver')
      : (widget.customerName.isNotEmpty ? widget.customerName : 'Customer');

  @override
  void initState() {
    super.initState();
    _prepareChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _prepareChat() async {
    try {
      await _database.ensureOrderChat(
        orderId: widget.orderId,
        customerId: widget.customerId,
        driverId: widget.driverId,
        customerName: widget.customerName,
        driverName: widget.driverName,
      );
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _setupError = e.toString());
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      await _database.sendOrderChatMessage(
        orderId: widget.orderId,
        customerId: widget.customerId,
        driverId: widget.driverId,
        customerName: widget.customerName,
        driverName: widget.driverName,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderRole: widget.currentUserRole,
        message: message,
      );
      _messageFocus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      _messageController.text = message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  DateTime? _messageTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatTime(dynamic value) {
    final dt = _messageTime(value);
    if (dt == null) return 'Sending';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _header(context),
          Expanded(child: _body()),
          _composer(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: Icon(
                  _isCustomer
                      ? Icons.local_shipping_outlined
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherPartyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF86EFAC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Account chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.86),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _body() {
    if (_setupError != null) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Chat unavailable',
        subtitle: _setupError!,
      );
    }

    if (!_ready) {
      return Center(
        child: CircularProgressIndicator(color: widget.primaryColor),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _database.getOrderChatMessages(_chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: widget.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.sms_failed_outlined,
            title: 'Messages failed to load',
            subtitle: snapshot.error.toString(),
          );
        }

        final messages =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (messages.isEmpty) {
          return _emptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Start the conversation',
            subtitle:
                'Keep pickup, delivery, and payment updates in one place.',
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data();
            return _messageBubble(data);
          },
        );
      },
    );
  }

  Widget _messageBubble(Map<String, dynamic> data) {
    final senderId = (data['SenderId'] ?? '').toString();
    final isMine = senderId == widget.currentUserId;
    final message = (data['Message'] ?? '').toString();
    final senderName = (data['SenderName'] ?? '').toString();
    final createdAt = data['CreatedAt'];

    final bubbleColor = isMine ? widget.primaryColor : AppWidget.surfaceColor;
    final textColor = isMine ? Colors.white : AppWidget.textPrimaryColor;
    final metaColor = isMine
        ? Colors.white.withOpacity(0.74)
        : AppWidget.textSecondaryColor;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            border: isMine ? null : Border.all(color: AppWidget.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppWidget.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine && senderName.isNotEmpty) ...[
                Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBackground = isDark
        ? AppWidget.surfaceAltColor
        : const Color(0xFFEFFBFD);

    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, bottomInset + 10),
      decoration: BoxDecoration(
        color: AppWidget.surfaceColor,
        border: Border(top: BorderSide(color: AppWidget.borderColor)),
        boxShadow: [
          BoxShadow(
            color: AppWidget.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 50, maxHeight: 126),
              decoration: BoxDecoration(
                color: inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.primaryColor.withOpacity(isDark ? 0.28 : 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 14,
                    bottom: 14,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _messageController,
                    focusNode: _messageFocus,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    cursorColor: widget.primaryColor,
                    style: TextStyle(
                      color: AppWidget.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      hintStyle: TextStyle(
                        color: AppWidget.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(
                        24,
                        15,
                        14,
                        15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  widget.primaryColor,
                  widget.primaryColor.withOpacity(0.86),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(isDark ? 0.34 : 0.26),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _sending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(15),
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ):
                       const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: widget.primaryColor.withOpacity(0.72),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppWidget.textPrimaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppWidget.textSecondaryColor,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
