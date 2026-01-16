class SettingsConstants {
  // Setting categories
  static const List<String> categories = [
    'general',
    'invoice',
    'product',
    'user',
    'system',
    'backup',
    'tax',
    'currency',
  ];

  // Setting types
  static const List<String> types = [
    'string',
    'int',
    'double',
    'bool',
    'json',
  ];

  // Setting groups
  static const Map<String, List<String>> groups = {
    'general': ['company', 'display', 'behavior'],
    'invoice': ['format', 'tax', 'payment', 'printing'],
    'product': ['general', 'inventory', 'pricing'],
    'user': ['security', 'permissions', 'logging'],
    'system': ['backup', 'logging', 'performance', 'maintenance'],
    'currency': ['format', 'rounding'],
    'tax': ['calculation', 'rates'],
  };

  // Default values for critical settings
  static const Map<String, dynamic> defaults = {
    // General
    'app_name': 'نظام إدارة المخزون',
    'company_name': 'شركتك',

    // Invoice
    'invoice_prefix': 'INV',
    'invoice_start_number': '1001',
    'invoice_tax_percentage': '15',
    'invoice_default_due_days': '30',

    // Currency
    'currency_code': 'SAR',
    'currency_symbol': '﷼',
    'currency_position': 'right',
    'thousands_separator': ',',
    'decimal_separator': '.',
    'decimal_digits': '2',

    // Tax
    'tax_enabled': '1',
    'tax_type': 'percentage',
    'tax_percentage': '15',

    // Product
    'default_product_unit': 'قطعة',
    'low_stock_threshold': '10',
    'profit_margin_percentage': '20',

    // User
    'session_timeout_minutes': '30',
    'password_min_length': '6',

    // System
    'backup_auto_days': '7',
    'enable_audit_log': '1',
  };

  // Settings that require app restart
  static const List<String> requiresRestart = [
    'language',
    'theme_mode',
    'currency_code',
    'thousands_separator',
    'decimal_separator',
  ];

  // Sensitive settings (only admin can change)
  static const List<String> sensitiveSettings = [
    'backup_location',
    'database_encryption_key',
    'max_login_attempts',
    'session_timeout_minutes',
    'tax_percentage',
    'profit_margin_percentage',
  ];

  // Settings with validation rules
  static const Map<String, Map<String, dynamic>> validationRules = {
    'invoice_start_number': {
      'min': 1,
      'max': 999999,
      'pattern': r'^\d+$',
    },
    'tax_percentage': {
      'min': 0,
      'max': 100,
      'pattern': r'^\d+(\.\d{1,2})?$',
    },
    'low_stock_threshold': {
      'min': 0,
      'max': 10000,
      'pattern': r'^\d+$',
    },
    'password_min_length': {
      'min': 4,
      'max': 32,
      'pattern': r'^\d+$',
    },
    'decimal_digits': {
      'min': 0,
      'max': 4,
      'pattern': r'^\d+$',
    },
  };

  // Settings with dependencies
  static const Map<String, List<String>> dependencies = {
    'tax_percentage': ['tax_enabled'],
    'currency_position': ['currency_symbol'],
    'invoice_auto_print': ['printer_configured'],
  };

  // Settings that affect multiple modules
  static const Map<String, List<String>> affectedModules = {
    'currency_code': ['invoices', 'products', 'reports', 'dashboard'],
    'tax_percentage': ['invoices', 'purchases', 'reports', 'products'],
    'low_stock_threshold': ['products', 'alerts', 'dashboard'],
    'invoice_prefix': ['invoices', 'reports', 'printing'],
  };
}