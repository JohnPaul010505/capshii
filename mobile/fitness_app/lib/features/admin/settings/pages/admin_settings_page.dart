import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/cupertino_theme.dart';

final systemInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  return {
    'Version': '1.0.0',
    'Platform': 'Fitness Tracker',
    'Flutter SDK': '3.x',
    'Database': 'Supabase',
  };
});

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(systemInfoProvider);

    return Scaffold(
      backgroundColor: CupertinoAppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Settings',
                style: sfText(fontSize: 28, fontWeight: FontWeight.w700, color: CupertinoAppColors.textPrimary),
              ),
            ),
            Expanded(
              child: infoAsync.when(
                data: (info) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      'System Info',
                      style: sfText(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: info.entries.map((e) => _InfoRow(label: e.key, value: e.value)).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Danger Zone',
                      style: sfText(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoAppColors.red, letterSpacing: -0.08),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoAppColors.red.withAlpha(200), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sensitive admin operations are not available in this build.',
                              style: sfText(fontSize: 15, fontWeight: FontWeight.w400, color: CupertinoAppColors.red.withAlpha(200), letterSpacing: -0.24),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
                loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Error: $e',
                      style: sfText(fontSize: 15, color: CupertinoAppColors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoAppColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(label, style: sfText(fontSize: 15, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.24)),
          const Spacer(),
          Text(value, style: sfText(fontSize: 17, fontWeight: FontWeight.w400, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41)),
        ],
      ),
    );
  }
}
