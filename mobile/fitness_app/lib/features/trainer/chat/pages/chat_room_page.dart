import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomPage({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription? _subscription;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribe();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await SupabaseClientService()
          .client
          .from('chat_messages')
          .select()
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _messages = (response as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe() {
    _subscription = SupabaseClientService()
        .client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true)
        .limit(1)
        .listen((_) => _loadMessages());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      final userId = SupabaseClientService().client.auth.currentUser!.id;
      await SupabaseClientService().client.from('chat_messages').insert({
        'room_id': widget.roomId,
        'sender_id': userId,
        'content': text,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseClientService().client.auth.currentUser!.id;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(CupertinoIcons.chevron_back, color: CupertinoAppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Chat',
                  style: sfText(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41)),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator(radius: 12, color: CupertinoAppColors.primaryBlue))
                  : _messages.isEmpty
                      ? Center(
                          child: Text('Start a conversation', style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMe = msg['sender_id'] == userId;
                            final content = msg['content'] as String? ?? '';
                            final time = msg['created_at'] as String? ?? '';
                            final timeStr = time.length >= 16 ? time.substring(11, 16) : '';

                            return Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isMe ? CupertinoAppColors.primaryBlue : CupertinoAppColors.cardElevated,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(3),
                                      bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(14),
                                    ),
                                  ),
                                  child: Text(content, style: sfText(
                                    fontSize: 13, fontWeight: FontWeight.w400,
                                    color: isMe ? CupertinoAppColors.textPrimary : CupertinoAppColors.textPrimary,
                                    letterSpacing: -0.08,
                                  )),
                                ),
                                if (timeStr.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2, left: isMe ? 0 : 2, right: isMe ? 2 : 0),
                                    child: Text(timeStr, style: sfText(fontSize: 11, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                                  ),
                                const SizedBox(height: 6),
                              ],
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              decoration: BoxDecoration(
                color: CupertinoAppColors.background,
                border: Border(top: BorderSide(color: CupertinoAppColors.separator.withAlpha(100))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.cardElevated,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: CupertinoAppColors.separator),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: TextStyle(color: CupertinoAppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textPrimary, letterSpacing: -0.08),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        color: CupertinoAppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.paperplane, color: CupertinoAppColors.textPrimary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
