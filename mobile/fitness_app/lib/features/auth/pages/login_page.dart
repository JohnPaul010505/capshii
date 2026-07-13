import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/providers/auth_provider.dart';
import '../../../app/design_tokens.dart';
import '../../shared/widgets/clay/clay_card.dart';
import '../../shared/widgets/clay/clay_button.dart';
import '../../shared/widgets/clay/clay_input.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _selectedRole = 'member';
  String? _error;
  String? _prefixWarning;
  bool _loading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _errorCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _errorCtrl = AnimationController(
      vsync: this,
      duration: ClayTokens.normal,
    );

    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() { _prefixWarning = null; }));
    _passwordController.addListener(() => setState(() {}));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty) {
      setState(() => _error = 'Please enter your code');
      _errorCtrl.forward(from: 0);
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password');
      _errorCtrl.forward(from: 0);
      return;
    }

    final prefix = code.isNotEmpty ? code[0] : '';
    setState(() => _prefixWarning = null);
    if (_selectedRole == 'trainer' && prefix == 'M') {
      setState(() => _prefixWarning = 'This is a member account, trainer access only.');
      return;
    }
    if (_selectedRole == 'member' && prefix == 'T') {
      setState(() => _prefixWarning = 'This is a trainer account, member access only.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ref.read(authProvider.notifier).signInWithCode(
        _codeController.text.trim().toUpperCase(),
        _passwordController.text,
      );

      if (!mounted) return;
      final profile = ref.read(authProvider).valueOrNull;
      if (profile == null) return;

      if (profile.role != _selectedRole) {
        setState(() {
          _prefixWarning = profile.role == 'member'
            ? 'This account is a member, not a trainer'
            : 'This account is a trainer, not a member';
          _loading = false;
        });
        return;
      }

      context.go(
        profile.role == 'trainer' ? '/trainer/dashboard' : '/member/home',
      );
    } catch (e) {
      setState(() => _error = e.toString());
      _errorCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D0D1A), Color(0xFF000000)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoSection(),
                      const SizedBox(height: 36),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ClayTokens.clayPrimary.withAlpha(60),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLoginCard() {
    return ClayCard(
      variant: ClayCardVariant.elevated,
      padding: ClayCardPadding.large,
      borderRadius: BorderRadius.circular(ClayTokens.radiusCard),
      customShadows: [
        BoxShadow(
          color: ClayTokens.clayPrimary.withAlpha(30),
          blurRadius: 32,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(100),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FitTrack',
            style: ClayTokens.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: ClayTokens.clayDarkTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your fitness journey starts here',
            style: ClayTokens.bodySmall.copyWith(
              color: ClayTokens.clayDarkTextTertiary,
            ),
          ),
          const SizedBox(height: 24),
          _buildRoleToggle(),
          const SizedBox(height: 22),
          ClayInput(
            controller: _codeController,
            focusNode: _emailFocus,
            label: 'UID',
            hint: '',
            prefixIcon: const Icon(Icons.tag, size: 18),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 14),
          ClayInput(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: '',
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outlined, size: 18),
            suffixIcon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: ClayTokens.clayDarkTextTertiary,
            ),
            onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _errorCtrl,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClayTokens.clayError.withAlpha(20),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
                  border: Border.all(
                    color: ClayTokens.clayError.withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: ClayTokens.clayError, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: ClayTokens.bodySmall.copyWith(color: ClayTokens.clayError),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close, color: ClayTokens.clayError, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_prefixWarning != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ClayTokens.clayWarning.withAlpha(26),
                borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
                border: Border.all(color: ClayTokens.clayWarning.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ClayTokens.clayWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _prefixWarning!,
                      style: ClayTokens.labelMedium.copyWith(color: ClayTokens.clayWarning),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _prefixWarning = null),
                    child: Icon(Icons.close, color: ClayTokens.clayWarning, size: 16),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClayButton(
            label: 'Sign In',
            onPressed: _login,
            loading: _loading,
            fullWidth: true,
            size: ClayButtonSize.large,
          ),
          const SizedBox(height: 16),
          Text(
            'v1.0.0 \u00b7 Powered by FitTrack',
            style: ClayTokens.bodyMedium.copyWith(
              fontSize: 11,
              color: ClayTokens.clayDarkTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: ClayTokens.clayDarkCard,
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        border: Border.all(color: ClayTokens.clayDarkBorder.withAlpha(102)),
      ),
      child: Row(
        children: [
          _roleTab(
            label: 'MEMBER',
            icon: Icons.person,
            isSelected: _selectedRole == 'member',
            onTap: () => setState(() { _selectedRole = 'member'; _prefixWarning = null; }),
          ),
          _roleTab(
            label: 'TRAINER',
            icon: Icons.person,
            isSelected: _selectedRole == 'trainer',
            onTap: () => setState(() { _selectedRole = 'trainer'; _prefixWarning = null; }),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _loading ? null : onTap,
        child: AnimatedContainer(
          duration: ClayTokens.normal,
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [ClayTokens.clayPrimary, ClayTokens.clayPrimary])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ClayTokens.clayPrimary.withAlpha(60),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? ClayTokens.clayDarkTextPrimary : ClayTokens.clayDarkTextTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: ClayTokens.bodyMedium.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? ClayTokens.clayDarkTextPrimary : ClayTokens.clayDarkTextTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
