import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';

final goalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final response = await SupabaseClientService()
      .client
      .from('goals')
      .select()
      .eq('member_id', userId)
      .order('created_at', ascending: false);
  return response as List<Map<String, dynamic>>;
});

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final userId = SupabaseClientService().client.auth.currentUser!.id;
    await SupabaseClientService().client.from('goals').insert({
      'member_id': userId,
      'title': _titleController.text.trim(),
      'target_value': double.tryParse(_targetController.text),
      'status': 'active',
    });
    _titleController.clear();
    _targetController.clear();
    ref.invalidate(goalsProvider);
    setState(() => _saving = false);
  }

  Future<void> _toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'completed' : 'active';
    await SupabaseClientService().client.from('goals').update({'status': newStatus}).eq('id', id);
    ref.invalidate(goalsProvider);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Goals'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: CupertinoAppColors.groupedBackground,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Goal',
                            style: sfText(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoAppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildField(_titleController, 'Goal Title *'),
                          const SizedBox(height: 8),
                          _buildField(_targetController, 'Target Value', TextInputType.number),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: CupertinoButton(
                              color: CupertinoAppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const CupertinoActivityIndicator(color: CupertinoAppColors.textPrimary)
                                  : Text(
                                      'Add Goal',
                                      style: sfText(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoAppColors.textPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'My Goals',
                      style: sfText(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CupertinoAppColors.textPrimary,
                        letterSpacing: -0.36,
                      ),
                    ),
                  ),
                  goalsAsync.when(
                    data: (goals) => Container(
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: goals.asMap().entries.map((entry) {
                          final g = entry.value;
                          final isLast = entry.key == goals.length - 1;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g['title'] ?? '',
                                            style: sfText(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              color: CupertinoAppColors.textPrimary,
                                              letterSpacing: -0.41,
                                            ),
                                          ),
                                          if (g['target_value'] != null)
                                            Text(
                                              'Target: ${g['target_value']}',
                                              style: sfText(
                                                fontSize: 15,
                                                color: CupertinoAppColors.textTertiary,
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(16),
                                    onPressed: () => _toggleStatus(g['id'], g['status']),
                                    child: Icon(
                                      g['status'] == 'completed'
                                          ? CupertinoIcons.checkmark_circle_fill
                                          : CupertinoIcons.circle,
                                      color: g['status'] == 'completed'
                                          ? CupertinoAppColors.green
                                          : CupertinoAppColors.primaryBlue,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLast)
                                const Divider(
                                  color: CupertinoAppColors.separator,
                                  height: 0.5,
                                  thickness: 0.5,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error: $e',
                        style: sfText(color: CupertinoAppColors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
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

  Widget _buildField(TextEditingController controller, String label, [TextInputType? keyboardType]) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoAppColors.cardElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: sfText(color: CupertinoAppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        keyboardType: keyboardType ?? TextInputType.text,
        cursorColor: CupertinoAppColors.primaryBlue,
        style: sfText(color: CupertinoAppColors.textPrimary),
      ),
    );
  }
}
