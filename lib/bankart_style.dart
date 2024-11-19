import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BankartStyle {
  String name;
  final BorderStyle borderStyle;
  final double borderRadius;
  final double padding;
  final TextStyle? textStyle;
  final Color? buttonColor;
  final Color? cardColor;
  final double buttonElevation;
  final Size? buttonSize;
  final ThemeData themeData;
  final double heightSpace;
  final double widthSpace;
  final double dateWidth;
  final double cvvWidth;
  final double paymentButtonWidth;
  final double paymentButtonRadius;

  BankartStyle.init({
    required this.name,
    this.borderStyle = BorderStyle.solid,
    this.borderRadius = 8,
    required this.padding,
    this.textStyle,
    this.buttonColor = Colors.lightGreen,
    this.cardColor,
    this.buttonElevation = 10,
    this.buttonSize,
    required this.themeData,
    required this.heightSpace,
    required this.widthSpace,
    this.dateWidth = 100,
    this.cvvWidth = 100,
    this.paymentButtonWidth = 100,
    this.paymentButtonRadius = 10,
  });

  factory BankartStyle(
      {String? name,
        BorderStyle? borderStyle,
        double? borderRadius,
        double? padding,
        TextStyle? textStyle,
        Color? buttonColor,
        Color? cardColor,
        double? buttonElevation,
        Size? buttonSize,
        ThemeData? themeData,
        double? heightSpace,
        double? widthSpace,
        double? dateWidth,
        double? cvvWidth,
        double? paymentButtonWidth,
        double? paymentButtonRadius}) =>
      BankartStyle.init(
        name: name ?? 'classic',
        borderStyle: borderStyle ??
            ((name == 'grid' || name == 'inline')
                ? BorderStyle.none
                : BorderStyle.solid),
        borderRadius: borderRadius ?? (name == 'inline' ? 30 : 8),
        padding: padding ?? 8,
        textStyle: textStyle,
        buttonColor: buttonColor ??
            (themeData != null
                ? themeData.colorScheme.primary
                : Colors.lightGreen),
        cardColor: cardColor ??
            (themeData != null ? themeData.colorScheme.surface : Colors.white),
        buttonElevation: buttonElevation ?? 10,
        buttonSize: buttonSize,
        themeData: themeData ?? ThemeData.light(),
        heightSpace: heightSpace ?? 12,
        widthSpace: widthSpace ?? 8,
        dateWidth: dateWidth ?? 80,
        cvvWidth: cvvWidth ?? 50,
        paymentButtonWidth: paymentButtonWidth ?? 100,
        paymentButtonRadius: paymentButtonRadius ?? 10,
      );

  @override
  String toString() =>
      'BankartStyle(name: $name, borderStyle: $borderStyle, borderRadius: $borderRadius)';

  InputBorder inputBorder() {
    if (borderStyle == BorderStyle.none) return InputBorder.none;
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
            color: themeData.colorScheme.primary, style: borderStyle));
  }
}
