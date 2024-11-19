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

  const Bankart.init(
      {super.key, required this.sharedSecret, required this.style, required this.paymentButtonText, required this.client});

  factory Bankart(String sharedSecret, {BankartStyle? style, String? paymentButtonText}) =>
      Bankart.init(
          sharedSecret: sharedSecret,
          style: style ?? BankartStyle(),
          paymentButtonText: paymentButtonText ?? 'Pay',
          client: TokenizationApi(integrationKey: sharedSecret)
      );

  String getPlatformVersion() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    }
    return 'Unknown platform version';
  }

  @override
  State<Bankart> createState() => _BankartState();
}

class _BankartState extends State<Bankart> {
  String cardNumber = '';
  String cardPath = 'packages/bankart/assets/generic-svgrepo-com.svg';
  String? token;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.style.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...bankartContent(context),
        ],
      ),
    );
  }

  List<Widget> bankartContent(BuildContext context) {
    List<Widget> widgets = [];
    if (!kIsWeb) {
      widgets
          .add(_buildPaymentMethodsSection(context) ?? const SizedBox.shrink());
      widgets.add(
        SizedBox(height: widget.style.heightSpace),
      );
      widgets.add(
        const Center(child: Text('or pay by', style: TextStyle(fontSize: 16))),
      );
      widgets.add(
        SizedBox(height: widget.style.heightSpace),
      );
    }
    widgets.add(_bankart(context));
    return widgets;
  }

  // Payment methods section (Apple Pay / Google Pay buttons)
  Widget? _buildPaymentMethodsSection(BuildContext context) {
    if (!Platform.isIOS && !Platform.isAndroid) return null;
    return ElevatedButton.icon(
      onPressed: () {
        // Add Apple Pay functionality here
      },
      icon: Icon(
        Platform.isIOS ? Icons.apple : Icons.payments,
        size: 24,
        color: Platform.isIOS ? Colors.white : Colors.black,
      ),
      label: Text(
        Platform.isIOS ? 'Apple Pay' : 'Google Pay',
        style: TextStyle(color: Platform.isIOS ? Colors.white : Colors.black),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor:
        Platform.isIOS ? Colors.black : widget.style.buttonColor,
      ),
    );
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
              color: widget.style.themeData!.colorScheme.primary,
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
        labelText: 'Card Number',
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
          labelText: 'MM/YY',
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
    );
  }

  Widget _payButton(BuildContext context) {
    return SizedBox(
        width: widget.style.paymentButtonWidth,
        height: 50,
        child: ElevatedButton(
            onPressed: () async{
              String? result = await widget.client.tokenize(
                  CardData(
                    cardHolder: 'Marija Absec',
                    pan: '4111111111111111',
                    expirationMonth: 11,
                    expirationYear: 2025,
                    cvv: '111',
                  )
              );
              setState(() {
                token = result;
              });
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
