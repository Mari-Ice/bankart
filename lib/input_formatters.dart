import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text =
    newValue.text.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i != 0 && i % 4 == 0) {
        buffer.write(' '); // Add space every 4 digits
      }
      buffer.write(text[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    bool isDeletion = false;

    if (oldValue.text.length > newValue.text.length) {
      isDeletion = true;
    }

    final text =
    newValue.text.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    final buffer = StringBuffer();
    if (text.length == 1 && int.parse(text) > 1) {
      buffer.write('0');
      buffer.write(text);
    } else if (text.length == 2 && int.parse(text) > 12) {
      buffer.write('12');
    } else {
      buffer.write(text.substring(0, text.length > 2 ? 2 : text.length));
    }
    if ((!isDeletion && buffer.length == 2) || text.length > 2) {
      buffer.write('/'); // Add slash after 2 digits
    }
    if (text.length > 2) {
      buffer.write(text.substring(2));
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
