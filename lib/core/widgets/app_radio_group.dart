// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../config/app_typography.dart';

class RadioOption<T> {
  const RadioOption({required this.value, required this.title, this.subtitle});

  final T value;
  final String title;
  final String? subtitle;
}

class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  final List<RadioOption<T>> options;
  final T? groupValue;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(opt.title, style: AppTypography.bodyMedium),
          subtitle: opt.subtitle != null ? Text(opt.subtitle!, style: AppTypography.bodySmall) : null,
          trailing: Radio<T>(
            value: opt.value,
            groupValue: groupValue,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
          onTap: () => onChanged(opt.value),
        );
      }).toList(),
    );
  }
}
