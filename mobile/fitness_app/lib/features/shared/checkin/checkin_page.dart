import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/providers/auth_provider.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../app/cupertino_theme.dart';

class CheckinPage extends ConsumerStatefulWidget {
  const CheckinPage({super.key});

  @override
  ConsumerState<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends ConsumerState<CheckinPage> {
  bool _processing = false;
  bool _showScanner = false;
  String? _statusMessage;
  bool _isSuccess = false;

  Future<void> _toggleAttendance() async {
    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) {
      setState(() {
        _statusMessage = 'Not logged in';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _processing = true;
      _statusMessage = null;
    });

    try {
      final client = SupabaseClientService().client;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final rows = await client
          .from('attendance')
          .select('id')
          .eq('member_id', profile.id)
          .eq('check_in_date', today);

      final count = (rows as List).length;
      final isCheckin = count % 2 == 0;
      final now = DateTime.now().toUtc().toIso8601String();

      await client.from('attendance').insert({
        'member_id': profile.id,
        'check_in_time': now,
        'check_in_date': today,
      });

      setState(() {
        _statusMessage = isCheckin ? 'Checked in!' : 'Checked out!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == 'FITGYM:ATTENDANCE') {
      _toggleAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Check In / Check Out'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  if (_showScanner)
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: CupertinoAppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CupertinoAppColors.separator.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          onDetect: _onDetect,
                          controller: MobileScannerController(
                            detectionSpeed: DetectionSpeed.normal,
                          ),
                        ),
                      ),
                    ),
                  if (!_showScanner)
                    GestureDetector(
                      onTap: () => setState(() => _showScanner = true),
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: CupertinoAppColors.groupedBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CupertinoAppColors.separator.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.qrcode_viewfinder,
                                size: 64,
                                color: CupertinoAppColors.textTertiary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to open scanner',
                                style: sfText(color: CupertinoAppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_showScanner)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            onPressed: () => setState(() => _showScanner = false),
                            child: Text(
                              'Close Scanner',
                              style: sfText(color: CupertinoAppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: CupertinoButton.filled(
                      onPressed: _processing ? null : _toggleAttendance,
                      borderRadius: BorderRadius.circular(12),
                      child: _processing
                          ? const CupertinoActivityIndicator(color: CupertinoAppColors.textPrimary, radius: 10)
                          : Text(
                              'Check In / Check Out',
                              style: sfText(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: CupertinoAppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? CupertinoAppColors.green.withOpacity(0.1)
                              : CupertinoAppColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.xmark_circle_fill,
                              color: _isSuccess
                                  ? CupertinoAppColors.green
                                  : CupertinoAppColors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: sfText(
                                  fontSize: 15,
                                  color: _isSuccess
                                      ? CupertinoAppColors.green
                                      : CupertinoAppColors.red,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan the gym QR code or tap the button above to check in or out.',
                    style: sfText(color: CupertinoAppColors.textTertiary, fontSize: 13),
                    textAlign: TextAlign.center,
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
