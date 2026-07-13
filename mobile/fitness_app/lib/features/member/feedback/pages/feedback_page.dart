import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';

final feedbackListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final response = await SupabaseClientService()
      .client
      .from('trainer_feedback')
      .select()
      .eq('member_id', userId)
      .order('created_at', ascending: false);
  return response as List<Map<String, dynamic>>;
});

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final _contentController = TextEditingController();
  bool _saving = false;

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final userId = SupabaseClientService().client.auth.currentUser!.id;
    await SupabaseClientService().client.from('trainer_feedback').insert({
      'member_id': userId,
      'content': _contentController.text.trim(),
    });
    _contentController.clear();
    ref.invalidate(feedbackListProvider);
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Feedback'),
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
                            'Submit Feedback',
                            style: sfText(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoAppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoAppColors.cardElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                labelText: 'Your feedback...',
                                labelStyle: sfText(color: CupertinoAppColors.textTertiary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              maxLines: 4,
                              cursorColor: CupertinoAppColors.primaryBlue,
                              style: sfText(color: CupertinoAppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: CupertinoButton(
                              color: CupertinoAppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _saving ? null : _submit,
                              child: _saving
                                  ? const CupertinoActivityIndicator(color: CupertinoAppColors.textPrimary)
                                  : Text(
                                      'Submit',
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
                      'History',
                      style: sfText(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CupertinoAppColors.textPrimary,
                        letterSpacing: -0.36,
                      ),
                    ),
                  ),
                  feedbackAsync.when(
                    data: (feedback) => Container(
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: feedback.asMap().entries.map((entry) {
                          final f = entry.value;
                          final isLast = entry.key == feedback.length - 1;
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
                                            f['content'] ?? '',
                                            style: sfText(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              color: CupertinoAppColors.textPrimary,
                                              letterSpacing: -0.41,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            f['created_at']?.toString().substring(0, 10) ?? '',
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
}
