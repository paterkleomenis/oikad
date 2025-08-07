import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import '../services/validation_service.dart';
import '../services/config_service.dart';

class RegistrationFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String locale;

  const RegistrationFormSection({
    Key? key,
    required this.title,
    required this.children,
    required this.locale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: ConfigService.normalAnimationDuration,
          curve: Curves.easeOutCubic,
          style: Theme.of(context).textTheme.titleLarge!,
          child: Text(LocalizationService.t(locale, title)),
        ),
        const SizedBox(height: ConfigService.defaultPadding),
        ...children,
        const SizedBox(height: ConfigService.largePadding),
      ],
    );
  }
}

class CustomTextField extends StatefulWidget {
  final String labelKey;
  final String locale;
  final Function(String?) onSaved;
  final Function(String?)? onChanged;
  final bool required;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? initialValue;
  final TextEditingController? controller;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final String? prefixText;
  final String? suffixText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final String? hintText;

  const CustomTextField({
    Key? key,
    required this.labelKey,
    required this.locale,
    required this.onSaved,
    this.onChanged,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.initialValue,
    this.controller,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String? _getValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && (value == null || value.trim().isEmpty)) {
      return ValidationService.validateRequired(
        value,
        widget.labelKey,
        widget.locale,
      );
    }

    // Apply specific validation based on field type
    switch (widget.labelKey) {
      case 'email':
        return ValidationService.validateEmail(value, widget.locale);
      case 'phone':
        return ValidationService.validatePhone(value, widget.locale);
      case 'tax_number':
        return ValidationService.validateTaxNumber(value, widget.locale);
      case 'id_card_number':
        return ValidationService.validateIdCard(value, widget.locale);
      case 'postal_code':
        return ValidationService.validatePostalCode(value, widget.locale);
      case 'name':
      case 'family_name':
      case 'father_name':
      case 'mother_name':
        return ValidationService.validateName(value, widget.locale);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = LocalizationService.t(widget.locale, widget.labelKey);
    final hint = widget.hintText ?? (widget.required ? '$label *' : label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
      child: AnimatedContainer(
        duration: ConfigService.fastAnimationDuration,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : null,
            suffixIcon: widget.suffixIcon != null
                ? Icon(widget.suffixIcon)
                : null,
            counterText: widget.maxLength != null ? '' : null,
          ),
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          validator: _getValidator,
          onSaved: widget.onSaved,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          inputFormatters: widget.inputFormatters,
          obscureText: widget.obscureText,
        ),
      ),
    );
  }
}

class CustomDropdown<T> extends StatelessWidget {
  final String labelKey;
  final String locale;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final Function(T?)? onSaved;
  final bool required;
  final String? Function(T?)? validator;

  const CustomDropdown({
    Key? key,
    required this.labelKey,
    required this.locale,
    required this.items,
    required this.onChanged,
    this.value,
    this.onSaved,
    this.required = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = LocalizationService.t(locale, labelKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: required ? '$label *' : label,
        ),
        items: items,
        onChanged: onChanged,
        onSaved: onSaved,
        validator:
            validator ??
            (required
                ? (v) => v == null
                      ? ValidationService.validateRequired(
                          null,
                          labelKey,
                          locale,
                        )
                      : null
                : null),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}

class BooleanDropdown extends StatelessWidget {
  final String labelKey;
  final String locale;
  final bool? value;
  final Function(bool?) onChanged;
  final Function(bool?)? onSaved;
  final bool required;

  const BooleanDropdown({
    Key? key,
    required this.labelKey,
    required this.locale,
    required this.onChanged,
    this.value,
    this.onSaved,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<bool>(
      labelKey: labelKey,
      locale: locale,
      value: value,
      items: [
        DropdownMenuItem(
          value: true,
          child: Text(LocalizationService.t(locale, 'yes')),
        ),
        DropdownMenuItem(
          value: false,
          child: Text(LocalizationService.t(locale, 'no')),
        ),
      ],
      onChanged: onChanged,
      onSaved: onSaved,
      required: required,
    );
  }
}

class DatePickerField extends StatefulWidget {
  final String labelKey;
  final String locale;
  final DateTime? value;
  final Function(DateTime?) onChanged;
  final Function(DateTime?)? onSaved;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hintTextKey;

  const DatePickerField({
    Key? key,
    required this.labelKey,
    required this.locale,
    required this.onChanged,
    this.value,
    this.onSaved,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.hintTextKey,
  }) : super(key: key);

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    if (widget.value != null) {
      _controller.text =
          '${widget.value!.day.toString().padLeft(2, '0')}/'
          '${widget.value!.month.toString().padLeft(2, '0')}/'
          '${widget.value!.year}';
    } else {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime(2000, 1, 1),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now(),
      locale: Locale(widget.locale),
    );

    if (picked != null) {
      setState(() {
        _updateControllerText();
      });
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = LocalizationService.t(widget.locale, widget.labelKey);
    final hintText = widget.hintTextKey != null
        ? LocalizationService.t(widget.locale, widget.hintTextKey!)
        : LocalizationService.t(widget.locale, 'select_birth_date');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
      child: GestureDetector(
        onTap: _selectDate,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: widget.required ? '$hintText *' : hintText,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            validator: widget.required
                ? (value) => widget.value == null
                      ? ValidationService.validateRequired(
                          null,
                          widget.labelKey,
                          widget.locale,
                        )
                      : ValidationService.validateDateNotFuture(
                          widget.value,
                          widget.locale,
                        )
                : (value) => ValidationService.validateDateNotFuture(
                    widget.value,
                    widget.locale,
                  ),
            onSaved: (value) => widget.onSaved?.call(widget.value),
          ),
        ),
      ),
    );
  }
}

class AnimatedSubmitButton extends StatelessWidget {
  final String labelKey;
  final String locale;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedSubmitButton({
    Key? key,
    required this.labelKey,
    required this.locale,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = LocalizationService.t(locale, labelKey);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ConfigService.smallPadding,
        vertical: ConfigService.smallPadding,
      ),
      decoration: BoxDecoration(
        color: (backgroundColor ?? theme.colorScheme.primary).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(ConfigService.cardBorderRadius),
      ),
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class FormProgressIndicator extends StatelessWidget {
  final double progress;
  final String locale;
  final Color? color;

  const FormProgressIndicator({
    Key? key,
    required this.progress,
    required this.locale,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Form Progress', style: theme.textTheme.bodySmall),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: progressColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 6,
        ),
      ],
    );
  }
}

class SectionDivider extends StatelessWidget {
  final double thickness;
  final double height;
  final Color? color;

  const SectionDivider({
    Key? key,
    this.thickness = 1.5,
    this.height = 32,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(thickness: thickness, height: height, color: color);
  }
}

class RequiredFieldIndicator extends StatelessWidget {
  final String text;
  final bool required;
  final TextStyle? style;

  const RequiredFieldIndicator({
    Key? key,
    required this.text,
    this.required = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!required) return Text(text, style: style);

    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
