import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import 'package:google_fonts/google_fonts.dart';

final chatRoomsWithProfilesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseClientService().client;
  final userId = client.auth.currentUser!.id;

  final rooms = await client
      .from('chat_rooms')
      .select()
      .or('participant_one.eq.$userId,participant_two.eq.$userId')
      .order('created_at', ascending: false);

  final roomList = (rooms as List).cast<Map<String, dynamic>>();
  final result = <Map<String, dynamic>>[];

  for (final room in roomList) {
    final otherId = (room['participant_one'] as String?) == userId
        ? room['participant_two'] as String?
        : room['participant_one'] as String?;
    if (otherId == null) continue;

    try {
      final profile = await client
          .from('profiles')
          .select('id, full_name')
          .eq('id', otherId)
          .single();
      result.add({
        'roomId': room['id'] as String,
        'memberId': otherId,
        'full_name': (profile as Map<String, dynamic>)['full_name'] as String? ?? 'Unknown',
      });
    } catch (_) {}
  }

  return result;
});

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsWithProfilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Conversations',
                    style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: 0.38)),
                  roomsAsync.when(
                    data: (rooms) => Text('${rooms.length} members',
                      style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: roomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.bubble_left, color: CupertinoAppColors.textTertiary, size: 48),
                          const SizedBox(height: 12),
                          Text('No conversations yet', style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary, letterSpacing: -0.08)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final r = rooms[i];
                      final name = r['full_name'] as String? ?? 'Unknown';
                      final initials = name.split(' ').map((n) => n[0]).take(2).join();
                      return Semantics(
                        label: 'Chat with $name',
                        child: PressableCard(
                          onTap: () => context.push('/trainer/chat/${r['roomId']}'),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          color: CupertinoAppColors.groupedBackground,
                          border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CupertinoAppColors.cardElevated,
                                ),
                                alignment: Alignment.center,
                                child: Text(initials, style: sfText(
                                  color: CupertinoAppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: sfText(
                                      fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoAppColors.textPrimary, letterSpacing: -0.24)),
                                    const SizedBox(height: 2),
                                    Text('Tap to open conversation',
                                      style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                                  ],
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_forward, color: CupertinoAppColors.textTertiary, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      SkeletonCard(),
                      SkeletonCard(),
                      SkeletonCard(),
                    ],
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e', style: sfText(fontSize: 12, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
