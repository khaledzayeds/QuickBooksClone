// app_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.validator,
    this.textInputAction,
    this.autofocus = false,
  });

  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  TextEditingController? _internalController;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.controller == null) {
      _internalController = TextEditingController(
        text: widget.initialValue ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _internalController?.dispose();
      _internalController = widget.controller == null
          ? TextEditingController(text: widget.initialValue ?? '')
          : null;
      return;
    }

    if (widget.controller == null && !_focusNode.hasFocus) {
      final nextText = widget.initialValue ?? '';
      if (_controller.text != nextText) {
        _controller.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.readOnly
                ? Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
