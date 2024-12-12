# Flutter Package for Bankart Payment Gateway

This is a flutter package for Bankart Payment Gateway. It provides a widget that can be used to tokenize the card data and mimics the Stripe card input widget.

# Usage
- include inside your pubspec.yaml file the following dependency:
```yaml
dependencies:
  bankart: 
    git:
      url: https://github.com/Mari-Ice/bankart.git
```

- import the package in your dart file:
```dart
import 'package:bankart/bankart.dart';
import 'package:bankart/bankart_style.dart'; // optional, if you want to use BankartStyle object
```
- create a new instance of Bankart object with required parameter SharedSecret.

constructor fingerprint: 
```dart
factory Bankart(String sharedSecret,
          {BankartStyle? style,
          String? paymentButtonText,
          String? cardHolder,
          String? cardHolderErrorText, Function(dynamic)? onSuccess, Function(dynamic)? onError})
```

- render the object directly in the widget tree
- also possible to use bankart.client.tokenize(CardData cardData) method to tokenize the card data directly without of usage of our widget
- there are two possible main styles for the widget, that you name in the initialization of the object with the `name` parameter of `BankartStyle` enum. The default style is `classic`, the other option is `grid`.
- the widget has a `onSuccess` and `onError` callback that you can use to handle result of tokenization. The `onSuccess` callback returns the token (string), the `onError` callback returns the error message.
- the widget has a `paymentButtonText` parameter that you can use to change the text of the payment button.
- you can pass your own text for the CardHolder field, CardNumber field and ExpiryDate field, by setting the `cardHolderText`, `cardNumberText` and `expiryDateText` parameters in the initialization of the object.
- you can pass your own error messages via `errorMessages` parameter as a Map<string> with the following keys: `empty`, `expired`, `tokenization`, `cardHolder`.
- you can control style of the widget via `BankartStyle` object. 