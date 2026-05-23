import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CommsScreen extends StatefulWidget {
  const CommsScreen({super.key});

  @override
  State<CommsScreen> createState() => _CommsScreenState();
}

class _CommsScreenState extends State<CommsScreen> {
  String? _selectedChannelId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (_selectedChannelId == null && provider.channels.isNotEmpty) {
          _selectedChannelId = provider.channels.first.id;
        }
        final selectedChannel = _selectedChannelId != null
            ? provider.channels.cast<ChatChannel?>().firstWhere(
                (c) => c!.id == _selectedChannelId,
                orElse: () => null)
            : null;

        return Row(
          children: [
            _buildChannelSidebar(provider),
            Expanded(
              child: selectedChannel != null
                  ? _ChatView(channel: selectedChannel, provider: provider)
                  : const Center(
                      child: Text('Select a channel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelSidebar(AppProvider provider) {
    return Container(
      width: 220,
      color: AppColors.secondary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.countyBorder),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.forum, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('CHANNELS',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: () => _showAddChannelDialog(provider),
                  child: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: provider.channels.map((channel) {
                final isSelected = channel.id == _selectedChannelId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChannelId = channel.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    color:
                        isSelected ? AppColors.accent.withAlpha(30) : Colors.transparent,
                    child: Row(
                      children: [
                        Text(channel.icon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(channel.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                        if (channel.messages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${channel.messages.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.countyBorder),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent,
                  child: Text(provider.currentUser.name[0],
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.currentUser.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(provider.currentUser.role.name,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChannelDialog(AppProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('New Channel'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Channel Name',
            prefixText: '# ',
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.addChannel(nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ChatChannel channel;
  final AppProvider provider;

  const _ChatView({required this.channel, required this.provider});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    widget.provider.addNote(text, channelId: widget.channel.id);
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            border: Border(bottom: BorderSide(color: AppColors.countyBorder)),
          ),
          child: Row(
            children: [
              Text(widget.channel.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(widget.channel.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${widget.channel.messages.length} messages',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: widget.channel.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.channel.icon,
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Welcome to #${widget.channel.name}!',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Start the conversation',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.channel.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.channel.messages[index];
                    return _MessageBubble(note: msg);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            border: Border(top: BorderSide(color: AppColors.countyBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Message #${widget.channel.name}...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
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
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.accent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
