import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ChannelChatScreen extends StatefulWidget {
  final ChatChannel channel;

  const ChannelChatScreen({super.key, required this.channel});

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(AppProvider provider) {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    provider.addNote(text, channelId: widget.channel.id);
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final channel = provider.channels.cast<ChatChannel?>().firstWhere(
              (c) => c!.id == widget.channel.id,
              orElse: () => widget.channel,
            )!;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to channels',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Text(channel.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${channel.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: channel.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(channel.icon,
                                style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Welcome to #${channel.name}!',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Start the conversation',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: channel.messages.length,
                        itemBuilder: (context, index) {
                          return _MessageBubble(note: channel.messages[index]);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  border: Border(top: BorderSide(color: AppColors.countyBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Message #${channel.name}...',
                            hintStyle:
                                const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.secondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _sendMessage(provider),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.accent,
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 18),
                          onPressed: () => _sendMessage(provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Note note;
  const _MessageBubble({required this.note});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(note.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(note.authorName[0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(note.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(timeStr,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(note.content,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
