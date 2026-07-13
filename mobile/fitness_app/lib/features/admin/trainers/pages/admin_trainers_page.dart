import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/cupertino_theme.dart';

final adminTrainersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseClientService().client;
  final response = await supabase
      .from('profiles')
      .select('id, full_name, email, created_at')
      .eq('role', 'trainer')
      .order('created_at', ascending: false);
  return response;
});

class AdminTrainersPage extends ConsumerStatefulWidget {
  const AdminTrainersPage({super.key});

  @override
  ConsumerState<AdminTrainersPage> createState() => _AdminTrainersPageState();
}

class _AdminTrainersPageState extends ConsumerState<AdminTrainersPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(adminTrainersProvider);

    return Scaffold(
      backgroundColor: CupertinoAppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Trainers',
                style: sfText(fontSize: 28, fontWeight: FontWeight.w700, color: CupertinoAppColors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search trainers...',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                suffixMode: _query.isNotEmpty ? OverlayVisibilityMode.always : OverlayVisibilityMode.editing,
                onSuffixTap: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Expanded(
              child: trainersAsync.when(
                data: (trainers) {
                  final filtered = _query.isEmpty
                      ? trainers
                      : trainers.where((t) =>
                          (t['full_name'] as String? ?? '').toLowerCase().contains(_query) ||
                          (t['email'] as String? ?? '').toLowerCase().contains(_query)).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_crop_circle_badge_xmark, size: 48, color: CupertinoAppColors.textQuaternary),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty ? 'No trainers yet' : 'No matching trainers',
                            style: sfText(fontSize: 15, color: CupertinoAppColors.textTertiary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _TrainerCard(trainer: filtered[i]),
                  );
                },
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

class _TrainerCard extends StatelessWidget {
  final Map<String, dynamic> trainer;

  const _TrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    final name = trainer['full_name'] as String? ?? 'Unknown';
    final email = trainer['email'] as String? ?? '';
    final initials = name.split(' ').map((n) => n[0]).take(2).join();

    return Container(
      decoration: BoxDecoration(
        color: CupertinoAppColors.groupedBackground,
        border: Border(
          bottom: BorderSide(color: CupertinoAppColors.separator, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CupertinoAppColors.neon.withAlpha(25),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: sfText(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoAppColors.neon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: sfText(fontSize: 17, fontWeight: FontWeight.w400, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41)),
                  Text(email, style: sfText(fontSize: 13, fontWeight: FontWeight.w400, color: CupertinoAppColors.textTertiary, letterSpacing: -0.08)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: CupertinoAppColors.textQuaternary, size: 16),
          ],
        ),
      ),
    );
  }
}
