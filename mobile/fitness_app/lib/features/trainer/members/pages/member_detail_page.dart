import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/profile.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';

final memberDetailProvider = FutureProvider.family<Profile?, String>((ref, id) async {
  final client = SupabaseClientService().client;
  final response = await client.from('profiles').select().eq('id', id).single();
  return Profile.fromJson(response);
});

class MemberDetailPage extends ConsumerWidget {
  final String id;
  const MemberDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailProvider(id));

    return Scaffold(
      body: SafeArea(
        child: memberAsync.when(
          data: (member) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(CupertinoIcons.chevron_back, color: CupertinoAppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CupertinoAppColors.cardElevated,
                      ),
                      alignment: Alignment.center,
                      child: Text(member!.fullName[0], style: sfText(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Text(member.fullName, style: sfText(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: -0.24)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoAppColors.groupedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: CupertinoAppColors.separator)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoAppColors.cardElevated,
                              ),
                              alignment: Alignment.center,
                              child: Text(member.fullName[0], style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.fullName, style: sfText(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41)),
                                  Text(member.email, style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoAppColors.groupedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                  ),
                  child: Column(
                    children: [
                      _DetailTile(icon: CupertinoIcons.figure_walk, title: 'View Workouts', onTap: () {}),
                      _DetailTile(icon: CupertinoIcons.graph_up, title: 'View Progress', onTap: () {}),
                      _DetailTile(icon: CupertinoIcons.bubble_left, title: 'Submit Feedback', onTap: () {}),
                      _DetailTile(icon: CupertinoIcons.flag, title: 'Goals', onTap: () {}),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator(radius: 14, color: CupertinoAppColors.primaryBlue)),
          error: (e, _) => Center(child: Text('Error: $e', style: sfText(fontSize: 12, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary))),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DetailTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoAppColors.separator)),
        ),
        child: Row(
          children: [
            Icon(icon, color: CupertinoAppColors.textTertiary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: sfText(fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoAppColors.textPrimary, letterSpacing: -0.24))),
            const Icon(CupertinoIcons.chevron_forward, color: CupertinoAppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
