import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final response = await SupabaseClientService()
      .client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return response as List<Map<String, dynamic>>;
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, 'Notifications'),
            Expanded(
              child: notifAsync.when(
                data: (notifs) {
                  if (notifs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoAppColors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return Container(
                    decoration: const BoxDecoration(
                      color: CupertinoAppColors.groupedBackground,
                    ),
                    child: ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, i) {
                        final n = notifs[i];
                        final isLast = i == notifs.length - 1;
                        return Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Icon(
                                    CupertinoIcons.bell,
                                    color: CupertinoAppColors.primaryBlue,
                                    size: 24,
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      if (n['read'] == false) {
                                        await SupabaseClientService().client
                                            .from('notifications')
                                            .update({'read': true})
                                            .eq('id', n['id']);
                                        ref.invalidate(notificationsProvider);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['title'] ?? '',
                                            style: sfText(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              color: CupertinoAppColors.textPrimary,
                                              letterSpacing: -0.41,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            n['message'] ?? '',
                                            style: sfText(
                                              fontSize: 15,
                                              color: CupertinoAppColors.textSecondary,
                                              letterSpacing: -0.24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                                  child: CupertinoSwitch(
                                    value: n['read'] == true,
                                    onChanged: (value) async {
                                      if (!value) {
                                        await SupabaseClientService().client
                                            .from('notifications')
                                            .update({'read': true})
                                            .eq('id', n['id']);
                                        ref.invalidate(notificationsProvider);
                                      }
                                    },
                                    activeColor: CupertinoAppColors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast)
                              const Divider(
                                color: CupertinoAppColors.separator,
                                height: 0.5,
                                thickness: 0.5,
                                indent: 72,
                                endIndent: 0,
                              ),
                          ],
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: sfText(color: CupertinoAppColors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoAppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: const Icon(
              CupertinoIcons.back,
              color: CupertinoAppColors.primaryBlue,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: sfText(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoAppColors.textPrimary,
                letterSpacing: -0.41,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
