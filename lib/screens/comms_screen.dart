import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'channel_chat_screen.dart';

class CommsScreen extends StatelessWidget {
  const CommsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.surface],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.forum, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('TEAM COMMS',
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.textSecondary),
                    tooltip: 'New channel',
                    onPressed: () => _showAddChannelDialog(context, provider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.channels.isEmpty
                  ? const Center(
                      child: Text('No channels yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.channels.length,
                      itemBuilder: (context, index) {
                        final channel = provider.channels[index];
                        return _ChannelTile(
                          channel: channel,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChannelChatScreen(channel: channel),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            _UserStatusBar(provider: provider),
          ],
        );
      },
    );
  }

  void _showAddChannelDialog(BuildContext context, AppProvider provider) {
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

class _ChannelTile extends StatelessWidget {
  final ChatChannel channel;
  final VoidCallback onTap;

  const _ChannelTile({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: ListTile(
        leading: Text(channel.icon, style: const TextStyle(fontSize: 22)),
        title: Text('#${channel.name}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: channel.messages.isEmpty
            ? const Text('No messages yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
            : Text(
                channel.messages.last.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
        trailing: channel.messages.isNotEmpty
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${channel.messages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _UserStatusBar extends StatelessWidget {
  final AppProvider provider;

  const _UserStatusBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        border: Border(top: BorderSide(color: AppColors.countyBorder)),
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
    );
  }
}
