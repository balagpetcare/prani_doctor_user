import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A thin wrapper around [TextFormField] that enforces the app's consistent
/// input decoration (set globally in [AppTheme]) while providing common
/// convenience parameters.
///
/// Use this instead of raw [TextFormField] / [TextField] in feature forms so
/// that field styling, text actions, and accessibility attributes are applied
/// uniformly.
///
/// ```dart
/// AppTextField(
///   controller: _nameController,
///   label: l10n.name,
///   validator: (v) => v?.isEmpty == true ? l10n.fieldRequired : null,
///   textInputAction: TextInputAction.next,
///   nextFocusNode: _nextFocus,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.initialValue,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  /// When set, pressing the keyboard "next" action moves focus to this node.
  final FocusNode? nextFocusNode;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? initialValue;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      enabled: enabled,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: (value) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
        onSubmitted?.call(value);
      },
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: maxLength != null ? null : '',
      ),
    );
  }
}

/// A read-only [AppTextField] that opens a picker dialog/sheet on tap.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.enabled = true,
    this.suffixIcon = Icons.arrow_drop_down,
  });

  final String label;
  final String? value;
  final String? hint;
  final VoidCallback onTap;
  final bool enabled;
  final IconData suffixIcon;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint ?? label,
      initialValue: value,
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      suffixIcon: Icon(suffixIcon),
    );
  }
}
