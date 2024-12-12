import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bankart/bankart_style.dart';
import 'package:bankart/input_formatters.dart';
import 'package:bankart/tokenization_api.dart';

class Bankart extends StatefulWidget {
  final BankartStyle style;
  final String paymentButtonText;
  final String sharedSecret;
  final TokenizationApi client;
  final String cardHolderText;
  final String cardNumberText;
  final String expiryDateText;
  final Map<String, String> errorMessages;
  String? cardHolder;
  Function(dynamic)? onSuccess;
  Function(dynamic)? onError;

  Bankart.init({
    super.key,
    required this.sharedSecret,
    required this.style,
    required this.paymentButtonText,
    required this.client,
    required this.cardHolderText,
    required this.cardNumberText,
    required this.expiryDateText,
    required this.errorMessages,
    this.cardHolder,
    this.onSuccess,
    this.onError,
  });

  factory Bankart(String sharedSecret,
          {BankartStyle? style,
          String? paymentButtonText,
          String? cardHolder,
          String? cardHolderText,
          String? cardNumberText,
          String? expiryDateText,
          Map<String, String>? errorMessages,
          Function(dynamic)? onSuccess,
          Function(dynamic)? onError}) =>
      Bankart.init(
          sharedSecret: sharedSecret,
          style: style ?? BankartStyle(),
          paymentButtonText: paymentButtonText ?? 'Pay',
          client: TokenizationApi(integrationKey: sharedSecret),
          cardHolderText: cardHolderText ?? 'Card Holder',
          cardNumberText: cardNumberText ?? 'Card Number',
          expiryDateText: expiryDateText ?? 'MM/YY',
          errorMessages: errorMessages ?? {'empty': 'All fields are required', 'expired': 'Invalid expiry date', 'cardHolder': 'Card Holder is required', 'tokenization': 'Tokenization failed'},
          cardHolder: cardHolder,
          onSuccess: onSuccess,
          onError: onError);

  String getPlatformVersion() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    }
    return 'Unknown platform version';
  }

  void setCardHolder(String cardHolder) {
    this.cardHolder = cardHolder;
  }

  @override
  State<Bankart> createState() => _BankartState();
}

