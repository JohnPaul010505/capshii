import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/providers/auth_provider.dart';
import 'package:shared/services/supabase_client.dart';
import '../../../app/design_tokens.dart';

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
      backgroundColor: ClayTokens.clayDarkBase,
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
                        color: ClayTokens.clayDarkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ClayTokens.clayDarkBorder.withAlpha(128)),
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
                          color: ClayTokens.clayDarkSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ClayTokens.clayDarkBorder.withAlpha(128)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.qrcode_viewfinder,
                                size: 64,
                                color: ClayTokens.clayDarkTextTertiary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to open scanner',
                                style: ClayTokens.bodyMedium.copyWith(color: ClayTokens.clayDarkTextTertiary),
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
                              style: ClayTokens.bodyMedium.copyWith(color: ClayTokens.clayPrimary),
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
                          ? CupertinoActivityIndicator(color: ClayTokens.clayDarkTextPrimary, radius: 10)
                          : Text(
                              'Check In / Check Out',
                              style: ClayTokens.titleLarge.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: ClayTokens.clayDarkTextPrimary,
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
                              ? ClayTokens.clayAccent.withAlpha(26)
                              : ClayTokens.clayError.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.xmark_circle_fill,
                              color: _isSuccess
                                  ? ClayTokens.clayAccent
                                  : ClayTokens.clayError,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: ClayTokens.titleLarge.copyWith(
                                  fontSize: 15,
                                  color: _isSuccess
                                      ? ClayTokens.clayAccent
                                      : ClayTokens.clayError,
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
                    style: ClayTokens.bodySmall.copyWith(color: ClayTokens.clayDarkTextTertiary, fontSize: 13),
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
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: Icon(
              CupertinoIcons.back,
              color: ClayTokens.clayPrimary,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: ClayTokens.titleLarge.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: ClayTokens.clayDarkTextPrimary,
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
