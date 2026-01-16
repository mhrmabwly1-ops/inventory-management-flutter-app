// screens/settings_screen_new.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled43/service/return_policies_screen.dart';
import 'package:untitled43/color.dart';

import '../database_helper.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../mod/settings_service.dart';
import '../widgets/theme_manager.dart';
import 'password_policy.dart';
import 'users_management.dart';
import 'invoice_numbering_screen.dart';
 // إضافة استيراد AppLocalizations

// Root solution: Create Provider in the same file
class SettingsScreenWithProvider extends StatelessWidget {
  const SettingsScreenWithProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsService(DatabaseHelper()),
      child: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _confirmDeleteController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _confirmDeleteController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final service = Provider.of<SettingsService>(context, listen: false);
              service.reload();
            },
            tooltip: localizations.translate('refresh'),
          ),
        ],
      ),
      body: Consumer<SettingsService>(
        builder: (context, service, child) {
          // Load settings if not already loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!service.isInitialized && !service.isLoading) {
              service.initialize();
            }
          });

          if (service.isLoading && !service.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    service.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: service.initialize,
                    child: Text(localizations.translate('retry')),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('general_settings'), Icons.settings),
                _buildGeneralSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('products_inventory'), Icons.inventory),
                _buildProductInventorySettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('sales_invoices'), Icons.receipt),
                _buildSalesInvoiceSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('purchases_suppliers'), Icons.shopping_cart),
                _buildPurchaseSupplierSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('reports_analytics'), Icons.analytics),
                _buildReportsAnalyticsSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('security_users'), Icons.security),
                _buildSecurityUserSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('customization_appearance'), Icons.palette),
                _buildCustomizationSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('maintenance_management'), Icons.build),
                _buildMaintenanceSettings(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('backup_restore'), Icons.backup),
                _buildBackupRestoreSection(service, localizations),
                const SizedBox(height: 20),

                _buildSectionHeader(localizations.translate('danger_zone'), Icons.dangerous),
                _buildDangerZone(service, localizations),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.translate('search_in_settings'),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildGeneralSettings(SettingsService service, AppLocalizations localizations) {
    final companyName = service.getString('company_name', defaultValue: localizations.translate('inventory_management_company'));
    final currency = service.getString('default_currency', defaultValue: localizations.translate('riyal'));
    final taxRate = service.getDouble('default_tax_rate', defaultValue: 15.0);
    final notifications = service.getBool('enable_notifications', defaultValue: true);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('company_name'),
              value: companyName,
              icon: Icons.business,
              onTap: () => _showEditDialog(service, 'company_name', localizations.translate('company_name'),
                  defaultValue: localizations.translate('inventory_management_company')),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('default_currency'),
              value: currency,
              icon: Icons.monetization_on,
              onTap: () => _showCurrencyDialog(service, localizations),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('default_tax_rate'),
              value: '$taxRate%',
              icon: Icons.percent,
              onTap: () => _showTaxDialog(service, localizations),
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('notifications_alerts')),
              subtitle: Text(localizations.translate('show_low_inventory_alerts')),
              secondary: Icon(Icons.notifications_active, color: AppColors.primary),
              value: notifications,
              onChanged: (value) => _updateSetting(service, 'enable_notifications', value, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInventorySettings(SettingsService service, AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('measurement_units'),
              value: localizations.translate('manage_measurement_units'),
              icon: Icons.straighten,
              onTap: () => _showUnitsDialog(localizations),
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('track_serial_numbers')),
              subtitle: Text(localizations.translate('enable_tracking_of_product_serial_numbers')),
              secondary: Icon(Icons.confirmation_number, color: AppColors.primary),
              value: service.getBool('track_serial_numbers', defaultValue: false),
              onChanged: (value) => _updateSetting(service, 'track_serial_numbers', value, localizations),
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('track_expiry_dates')),
              subtitle: Text(localizations.translate('enable_tracking_of_expiry_dates')),
              secondary: Icon(Icons.calendar_today, color: AppColors.primary),
              value: service.getBool('track_expiry_dates', defaultValue: false),
              onChanged: (value) => _updateSetting(service, 'track_expiry_dates', value, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _updateSetting(SettingsService service, String key, dynamic value, AppLocalizations localizations) async {
    final result = await service.setSetting(key, value);
    if (!result.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? localizations.translate('unknown_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(
      SettingsService service,
      String key,
      String title, {
        String? defaultValue,
      }) async {
    final currentValue = service.getString(key, defaultValue: defaultValue ?? '');
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text('${localizations.translate('edit')} $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              border: const OutlineInputBorder(),
              hintText: '${localizations.translate('enter')} $title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _updateSetting(service, key, controller.text.trim(), localizations);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(localizations.translate('save')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesInvoiceSettings(SettingsService service, AppLocalizations localizations) {
    final autoPrint = service.getBool('auto_print_invoice', defaultValue: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('invoice_numbering'),
              value: localizations.translate('configure_invoice_numbering_pattern'),
              icon: Icons.format_list_numbered,
              onTap: _showInvoiceNumberingDialog,
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('return_policies'),
              value: localizations.translate('define_return_terms_and_duration'),
              icon: Icons.assignment_return,
              onTap: _showReturnPoliciesDialog,
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('auto_print')),
              subtitle: Text(localizations.translate('print_invoice_automatically_after_creation')),
              secondary: Icon(Icons.print, color: AppColors.primary),
              value: autoPrint,
              onChanged: (value) => _updateSetting(service, 'auto_print_invoice', value, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseSupplierSettings(SettingsService service, AppLocalizations localizations) {
    final autoPurchase = service.getBool('auto_purchase_orders', defaultValue: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(localizations.translate('auto_purchase_orders')),
              subtitle: Text(localizations.translate('create_purchase_orders_when_inventory_reaches_minimum_level')),
              secondary: Icon(Icons.shopping_basket, color: AppColors.primary),
              value: autoPurchase,
              onChanged: (value) => _updateSetting(service, 'auto_purchase_orders', value, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsAnalyticsSettings(SettingsService service, AppLocalizations localizations) {
    final emailReports = service.getBool('email_reports', defaultValue: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('scheduled_reports'),
              value: localizations.translate('schedule_report_sending'),
              icon: Icons.schedule_send,
              onTap: () => _showComingSoonDialog(localizations.translate('scheduled_reports'), localizations),
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('email_reports')),
              subtitle: Text(localizations.translate('enable_sending_reports_via_email')),
              secondary: Icon(Icons.email, color: AppColors.primary),
              value: emailReports,
              onChanged: (value) => _updateSetting(service, 'email_reports', value, localizations),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('export_formats'),
              value: localizations.translate('select_default_export_formats'),
              icon: Icons.file_download,
              onTap: () => _showComingSoonDialog(localizations.translate('export_formats'), localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityUserSettings(SettingsService service, AppLocalizations localizations) {
    final twoFactorAuth = service.getBool('two_factor_auth', defaultValue: false);
    final ipRestriction = service.getBool('ip_restriction', defaultValue: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('users_management'),
              value: localizations.translate('add_edit_and_delete_users'),
              icon: Icons.people,
              onTap: _showUsersManagement,
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('password_policies'),
              value: localizations.translate('configure_password_requirements'),
              icon: Icons.lock,
              onTap: _showPasswordPolicyDialog,
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('two_factor_authentication')),
              subtitle: Text(localizations.translate('enable_two_factor_authentication_for_users')),
              secondary: Icon(Icons.verified_user, color: AppColors.primary),
              value: twoFactorAuth,
              onChanged: (value) => _updateSetting(service, 'two_factor_auth', value, localizations),
            ),
            const Divider(height: 20),
            SwitchListTile(
              title: Text(localizations.translate('ip_restriction')),
              subtitle: Text(localizations.translate('restrict_access_to_specific_ip_addresses')),
              secondary: Icon(Icons.network_check, color: AppColors.primary),
              value: ipRestriction,
              onChanged: (value) => _updateSetting(service, 'ip_restriction', value, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationSettings(SettingsService service, AppLocalizations localizations) {
    final appLanguage = service.getString('app_language', defaultValue: localizations.translate('arabic'));
    final appTheme = service.getString('app_theme', defaultValue: localizations.translate('light'));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('app_language'),
              value: appLanguage,
              icon: Icons.language,
              onTap: () => _showLanguageDialog(service, localizations),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('interface_theme'),
              value: appTheme,
              icon: Icons.palette,
              onTap: () => _showThemeDialog(service, localizations),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('date_format'),
              value: localizations.translate('define_date_and_time_format'),
              icon: Icons.date_range,
              onTap: () => _showComingSoonDialog(localizations.translate('date_format'), localizations),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('currency_format'),
              value: localizations.translate('define_number_and_currency_format'),
              icon: Icons.attach_money,
              onTap: () => _showComingSoonDialog(localizations.translate('currency_format'), localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSettings(SettingsService service, AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              title: localizations.translate('database_integrity_check'),
              value: localizations.translate('check_for_errors_and_issues'),
              icon: Icons.health_and_safety,
              onTap: _checkDatabaseIntegrity,
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('database_compression'),
              value: localizations.translate('improve_performance_and_reduce_space'),
              icon: Icons.compress,
              onTap: _compressDatabase,
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('rebuild_indexes'),
              value: localizations.translate('improve_search_and_query_speed'),
              icon: Icons.build,
              onTap: _rebuildIndexes,
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: localizations.translate('database_statistics'),
              value: localizations.translate('view_data_information_and_size'),
              icon: Icons.storage,
              onTap: _showDatabaseStats,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(localizations.translate('feature_under_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(SettingsService service, AppLocalizations localizations) async {
    final List<String> languages = [localizations.translate('arabic'), 'English', 'Français', 'Español'];
    String selectedLang = service.getString('app_language', defaultValue: localizations.translate('arabic'));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(localizations.translate('choose_app_language')),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return RadioListTile<String>(
                    title: Text(lang),
                    value: lang,
                    groupValue: selectedLang,
                    onChanged: (value) {
                      setState(() {
                        selectedLang = value!;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateSetting(service, 'app_language', selectedLang, localizations);
                  if (mounted) Navigator.pop(context);
                },
                child: Text(localizations.translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  ThemeMode _mapStringToThemeMode(String value, AppLocalizations localizations) {
    if (value == localizations.translate('dark')) {
      return ThemeMode.dark;
    } else if (value == localizations.translate('light')) {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  Future<void> _showThemeDialog(SettingsService service, AppLocalizations localizations) async {
    final List<String> themes = [
      localizations.translate('light'),
      localizations.translate('dark'),
      localizations.translate('system')
    ];
    String selectedTheme = service.getString('app_theme', defaultValue: localizations.translate('system'));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(localizations.translate('choose_interface_theme')),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: themes.length,
                      itemBuilder: (context, index) {
                        final theme = themes[index];
                        return RadioListTile<String>(
                          title: Text(theme),
                          value: theme,
                          groupValue: selectedTheme,
                          onChanged: (value) {
                            setState(() {
                              selectedTheme = value!;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('theme_preview'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localizations.translate('interactive_element'),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateSetting(service, 'app_theme', selectedTheme, localizations);
                  if (mounted) {
                    themeNotifier.value = _mapStringToThemeMode(selectedTheme, localizations);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${localizations.translate('theme_changed_to')} $selectedTheme',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(localizations.translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkDatabaseIntegrity() async {
    final dbHelper = DatabaseHelper();
    final localizations = AppLocalizations.of(context);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('checking_database_integrity'))),
        );
      }

      final result = await dbHelper.checkDatabaseIntegrity();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result['success']
                ? '✅ ${localizations.translate('integrity_check')}'
                : '❌ ${localizations.translate('check_error')}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.translate('check_result'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(result['message'].toString()),
                    if (result['success'] && result['data_integrity'] is List)
                      ...[
                        const SizedBox(height: 20),
                        Text(localizations.translate('detected_issues'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ...(result['data_integrity'] as List).map<Widget>((issue) {
                          return ListTile(
                            title: Text(issue['table_name'].toString()),
                            subtitle: Text('${localizations.translate('orphaned_records')}: ${issue['orphaned_records']}'),
                          );
                        }).toList(),
                      ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${localizations.translate('database_integrity_check_error')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _compressDatabase() async {
    final dbHelper = DatabaseHelper();
    final localizations = AppLocalizations.of(context);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('compressing_database'))),
        );
      }

      await dbHelper.compressDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${localizations.translate('database_compressed_successfully')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${localizations.translate('database_compression_error')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rebuildIndexes() async {
    final dbHelper = DatabaseHelper();
    final localizations = AppLocalizations.of(context);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('rebuilding_database_indexes'))),
        );
      }

      await dbHelper.rebuildDatabaseIndexes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${localizations.translate('indexes_rebuilt_successfully')}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${localizations.translate('index_rebuild_error')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showDatabaseStats() async {
    final dbHelper = DatabaseHelper();
    final localizations = AppLocalizations.of(context);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('gathering_database_statistics'))),
        );
      }

      final stats = await dbHelper.getDatabaseStats();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.translate('database_statistics')),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stats['success'] as bool)
                      ...[
                        _buildStatCard(localizations.translate('total_records'), '${stats['total_records']} ${localizations.translate('records')}'),
                        _buildStatCard(localizations.translate('total_tables'), '${stats['total_tables']} ${localizations.translate('tables')}'),
                        _buildStatCard(localizations.translate('database_size'), '${stats['database_size_mb']} MB'),
                        const SizedBox(height: 20),
                        Text(localizations.translate('table_details'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ...(stats['table_stats'] as List<dynamic>).map<Widget>((table) {
                          return ListTile(
                            title: Text(table['table_name'].toString()),
                            trailing: Text('${table['row_count']} ${localizations.translate('records')}'),
                          );
                        }).toList(),
                      ]
                    else
                      Text('❌ ${stats['error']}'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${localizations.translate('error_fetching_statistics')}: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _showCurrencyDialog(SettingsService service, AppLocalizations localizations) async {
    final List<String> currencies = [
      localizations.translate('riyal'),
      localizations.translate('dirham'),
      localizations.translate('dinar'),
      localizations.translate('dollar'),
      localizations.translate('euro'),
      localizations.translate('pound')
    ];
    String selectedCurrency = service.getString('default_currency', defaultValue: localizations.translate('riyal'));

    await showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text(localizations.translate('choose_default_currency')),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return RadioListTile<String>(
                    title: Text(currency),
                    value: currency,
                    groupValue: selectedCurrency,
                    onChanged: (value) {
                      setState(() {
                        selectedCurrency = value!;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateSetting(service, 'default_currency', selectedCurrency, localizations);
                  if (mounted) Navigator.pop(context);
                },
                child: Text(localizations.translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTaxDialog(SettingsService service, AppLocalizations localizations) async {
    final currentTax = service.getDouble('default_tax_rate', defaultValue: 15.0);
    final controller = TextEditingController(text: currentTax.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('edit_default_tax_rate')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: localizations.translate('tax_rate_percent'),
                border: const OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${localizations.translate('current_value')}: $currentTax%',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final taxRate = double.tryParse(controller.text) ?? 0.0;
              if (taxRate >= 0 && taxRate <= 100) {
                await _updateSetting(service, 'default_tax_rate', taxRate, localizations);
                if (mounted) Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.translate('tax_rate_must_be_between_0_and_100'))),
                );
              }
            },
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestoreSection(SettingsService service, AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.backup, color: AppColors.primary),
              title: Text(localizations.translate('create_backup')),
              subtitle: Text(localizations.translate('save_all_data_to_a_file')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _createBackupNow,
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.restore, color: AppColors.primary),
              title: Text(localizations.translate('restore_backup')),
              subtitle: Text(localizations.translate('restore_data_from_a_saved_file')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _restoreBackup,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(SettingsService service, AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.red, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(localizations.translate('reset_all_settings')),
              subtitle: Text(localizations.translate('revert_to_default_settings')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoonDialog(localizations.translate('reset'), localizations),
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text(localizations.translate('delete_all_data')),
              subtitle: Text(localizations.translate('delete_all_data_and_start_fresh')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoonDialog(localizations.translate('delete_data'), localizations),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnitsDialog(AppLocalizations localizations) async {
    final dbHelper = DatabaseHelper();
    try {
      final units = await dbHelper.getUnits();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnitsManagementScreen(localizations: localizations),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_loading_measurement_units')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createBackupNow() async {
    final dbHelper = DatabaseHelper();
    final localizations = AppLocalizations.of(context);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('creating_backup'))),
        );
      }

      final backupPath = await dbHelper.createBackup();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ ${localizations.translate('backup_created')}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.translate('backup_saved_successfully_at')),
                const SizedBox(height: 10),
                SelectableText(
                  backupPath,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Text('${localizations.translate('backup_date')}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('ok')),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: Text(localizations.translate('share')),
                onPressed: () async {
                  final file = File(backupPath);
                  if (await file.exists()) {
                    await Share.shareXFiles([XFile(backupPath)], text: localizations.translate('database_backup'));
                  }
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${localizations.translate('backup_creation_error')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final localizations = AppLocalizations.of(context);

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.translate('restore_backup')),
          content: Text(localizations.translate('restore_backup_feature')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('ok')),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showResetAllSettingsConfirmation(SettingsService service, AppLocalizations localizations) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text(localizations.translate('reset_all_settings')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.translate('are_you_sure_you_want_to_reset_all_settings')),
            SizedBox(height: 10),
            Text(
              localizations.translate('this_action_cannot_be_undone'),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await service.resetAllSettings();
              if (mounted) {
                Navigator.pop(context);
                if (result['success'] as bool) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ ${localizations.translate('all_settings_reset_successfully')}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ ${result['error']}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.translate('confirm')),
          ),
        ],
      ),
    );
  }

  void _showInvoiceNumberingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceNumberingScreen(),
      ),
    );
  }

  void _showReturnPoliciesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnPoliciesScreen(),
      ),
    );
  }

  void _showUsersManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersManagementScreen()),
    );
  }

  void _showPasswordPolicyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PasswordPolicyScreen()),
    );
  }
}

// Measurement Units Management Screen
class UnitsManagementScreen extends StatefulWidget {
  final AppLocalizations localizations;

  const UnitsManagementScreen({super.key, required this.localizations});

  @override
  State<UnitsManagementScreen> createState() => _UnitsManagementScreenState();
}

class _UnitsManagementScreenState extends State<UnitsManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final units = await _dbHelper.getUnits();
      setState(() => _units = units);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.translate('error_loading_units')}: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.localizations.translate('measurement_units_management')),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
          ? Center(child: Text(widget.localizations.translate('no_measurement_units')))
          : ListView.builder(
        itemCount: _units.length,
        itemBuilder: (context, index) {
          final unit = _units[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(unit['name'].toString()),
              subtitle: Text(unit['abbreviation']?.toString() ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditUnitDialog(unit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteUnitConfirmation(unit),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUnitDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddUnitDialog() async {
    final nameController = TextEditingController();
    final abbreviationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.translate('add_new_measurement_unit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: widget.localizations.translate('unit_name'),
                border: const OutlineInputBorder(),
                hintText: widget.localizations.translate('example_kilogram'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: abbreviationController,
              decoration: InputDecoration(
                labelText: widget.localizations.translate('abbreviation_optional'),
                border: const OutlineInputBorder(),
                hintText: widget.localizations.translate('example_kg'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await _dbHelper.insertUnit({
                    'name': nameController.text.trim(),
                    'abbreviation': abbreviationController.text.trim().isNotEmpty
                        ? abbreviationController.text.trim()
                        : null,
                  });

                  await _loadUnits();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ ${widget.localizations.translate('unit_added_successfully')}')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ ${widget.localizations.translate('error_adding_unit')}: $e')),
                    );
                  }
                }
              }
            },
            child: Text(widget.localizations.translate('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUnitDialog(Map<String, dynamic> unit) async {
    final nameController = TextEditingController(text: unit['name'].toString());
    final abbreviationController = TextEditingController(
      text: unit['abbreviation']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.translate('edit_measurement_unit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: widget.localizations.translate('unit_name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: abbreviationController,
              decoration: InputDecoration(
                labelText: widget.localizations.translate('abbreviation'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await _dbHelper.updateUnit(unit['id'] as int, {
                    'name': nameController.text.trim(),
                    'abbreviation': abbreviationController.text.trim(),
                  });

                  await _loadUnits();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ ${widget.localizations.translate('unit_updated_successfully')}')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ ${widget.localizations.translate('error_updating_unit')}: $e')),
                    );
                  }
                }
              }
            },
            child: Text(widget.localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteUnitConfirmation(Map<String, dynamic> unit) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.translate('confirm_delete')),
        content: Text('${widget.localizations.translate('are_you_sure_you_want_to_delete_unit')} "${unit['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteUnit(unit['id'] as int);
                await _loadUnits();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ ${widget.localizations.translate('unit_deleted_successfully')}')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ ${widget.localizations.translate('error_deleting_unit')}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.localizations.translate('delete')),
          ),
        ],
      ),
    );
  }
}