class _BankartState extends State<Bankart> {
  String cardNumber = '';
  String cvv = '';
  String expiryDate = '';
  String cardHolder = '';
  String cardPath = 'packages/bankart/assets/generic-svgrepo-com.svg';
  String? token;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(widget.style.padding),
        child: Column(
          children: bankartContent(context) ?? const <Widget>[],
        ));
  }

  List<Widget> bankartContent(BuildContext context) {
    List<Widget> widgets = [];
    if (widget.cardHolder == null) {
      widgets.add(Container(
          padding: EdgeInsets.all(widget.style.padding),
          child: Material(
            elevation: widget.style.buttonElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
            ),
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: widget.cardHolderText,
                  border: widget.style.inputBorder(),
                  contentPadding: EdgeInsets.all(widget.style.padding)),
              onChanged: (value) {
                setState(() {
                  cardHolder = value;
                });
              },
            ),
          )));
      widgets.add(
        SizedBox(height: widget.style.heightSpace),
      );
    }
    widgets.add(_bankart(context));
    return widgets;
  }

  Widget _bankart(BuildContext context) {
    switch (widget.style.name) {
      case 'classic':
        return _buildClassicBankart(context);
      case 'grid':
        return _buildGridBankart(context);
      case 'inline':
        if (kIsWeb) return _buildInlineBankart(context);
        throw UnimplementedError('Inline Bankart is not supported on mobile');
      default:
        widget.style.name = 'classic';
        return _buildClassicBankart(context);
    }
  }

  Widget _buildClassicBankart(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(widget.style.padding),
          child: Stack(
            children: [
              Material(
                elevation: widget.style.buttonElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(widget.style.borderRadius),
                ),
                child: _buildCardNumberField(context),
              ),
              Positioned(
                right: 10,
                top: 8,
                bottom: 8,
                child: SvgPicture.asset(
                  cardPath,
                  width: 50,
                  height: 50,
                ),
              )
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(widget.style.padding),
                child: Material(
                  elevation: widget.style.buttonElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(widget.style.borderRadius),
                  ),
                  child: _buildExpiryDateField(context),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(widget.style.padding),
                child: Material(
                  elevation: widget.style.buttonElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(widget.style.borderRadius),
                  ),
                  child: _buildCvvField(context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.style.heightSpace),
        _payButton(context),
      ],
    );
  }

  Widget _buildGridBankart(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: widget.style.buttonElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.style.borderRadius),
          ),
          child: Table(
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
            ),
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      child: Stack(
                        children: [
                          _buildCardNumberField(context),
                          Positioned(
                            right: 10,
                            top: 10,
                            bottom: 10,
                            child: SvgPicture.asset(
                              cardPath,
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Table(
                      border: TableBorder(
                          verticalInside: BorderSide(
                              color:
                                  widget.style.themeData.colorScheme.primary)),
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Container(
                                padding: const EdgeInsets.only(left: 10),
                                child: _buildExpiryDateField(context),
                              ),
                            ),
                            TableCell(
                              child: Container(
                                padding: const EdgeInsets.only(left: 10),
                                child: _buildCvvField(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        SizedBox(height: widget.style.heightSpace),
        _payButton(context),
      ],
    );
  }

  Widget _buildInlineBankart(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            elevation: widget.style.buttonElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    child: _buildCardNumberField(context),
                  ),
                ),
                SizedBox(
                  width: widget.style.dateWidth,
                  child: _buildExpiryDateField(context),
                ),
                SizedBox(
                  width: widget.style.cvvWidth,
                  child: _buildCvvField(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: widget.style.widthSpace),
        _payButton(context),
      ],
    );
  }

  Widget _buildCardNumberField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: widget.cardNumberText,
        border: widget.style.inputBorder(),
        icon: (widget.style.name == 'inline')
            ? SvgPicture.asset(
                cardPath,
                width: 30,
                height: 30,
              )
            : null,
        contentPadding: EdgeInsets.all(widget.style.padding),
      ),
      onTapOutside: (e) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter(RegExp(r'[0-9]*'), allow: true),
        CardNumberInputFormatter(),
        LengthLimitingTextInputFormatter(19)
      ],
      onChanged: (value) {
        setState(() {
          cardNumber = value;
          cardPath = _getCardTypeIcon(cardNumber);
        });
      },
    );
  }

  // Helper widget for expiration date input
  Widget _buildExpiryDateField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
          labelText: widget.expiryDateText,
          border: widget.style.inputBorder(),
          contentPadding: EdgeInsets.all(widget.style.padding)),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter(RegExp(r'[0-9]*'), allow: true),
        ExpiryDateInputFormatter(),
        LengthLimitingTextInputFormatter(5)
      ],
      onTapOutside: (e) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      onChanged: (value) {
        setState(() {
          expiryDate = value;
        });
      },
    );
  }

  // Helper widget for CVV input
  Widget _buildCvvField(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'CVV',
          border: widget.style.inputBorder(),
          contentPadding: EdgeInsets.all(widget.style.padding)),
      keyboardType: TextInputType.number,
      inputFormatters: [LengthLimitingTextInputFormatter(3)],
      onTapOutside: (e) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      onChanged: (value) {
        setState(() {
          cvv = value;
        });
      },
    );
  }

  Widget _payButton(BuildContext context) {
    return SizedBox(
        width: widget.style.paymentButtonWidth,
        height: 50,
        child: ElevatedButton(
            onPressed: () async {
              if (widget.cardHolder == null && cardHolder.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.errorMessages['cardHolder']!),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.errorMessages['empty']!),
                  backgroundColor: Colors.red,
                ));
                return;
              }

              if (expiryDate.contains('/') == false ||
                  int.parse(expiryDate.split('/')[0]) > 12 ||
                  int.parse(expiryDate.split('/')[0]) < 1 ||
                  int.parse(expiryDate.split('/')[1]) + 2000 <
                      DateTime.now().year ||
                  (int.parse(expiryDate.split('/')[1]) + 2000 ==
                          DateTime.now().year &&
                      int.parse(expiryDate.split('/')[0]) <
                          DateTime.now().month)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.errorMessages['expired']!),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              String? result = await widget.client.tokenize(CardData(
                cardHolder: widget.cardHolder ?? cardHolder,
                pan: cardNumber,
                expirationMonth: int.parse(expiryDate.split('/')[0]),
                expirationYear: int.parse(expiryDate.split('/')[1]) + 2000,
                cvv: cvv,
              ));
              if (result == null) {
                if (widget.onError != null) {
                  widget.onError!(widget.errorMessages['tokenization']);
                }
                return;
              }
              setState(() {
                token = result;
              });
              if (widget.onSuccess != null) {
                widget.onSuccess!(token);
              }
              if (kDebugMode) {
                print('Token: $token');
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: widget.style.buttonElevation,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(widget.style.paymentButtonRadius)),
              backgroundColor: widget.style.buttonColor,
            ),
            child: Text(
              widget.paymentButtonText,
            )));
  }

  String _getCardTypeIcon(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
    String assetPath = 'packages/bankart/assets/generic-svgrepo-com.svg';
    if (RegExp(r'^4').hasMatch(cardNumber)) {
      // Visa starts with '4'
      assetPath = 'packages/bankart/assets/visa.svg';
    } else if (RegExp(r'^5[1-5]').hasMatch(cardNumber)) {
      // MasterCard starts with '51' to '55'
      assetPath =
          'packages/bankart/assets/Mastercard Symbol - SVG/Artwork/mc_symbol.svg';
    } else if (RegExp(r'^3[47]').hasMatch(cardNumber)) {
      // American Express starts with '34' or '37'
      assetPath = 'packages/bankart/assets/american-express-svgrepo-com.svg';
    } else if (RegExp(r'^6(?:011|5)').hasMatch(cardNumber)) {
      // Discover starts with '6011' or '65'
      assetPath = 'packages/bankart/assets/discover-card.svg';
    } else if (RegExp(r'^3(?:0|6|8)').hasMatch(cardNumber)) {
      // Diners Club starts with '30', '36', or '38'
      assetPath = 'packages/bankart/assets/diners-club-logo3.svg';
    } else if (RegExp(r'^(2131|1800|35)').hasMatch(cardNumber)) {
      // JCB starts with '2131', '1800', or '35'
      assetPath = 'packages/bankart/assets/jcb.svg';
    } else if (RegExp(r'^62').hasMatch(cardNumber)) {
      // UnionPay starts with '62'
      assetPath = 'packages/bankart/assets/unionpay.svg';
    }
    return assetPath;
  }
}
