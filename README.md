# Flutter Package for Bankart Payment Gateway

This is a flutter package for Bankart Payment Gateway. It provides a widget that can be used to tokenize the card data and mimics the Stripe card input widget.

# Usage

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