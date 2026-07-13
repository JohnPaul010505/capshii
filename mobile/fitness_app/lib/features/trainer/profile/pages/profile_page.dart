import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/providers/auth_provider.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import 'package:google_fonts/google_fonts.dart';

final trainerProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  return SupabaseClientService()
      .client
      .from('profiles')
      .select('id, full_name, email, created_at')
      .eq('id', userId)
      .single();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(trainerProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final name = profile['full_name'] as String? ?? 'Trainer';
            final email = profile['email'] as String? ?? '';
            final initials = name.split(' ').map((n) => n[0]).take(2).join();
            final createdAt = profile['created_at'] as String? ?? '';
            final since = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const ClampingScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                // Avatar & badge
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoAppColors.cardElevated,
                            ),
                            alignment: Alignment.center,
                            child: Text(initials, style: sfText(
                              color: CupertinoAppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: CupertinoAppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.person, color: CupertinoAppColors.textPrimary, size: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: sfText(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: 0.38)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: const BoxDecoration(
                          color: CupertinoAppColors.primaryBlue,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Text('TRAINER',
                          style: sfText(color: CupertinoAppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          color: CupertinoAppColors.groupedBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.bolt, color: CupertinoAppColors.textQuaternary, size: 12),
                            SizedBox(width: 5),
                            const Text('Strength & HIIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Info card 1
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoAppColors.groupedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(icon: CupertinoIcons.mail, label: 'Email', value: email),
                      _InfoRow(icon: CupertinoIcons.shield, label: 'Role', value: 'Trainer'),
                      if (since.isNotEmpty)
                        _InfoRow(icon: CupertinoIcons.calendar, label: 'Since', value: since),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Info card 2 — Specialty & Availability
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoAppColors.groupedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CupertinoAppColors.separator.withAlpha(100)),
                  ),
                  child: const Column(
                    children: [
                      _InfoRow(icon: CupertinoIcons.star, label: 'Specialty', value: 'Strength & HIIT'),
                      _InfoRow(icon: CupertinoIcons.calendar, label: 'Available', value: 'Mon, Wed, Fri'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Consumer(
                  builder: (_, ref, __) => PressableCard(
                    onTap: () => ref.read(authProvider.notifier).signOut(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    color: CupertinoAppColors.red.withAlpha(15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: CupertinoAppColors.red.withAlpha(50)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.square_arrow_right, color: CupertinoAppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Text('Sign Out',
                          style: sfText(color: CupertinoAppColors.red, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.24)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 72, height: 72, borderRadius: 36),
                SizedBox(height: 12),
                SkeletonBox(width: 140, height: 18),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 24, borderRadius: 12),
                SizedBox(height: 24),
                SkeletonBox(height: 150),
                SizedBox(height: 12),
                SkeletonBox(height: 50),
              ],
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e', style: sfText(fontSize: 12, fontWeight: FontWeight.w400, color: CupertinoAppColors.textQuaternary))),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoAppColors.separator)),
        ),
        child: Row(
          children: [
            Icon(icon, color: CupertinoAppColors.textTertiary, size: 16),
            const SizedBox(width: 10),
            Text(label, style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
            const Spacer(),
            Text(value, style: sfText(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoAppColors.textPrimary, letterSpacing: -0.08)),
          ],
        ),
      ),
    );
  }
}
