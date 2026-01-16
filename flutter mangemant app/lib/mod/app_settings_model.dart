// models/app_settings_model.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class AppSettingsModel {
  final int id;
  final String settingKey;
  final String settingValue;
  final String settingType;
  final String category;
  final String? groupName;
  final int displayOrder;
  final bool isEncrypted;
  final String? description;
  final List<String>? options;
  final String? minValue;
  final String? maxValue;
  final String defaultValue;
  final bool isReadonly;
  final bool requiresRestart;
  final String? validationRegex;
  final String? dependsOn;
  final String? visibleCondition;
  final String? tooltip;
  final String createdAt;
  final String updatedAt;

  const AppSettingsModel({
    required this.id,
    required this.settingKey,
    required this.settingValue,
    required this.settingType,
    required this.category,
    this.groupName,
    this.displayOrder = 0,
    this.isEncrypted = false,
    this.description,
    this.options,
    this.minValue,
    this.maxValue,
    required this.defaultValue,
    this.isReadonly = false,
    this.requiresRestart = false,
    this.validationRegex,
    this.dependsOn,
    this.visibleCondition,
    this.tooltip,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    final options = map['options'] as String?;
    List<String>? optionsList;
    if (options != null && options.isNotEmpty) {
      try {
        final decoded = jsonDecode(options) as List<dynamic>;
        optionsList = decoded.map((e) => e.toString()).toList();
      } catch (_) {
        optionsList = null;
      }
    }

    return AppSettingsModel(
      id: map['id'] as int,
      settingKey: map['setting_key'] as String,
      settingValue: map['setting_value'] as String? ?? '',
      settingType: map['setting_type'] as String,
      category: map['category'] as String,
      groupName: map['group_name'] as String?,
      displayOrder: (map['display_order'] as int?) ?? 0,
      isEncrypted: (map['is_encrypted'] as int?) == 1,
      description: map['description'] as String?,
      options: optionsList,
      minValue: map['min_value'] as String?,
      maxValue: map['max_value'] as String?,
      defaultValue: map['default_value'] as String,
      isReadonly: (map['is_readonly'] as int?) == 1,
      requiresRestart: (map['requires_restart'] as int?) == 1,
      validationRegex: map['validation_regex'] as String?,
      dependsOn: map['depends_on'] as String?,
      visibleCondition: map['visible_condition'] as String?,
      tooltip: map['tooltip'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'setting_type': settingType,
      'category': category,
      'group_name': groupName,
      'display_order': displayOrder,
      'is_encrypted': isEncrypted ? 1 : 0,
      'description': description,
      'options': options != null ? jsonEncode(options) : null,
      'min_value': minValue,
      'max_value': maxValue,
      'default_value': defaultValue,
      'is_readonly': isReadonly ? 1 : 0,
      'requires_restart': requiresRestart ? 1 : 0,
      'validation_regex': validationRegex,
      'depends_on': dependsOn,
      'visible_condition': visibleCondition,
      'tooltip': tooltip,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  AppSettingsModel copyWith({
    int? id,
    String? settingKey,
    String? settingValue,
    String? settingType,
    String? category,
    String? groupName,
    int? displayOrder,
    bool? isEncrypted,
    String? description,
    List<String>? options,
    String? minValue,
    String? maxValue,
    String? defaultValue,
    bool? isReadonly,
    bool? requiresRestart,
    String? validationRegex,
    String? dependsOn,
    String? visibleCondition,
    String? tooltip,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppSettingsModel(
      id: id ?? this.id,
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      settingType: settingType ?? this.settingType,
      category: category ?? this.category,
      groupName: groupName ?? this.groupName,
      displayOrder: displayOrder ?? this.displayOrder,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      description: description ?? this.description,
      options: options ?? this.options,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      defaultValue: defaultValue ?? this.defaultValue,
      isReadonly: isReadonly ?? this.isReadonly,
      requiresRestart: requiresRestart ?? this.requiresRestart,
      validationRegex: validationRegex ?? this.validationRegex,
      dependsOn: dependsOn ?? this.dependsOn,
      visibleCondition: visibleCondition ?? this.visibleCondition,
      tooltip: tooltip ?? this.tooltip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  dynamic get typedValue {
    switch (settingType) {
      case 'int':
        return int.tryParse(settingValue) ?? int.tryParse(defaultValue) ?? 0;
      case 'double':
        return double.tryParse(settingValue) ?? double.tryParse(defaultValue) ?? 0.0;
      case 'bool':
        final value = settingValue.isNotEmpty ? settingValue : defaultValue;
        return value == '1' || value.toLowerCase() == 'true';
      case 'json':
        try {
          return jsonDecode(settingValue);
        } catch (_) {
          try {
            return jsonDecode(defaultValue);
          } catch (_) {
            return settingValue;
          }
        }
      default:
        return settingValue.isNotEmpty ? settingValue : defaultValue;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettingsModel &&
        other.id == id &&
        other.settingKey == settingKey &&
        other.settingValue == settingValue;
  }

  @override
  int get hashCode => id.hashCode ^ settingKey.hashCode ^ settingValue.hashCode;
}

class SettingValidator {
  static ValidationResult validate(AppSettingsModel setting, dynamic value) {
    final String stringValue = value.toString();

    // التحقق من النوع
    switch (setting.settingType) {
      case 'int':
        if (int.tryParse(stringValue) == null) {
          return ValidationResult(
            isValid: false,
            errorMessage: 'القيمة يجب أن تكون رقماً صحيحاً',
          );
        }
        break;
      case 'double':
        if (double.tryParse(stringValue) == null) {
          return ValidationResult(
            isValid: false,
            errorMessage: 'القيمة يجب أن تكون رقماً عشرياً',
          );
        }
        break;
      case 'bool':
        final lowerValue = stringValue.toLowerCase();
        if (!['0', '1', 'true', 'false'].contains(lowerValue)) {
          return ValidationResult(
            isValid: false,
            errorMessage: 'القيمة يجب أن تكون true/false أو 0/1',
          );
        }
        break;
    }

    // التحقق من القيمة الدنيا
    if (setting.minValue != null && setting.minValue!.isNotEmpty) {
      final min = num.tryParse(setting.minValue!);
      final current = num.tryParse(stringValue);
      if (min != null && current != null && current < min) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'القيمة يجب أن تكون أكبر من أو تساوي $min',
        );
      }
    }

    // التحقق من القيمة القصوى
    if (setting.maxValue != null && setting.maxValue!.isNotEmpty) {
      final max = num.tryParse(setting.maxValue!);
      final current = num.tryParse(stringValue);
      if (max != null && current != null && current > max) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'القيمة يجب أن تكون أقل من أو تساوي $max',
        );
      }
    }

    // التحقق من التعبير المنتظم
    if (setting.validationRegex != null && setting.validationRegex!.isNotEmpty) {
      final regex = RegExp(setting.validationRegex!);
      if (!regex.hasMatch(stringValue)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'القيمة لا تطابق التنسيق المطلوب',
        );
      }
    }

    // التحقق من الخيارات المحددة
    if (setting.options != null && setting.options!.isNotEmpty) {
      if (!setting.options!.contains(stringValue)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'القيمة يجب أن تكون واحدة من: ${setting.options!.join(", ")}',
        );
      }
    }

    return ValidationResult(isValid: true);
  }
}

@immutable
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}