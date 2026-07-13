import 'package:flutter/cupertino.dart';
import '../../../app/cupertino_theme.dart';
import 'admin_sidebar.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoAppColors.background,
      child: AdminSidebar(child: child),
    );
  }
}
