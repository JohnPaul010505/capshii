import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/cupertino_theme.dart';

const _collapsedWidth = 60.0;
const _expandedWidth = 220.0;
const _duration = Duration(milliseconds: 250);

final _adminRoutes = [
  ('/admin/dashboard', CupertinoIcons.square_list, 'Dashboard'),
  ('/admin/members', CupertinoIcons.person_2, 'Members'),
  ('/admin/trainers', CupertinoIcons.graph_square_fill, 'Trainers'),
  ('/admin/settings', CupertinoIcons.settings, 'Settings'),
];

class AdminSidebar extends StatefulWidget {
  final Widget child;

  const AdminSidebar({super.key, required this.child});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Row(
      children: [
        AnimatedContainer(
          duration: _duration,
          curve: Curves.easeInOut,
          width: _expanded ? _expandedWidth : _collapsedWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: CupertinoAppColors.groupedBackground,
            border: Border(
              right: BorderSide(color: CupertinoAppColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: _duration,
                curve: Curves.easeInOut,
                height: 64,
                padding: EdgeInsets.symmetric(
                  horizontal: _expanded ? 16 : 0,
                ),
                alignment: _expanded ? Alignment.centerLeft : Alignment.center,
                child: _expanded
                    ? Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset('assets/logo.png', width: 28, height: 28, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Admin',
                            style: sfText(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoAppColors.textPrimary, letterSpacing: -0.41),
                          ),
                        ],
                      )
                    : Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/logo.png', width: 28, height: 28, fit: BoxFit.cover),
                        ),
                      ),
              ),
              Container(
                height: 0.5,
                margin: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 8),
                color: CupertinoAppColors.separator,
              ),
              const SizedBox(height: 8),
              ..._adminRoutes.map((route) {
                final active = location.startsWith(route.$1);
                return _SidebarItem(
                  icon: route.$2,
                  label: route.$3,
                  active: active,
                  expanded: _expanded,
                  onTap: () => context.go(route.$1),
                );
              }),
              const Spacer(),
              Container(
                height: 0.5,
                margin: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 8),
                color: CupertinoAppColors.separator,
              ),
              Consumer(
                builder: (_, ref, __) => GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).signOut(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: _expanded ? 14 : 10, horizontal: _expanded ? 12 : 0),
                    child: _expanded
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_left_square, color: CupertinoAppColors.red.withAlpha(200), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: sfText(fontSize: 17, fontWeight: FontWeight.w400, color: CupertinoAppColors.red.withAlpha(200), letterSpacing: -0.41),
                              ),
                            ],
                          )
                        : Icon(CupertinoIcons.arrow_left_square, color: CupertinoAppColors.red.withAlpha(180), size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: expanded ? 12 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active
              ? CupertinoAppColors.primaryBlue.withAlpha(25)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(width: active ? 0 : 13),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: active
                    ? CupertinoAppColors.primaryBlue.withAlpha(25)
                    : Colors.transparent,
              ),
              child: Icon(
                icon,
                color: active ? CupertinoAppColors.primaryBlue : CupertinoAppColors.textTertiary,
                size: 20,
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: sfText(
                    fontSize: 17,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? CupertinoAppColors.primaryBlue : CupertinoAppColors.textPrimary,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: CupertinoAppColors.textQuaternary, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
