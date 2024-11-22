import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bankart/bankart_style.dart';
import 'package:bankart/input_formatters.dart';
import 'package:bankart/tokenization_api.dart';
import 'package:pay/pay.dart';

class Bankart extends StatefulWidget {
  final BankartStyle style;
  final String paymentButtonText;
  final String sharedSecret;
  final TokenizationApi client;
  String? cardHolder;
  final String cardHolderErrorText;
  Function(dynamic)? onSuccess;
  Function(dynamic)? onError;

  Bankart.init({
    super.key,
    required this.sharedSecret,
    required this.style,
    required this.paymentButtonText,
    required this.client,
    this.cardHolder,
    required this.cardHolderErrorText,
    this.onSuccess,
    this.onError,
  });

  factory Bankart(String sharedSecret,
          {BankartStyle? style,
          String? paymentButtonText,
          String? cardHolder,
          String? cardHolderErrorText, Function(dynamic)? onSuccess, Function(dynamic)? onError}) =>
      Bankart.init(
          sharedSecret: sharedSecret,
          style: style ?? BankartStyle(),
          paymentButtonText: paymentButtonText ?? 'Pay',
          client: TokenizationApi(integrationKey: sharedSecret),
          cardHolder: cardHolder,
          cardHolderErrorText:
              cardHolderErrorText ?? 'Card Holder is required',
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: bankartContent(context) ?? const <Widget>[],
        ));
  }

  List<Widget> bankartContent(BuildContext context) {
    List<Widget> widgets = [];
    // if (!kIsWeb) {
    //   Widget? paymentMethods = _buildPaymentMethodsSection(context);
    //   widgets.add(paymentMethods ?? const SizedBox.shrink());
    //   widgets.add(
    //     SizedBox(height: widget.style.heightSpace),
    //   );
    //   widgets.add(
    //     const Center(child: Text('or pay by', style: TextStyle(fontSize: 16))),
    //   );
    //   widgets.add(
    //     SizedBox(height: widget.style.heightSpace),
    //   );
    // }
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
                  labelText: 'Card Holder',
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

  // Payment methods section (Apple Pay / Google Pay buttons)
  Widget? _buildPaymentMethodsSection(BuildContext context) {
    const _paymentItems = [
      PaymentItem(
        label: 'Total',
        amount: '0.0',
        status: PaymentItemStatus.final_price,
      )
    ];
    if (!Platform.isIOS && !Platform.isAndroid) return null;
    if (Platform.isAndroid) {
      String defaultGooglePay = '''{
        "provider": "google_pay",
        "data": {
          "environment": "TEST",
          "apiVersion": 2,
          "apiVersionMinor": 0,
          "allowedPaymentMethods": [
            {
              "type": "CARD",
              "tokenizationSpecification": {
                "type": "PAYMENT_GATEWAY",
                "parameters": {
                  "gateway": "example",
                  "gatewayMerchantId": "gatewayMerchantId"
                }
              },
              "parameters": {
                "allowedCardNetworks": ["VISA", "MASTERCARD"],
                "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
                "billingAddressRequired": true,
                "billingAddressParameters": {
                  "format": "FULL",
                  "phoneNumberRequired": true
                }
              }
            }
          ],
          "merchantInfo": {
            "merchantName": "Example Merchant Name"
          },
          "transactionInfo": {
            "countryCode": "SI",
            "currencyCode": "EUR"
          }
        }
      }''';
      PaymentConfiguration configuration =
          PaymentConfiguration.fromJsonString(defaultGooglePay);
      return GooglePayButton(
        paymentConfiguration: configuration,
        paymentItems: _paymentItems,
        margin: const EdgeInsets.only(top: 15.0),
        onPaymentResult: (paymentResult) async {
          print('Google Pay payment result: $paymentResult');
          String newToken = await widget.client.getBankartToken(
              null,
              TokenizationResponse.fromValues(
                token: paymentResult['paymentMethodData']['tokenizationData']
                    ['token'],
                cardHolder: paymentResult['paymentMethodData']['info']
                    ['billingAddress']['name'],
                lastFourDigits: paymentResult['paymentMethodData']['info']
                        ['cardDetails']
                    .toString(),
                cardType: paymentResult['paymentMethodData']['info'][
                    'cardNetwork'], // or paymentResult['paymentMethodData']['type'] todo: check if this is correct, make this section more robust to errors
              ),
              await widget.client.getDeviceData());
          setState(() {
            print('Token: $newToken');
            token = newToken;
          });
        },
      );
    } else {
      PaymentConfiguration configuration =
          PaymentConfiguration.fromJsonString('''{
        "provider": "apple_pay",
        "data": {
          "merchantIdentifier": "AMZS",
          "displayName": "Sam's Fish",
          "merchantCapabilities": ["3DS", "debit", "credit"],
          "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
          "countryCode": "SI",
          "currencyCode": "EUR",
          "requiredBillingContactFields": ["emailAddress", "name", "phoneNumber", "postalAddress"],
          "requiredShippingContactFields": [],
          "shippingMethods": [
            {
              "amount": "0.00",
              "detail": "Available within an hour",
              "identifier": "in_store_pickup",
              "label": "In-Store Pickup"
            },
            {
              "amount": "0.00",
              "detail": "5-8 Business Days",
              "identifier": "flat_rate_shipping_id_2",
              "label": "UPS Ground"
            },
            {
              "amount": "0.00",
              "detail": "1-3 Business Days",
              "identifier": "flat_rate_shipping_id_1",
              "label": "FedEx Priority Mail"
            }
          ]
        }
      }''');
      return ApplePayButton(
        paymentItems: _paymentItems,
        style: ApplePayButtonStyle.black,
        type: ApplePayButtonType.buy,
        margin: const EdgeInsets.only(top: 15.0),
        onPaymentResult: (paymentResult) {
          print(paymentResult);
        },
        paymentConfiguration: configuration,
      );
    }
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
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.cardHolderErrorText), backgroundColor: Colors.red,));
                return;
              }
              if(cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required'), backgroundColor: Colors.red,));
                return;
              }

               if (expiryDate.contains('/') == false ||
                  int.parse(expiryDate.split('/')[0]) > 12 ||
                  int.parse(expiryDate.split('/')[0]) < 1 ||
                  int.parse(expiryDate.split('/')[1]) + 2000 < DateTime.now().year ||
                  (int.parse(expiryDate.split('/')[1]) + 2000 == DateTime.now().year &&
                      int.parse(expiryDate.split('/')[0]) <
                          DateTime.now().month)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid expiry date'), backgroundColor: Colors.red,));
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
                 if(widget.onError != null) {
                   widget.onError!('Tokenization failed');
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
