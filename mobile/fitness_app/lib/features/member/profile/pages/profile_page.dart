import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/providers/auth_provider.dart';
import '../../../../app/cupertino_theme.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: authState.when(
        data: (profile) => SafeArea(
          child: Column(
            children: [
              _buildNavBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: const BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoAppColors.primaryBlue,
                            ),
                            child: Center(
                              child: Text(
                                (profile?.fullName ?? '?')[0].toUpperCase(),
                                style: sfText(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoAppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile?.fullName ?? '',
                            textAlign: TextAlign.center,
                            style: sfText(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CupertinoAppColors.textPrimary,
                              letterSpacing: 0.38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? '',
                            textAlign: TextAlign.center,
                            style: sfText(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: CupertinoAppColors.textSecondary,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FeatureCard(
                      icon: CupertinoIcons.qrcode_viewfinder,
                      title: 'Check In / Check Out',
                      subtitle: 'Scan QR code to check in at the gym',
                      onTap: () => context.push('/member/checkin'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: CupertinoIcons.ruler,
                      title: 'Measurements',
                      subtitle: 'Track your body measurements',
                      onTap: () => context.push('/member/measurements'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: CupertinoIcons.flag,
                      title: 'Goals',
                      subtitle: 'View and manage your fitness goals',
                      onTap: () => context.push('/member/goals'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: CupertinoIcons.doc_text,
                      title: 'Feedback',
                      subtitle: 'Send feedback to your trainer',
                      onTap: () => context.push('/member/feedback'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: CupertinoIcons.bell,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      onTap: () => context.push('/member/notifications'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: CupertinoIcons.settings,
                      title: 'Settings',
                      subtitle: 'Account and app preferences',
                      onTap: () => context.push('/member/settings'),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () =>
                          ref.read(authProvider.notifier).signOut(),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.square_arrow_right,
                            color: CupertinoAppColors.textPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: sfText(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoAppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: sfText(color: CupertinoAppColors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
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
            onPressed: () {},
            child: Icon(
              CupertinoIcons.back,
              color: CupertinoAppColors.primaryBlue,
            ),
          ),
          Expanded(
            child: Text(
              'Profile',
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoAppColors.groupedBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CupertinoAppColors.primaryBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: CupertinoAppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: sfText(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoAppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: sfText(
                      fontSize: 12,
                      color: CupertinoAppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoAppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
