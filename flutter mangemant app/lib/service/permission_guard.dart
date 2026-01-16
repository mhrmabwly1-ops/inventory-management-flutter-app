// permission_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';

class PermissionGuard extends StatelessWidget {
  final String permissionKey;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.permissionKey,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context, listen: false);

    if (settingsController.hasPermission(permissionKey)) {
      return child;
    }

    return fallback ?? const _UnauthorizedAccess();
  }
}

class _UnauthorizedAccess extends StatelessWidget {
  const _UnauthorizedAccess();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غير مصرح بالوصول'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'غير مصرح لك بالوصول إلى هذه الصفحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'يرجى التواصل مع مدير النظام لطلب الصلاحيات',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}