import 'package:flutter/material.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// Generic settings dialog that can be used across different screens
/// Supports master switches and dependent sub-settings
class GenericSettingsDialog extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;
  final double? width;

  const GenericSettingsDialog({
    super.key,
    required this.title,
    required this.items,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: width ?? 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) => _buildSettingsItem(item)).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.close),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    if (item is SwitchSettingsItem) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(item.title),
            subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
            value: item.value,
            onChanged: item.enabled ?? true ? item.onChanged : null,
          ),
          // Show dependent items only when master switch is enabled
          if (item.value && item.dependentItems != null)
            Padding(
              padding: const EdgeInsets.only(right: 32.0),
              child: Column(
                children: item.dependentItems!
                    .map((dependentItem) => _buildSettingsItem(dependentItem))
                    .toList(),
              ),
            ),
        ],
      );
    } else if (item is CheckboxSettingsItem) {
      return CheckboxListTile(
        title: Text(item.title),
        subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
        value: item.value,
        onChanged: item.enabled ?? true ? item.onChanged : null,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// Base class for settings items
abstract class SettingsItem {
  final String title;
  final String? subtitle;

  const SettingsItem({
    required this.title,
    this.subtitle,
  });
}

/// Switch settings item with optional dependent sub-items
class SwitchSettingsItem extends SettingsItem {
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<SettingsItem>? dependentItems;
  final bool? enabled;

  const SwitchSettingsItem({
    required super.title,
    super.subtitle,
    required this.value,
    required this.onChanged,
    this.dependentItems,
    this.enabled,
  });
}

/// Checkbox settings item
class CheckboxSettingsItem extends SettingsItem {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool? enabled;

  const CheckboxSettingsItem({
    required super.title,
    super.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled,
  });
}
