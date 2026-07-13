import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../../app/cupertino_theme.dart';

final measurementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseClientService().client.auth.currentUser!.id;
  final response = await SupabaseClientService()
      .client
      .from('body_measurements')
      .select()
      .eq('member_id', userId)
      .order('measured_at', ascending: false);
  return response as List<Map<String, dynamic>>;
});

class MeasurementsPage extends ConsumerStatefulWidget {
  const MeasurementsPage({super.key});

  @override
  ConsumerState<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends ConsumerState<MeasurementsPage> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final userId = SupabaseClientService().client.auth.currentUser!.id;
    await SupabaseClientService().client.from('body_measurements').insert({
      'member_id': userId,
      'weight_kg': double.tryParse(_weightController.text),
      'body_fat_pct': double.tryParse(_bodyFatController.text),
      'chest_cm': double.tryParse(_chestController.text),
      'waist_cm': double.tryParse(_waistController.text),
      'hips_cm': double.tryParse(_hipsController.text),
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      'measured_at': DateTime.now().toIso8601String(),
    });
    _weightController.clear();
    _bodyFatController.clear();
    _chestController.clear();
    _waistController.clear();
    _hipsController.clear();
    _notesController.clear();
    ref.invalidate(measurementsProvider);
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(measurementsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Measurements'),
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
                            'Record New',
                            style: sfText(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoAppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildField(_weightController, 'Weight (kg)', TextInputType.number),
                          const SizedBox(height: 8),
                          _buildField(_bodyFatController, 'Body Fat %', TextInputType.number),
                          const SizedBox(height: 8),
                          _buildField(_chestController, 'Chest (cm)', TextInputType.number),
                          const SizedBox(height: 8),
                          _buildField(_waistController, 'Waist (cm)', TextInputType.number),
                          const SizedBox(height: 8),
                          _buildField(_hipsController, 'Hips (cm)', TextInputType.number),
                          const SizedBox(height: 8),
                          _buildField(_notesController, 'Notes', TextInputType.text, maxLines: 2),
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
                                      'Save',
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
                  measurementsAsync.when(
                    data: (measurements) => Container(
                      decoration: const BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Column(
                        children: measurements.asMap().entries.map((entry) {
                          final m = entry.value;
                          final isLast = entry.key == measurements.length - 1;
                          return Column(
                            children: [
                              _measurementRow(
                                title: m['measured_at']?.toString().substring(0, 10) ?? '',
                                subtitle: [
                                  if (m['weight_kg'] != null) '${m['weight_kg']} kg',
                                  if (m['body_fat_pct'] != null) 'BF: ${m['body_fat_pct']}%',
                                  if (m['waist_cm'] != null) 'Waist: ${m['waist_cm']} cm',
                                ].join(', '),
                                onDelete: () async {
                                  await SupabaseClientService().client
                                      .from('body_measurements')
                                      .delete()
                                      .eq('id', m['id']);
                                  ref.invalidate(measurementsProvider);
                                },
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

  Widget _measurementRow({
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
  }) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: sfText(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: CupertinoAppColors.textPrimary,
                    letterSpacing: -0.41,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          onPressed: onDelete,
          child: Icon(CupertinoIcons.trash, color: CupertinoAppColors.red, size: 20),
        ),
      ],
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

  Widget _buildField(TextEditingController controller, String label, TextInputType keyboardType, {int maxLines = 1}) {
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
        keyboardType: keyboardType,
        maxLines: maxLines,
        cursorColor: CupertinoAppColors.primaryBlue,
        style: sfText(color: CupertinoAppColors.textPrimary),
      ),
    );
  }
}
