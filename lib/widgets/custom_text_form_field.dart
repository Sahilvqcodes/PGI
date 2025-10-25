import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextStyle? hintStyle;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool? isValid;
  final Alignment? alignment;
  final double? width;
  final AutovalidateMode? autoValidateMode;
  final TextEditingController? scrollPadding;
  final FocusNode? focusNode;
  final bool? autofocus;
  final TextStyle? textStyle;
  final bool? obscureText;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? textInputType;
  final int? maxLines;
  final bool? readOnly;
  final Widget? prefixIcon;
  final BoxConstraints? prefixConstraints;
  final bool? enableInteractiveSelection;
  final BoxConstraints? suffixConstraints;
  final EdgeInsets? contentPadding;
  final InputBorder? borderDecoration;
  final Color? fillColor;
  final Color? cursorColor;
  final bool? filled;
  final double? height;
  final bool? isDense;
  final Function()? onTap;
  final bool? showCursor;
  final TextStyle? style;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.hintStyle,
    this.style,
    this.onChanged,
    this.validator,
    this.suffixIcon,
    this.isValid,
    this.alignment,
    this.width,
    this.autoValidateMode,
    this.scrollPadding,
    this.focusNode,
    this.autofocus,
    this.textStyle,
    this.obscureText,
    this.textInputAction,
    this.maxLines,
    this.readOnly,
    this.prefixIcon,
    this.prefixConstraints,
    this.enableInteractiveSelection,
    this.suffixConstraints,
    this.contentPadding,
    this.borderDecoration,
    this.fillColor,
    this.filled,
    this.height,
    this.isDense,
    this.inputFormatters,
    this.textInputType,
    this.onTap,
    this.showCursor,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(

      controller: controller,
      obscuringCharacter: '*',
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        hintStyle: hintStyle ,

        border: borderDecoration ??
            OutlineInputBorder(
              borderSide: BorderSide(color:Colors.grey,  width: 1),
              borderRadius: BorderRadius.circular(50),
            ),
        focusedBorder: borderDecoration ??
            OutlineInputBorder(
              borderSide: BorderSide(color:Colors.grey,  width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
        enabledBorder: borderDecoration ??
            OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(50),
            ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        contentPadding: maxLines != null && maxLines! > 3
            ? const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
            : const EdgeInsets.symmetric(horizontal: 15),
      ),
      style: style ,
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
      obscureText: obscureText ?? false,
      textInputAction: textInputAction,
      maxLines: maxLines ?? 1,
      readOnly: readOnly ?? false,
      inputFormatters: inputFormatters,
      keyboardType: textInputType,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autoValidateMode,
      cursorColor: cursorColor,
      showCursor: showCursor ?? true ,


    );
  }
}
