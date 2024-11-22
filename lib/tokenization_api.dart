import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

/// Card data for tokenization
class CardData {
  final String cardHolder;
  final String pan;
  final String? cvv;
  final int expirationMonth;
  final int expirationYear;
  final Map<String, String>? additionalData;

  CardData({
    required this.cardHolder,
    required this.pan,
    this.cvv,
    required this.expirationMonth,
    required this.expirationYear,
    this.additionalData,
  });
}

/// Initial tokenization response data
class TokenizationResponse {
  final String? token;
  final String? fingerprint;
  final String? cardType;
  final String? cardHolder;
  final String? binDigits;
  final String? firstSixDigits;
  final String? lastFourDigits;
  final String? expirationMonth;
  final String? expirationYear;

  TokenizationResponse({
    this.token,
    this.fingerprint,
    this.cardType,
    this.cardHolder,
    this.binDigits,
    this.firstSixDigits,
    this.lastFourDigits,
    this.expirationMonth,
    this.expirationYear,
  });

  factory TokenizationResponse.fromJson(Map<String, dynamic> json) {
    final creditcard = json['creditcard'] as Map<String, dynamic>;
    return TokenizationResponse(
      token: json.containsKey('token') ? json['token'] : null,
      fingerprint: json.containsKey('fingerprint') ? json['fingerprint'] : null,
      cardType: creditcard.containsKey('cardType') ? creditcard['cardType'] : null,
      cardHolder: creditcard.containsKey('cardHolder') ? creditcard['cardHolder'] : null,
      binDigits: creditcard.containsKey('binDigits') ? creditcard['binDigits'] : null,
      firstSixDigits: creditcard.containsKey('firstSixDigits') ? creditcard['firstSixDigits'] : null,
      lastFourDigits: creditcard.containsKey('lastFourDigits') ? creditcard['lastFourDigits'] : null,
      expirationMonth: creditcard.containsKey('expirationMonth') ? creditcard['expirationMonth'] : null,
      expirationYear: creditcard.containsKey('expirationYear') ? creditcard['expirationYear'] : null,
    );
  }
  factory TokenizationResponse.fromValues(
  {String? token, String? fingerprint, String? cardType, String? cardHolder, String? binDigits, String? firstSixDigits, String? lastFourDigits, String? expirationMonth, String? expirationYear}) {
    return TokenizationResponse(
      token: token,
      fingerprint: fingerprint,
      cardType: cardType,
      cardHolder: cardHolder,
      binDigits: binDigits,
      firstSixDigits: firstSixDigits,
      lastFourDigits: lastFourDigits,
      expirationMonth: expirationMonth,
      expirationYear: expirationYear,
    );
  }

@override
  String toString() {
    return 'TokenizationResponse{token: $token, fingerprint: $fingerprint, cardType: $cardType, cardHolder: $cardHolder, binDigits: $binDigits, firstSixDigits: $firstSixDigits, lastFourDigits: $lastFourDigits, expirationMonth: $expirationMonth, expirationYear: $expirationYear}';
  }
}

/// Core API for IXOPAY tokenization that works across platforms (iOS, Android, Web)
/// Returns token in format: ix::TOKEN
class TokenizationApi {
  static const _defaultGatewayHost = 'https://gateway.bankart.si';
  static const _defaultTokenizationHost = 'https://secure.ixopay.com';

  final String _integrationKey;
  final String _gatewayHost;
  final String _tokenizationHost;
  final http.Client _httpClient;

  TokenizationApi({
    required String integrationKey,
    String? gatewayHost,
    String? tokenizationHost,
    http.Client? httpClient,
  }) : _integrationKey = integrationKey,
        _gatewayHost = gatewayHost ?? _defaultGatewayHost,
        _tokenizationHost = tokenizationHost ?? _defaultTokenizationHost,
        _httpClient = httpClient ?? http.Client();

  /// Tokenizes card data and returns final IX token
  /// Handles fingerprinting automatically based on platform
  Future<String?> tokenize(CardData cardData) async {
    try {

      // Get device fingerprint
      final deviceData = await getDeviceData();

      // Get initial tokenization data
      final tokenData = await _getInitialToken(cardData);

      // Get final IX token
      return getBankartToken(cardData, tokenData, deviceData);

    } catch (e) {
      print('Failed to tokenize card: $e');
      return null;
    }
  }

  Future<String> getBankartToken(CardData? cardData, TokenizationResponse tokenData, Map<String, dynamic> deviceData) async {
    Map<String, dynamic> additionalData = {
        ...cardData?.additionalData ?? {},
      };
    if (tokenData.cardType != null) additionalData['card_type'] = tokenData.cardType!;
    if (tokenData.cardHolder != null) additionalData['full_name'] = tokenData.cardHolder!;
    if (tokenData.lastFourDigits != null) additionalData['last_four_digits'] = tokenData.lastFourDigits!;
    if (tokenData.expirationMonth != null) additionalData['month'] = tokenData.expirationMonth!;
    if (tokenData.expirationYear != null) additionalData['year'] = tokenData.expirationYear!;
    if (tokenData.binDigits != null) additionalData['bin_digits'] = tokenData.binDigits!;
    if (tokenData.firstSixDigits != null) additionalData['first_six_digits'] = tokenData.firstSixDigits!;
    if (tokenData.fingerprint != null) additionalData['fingerprint'] = tokenData.fingerprint!;

    // Make final tokenization request
    final response = await _httpClient.post(
      Uri.parse('$_gatewayHost/integrated/tokenize/$_integrationKey'),
      body: {
        'token': tokenData.token ?? 'bedni token',
         'additionalData': jsonEncode(additionalData) ?? 'bedni additional data',
         'fp': deviceData['fingerprint'],
      },
    );

    if (response.statusCode != 200) {
      throw 'Failed to get final token: ${response.statusCode}';
    }

    final ixToken = response.body.trim();
    if (!ixToken.startsWith('ix::')) {
      throw 'Invalid token format in response';
    }

    return ixToken;
  }

  Future<TokenizationResponse> _getInitialToken(CardData cardData) async {
    final tokenizationKey = await _getTokenizationKey();
    final response = await _httpClient.post(
      Uri.parse('$_tokenizationHost/v1/$tokenizationKey/tokenize/creditcard'),
      body: {
        'cardHolder': cardData.cardHolder,
        'month': cardData.expirationMonth.toString(),
        'year': cardData.expirationYear.toString(),
        if (cardData.cvv != null && cardData.cvv!.isNotEmpty) ...<String, String>{
          'pan': cardData.pan,
          'cvv': cardData.cvv!,
        } else ...<String, String>{
          'panonly': cardData.pan,
        },
      },
    );

    if (response.statusCode != 200) {
      throw 'Invalid token key or request failed';
    }

    final responseData = jsonDecode(response.body);
    if (!(responseData['success'] as bool)) {
      throw responseData['errors'].toString();
    }

    return TokenizationResponse.fromJson(responseData);
  }

  Future<String> _getTokenizationKey() async {
    final response = await _httpClient.get(
      Uri.parse('$_gatewayHost/integrated/getTokenizationKey/$_integrationKey'),
    );

    if (response.statusCode != 200) {
      throw 'Invalid integration key';
    }

    return jsonDecode(response.body)['tokenizationKey'];
  }

  Future<Map<String, dynamic>> getDeviceData() async {
    if (kIsWeb) {
      throw 'Web platform is not supported';
    }
    return _getNativeDeviceData();
  }

  Future<Map<String, dynamic>> _getNativeDeviceData() async {
    final deviceInfo = DeviceInfoPlugin();
    final window = WidgetsBinding.instance.window;
    Map<String, dynamic> deviceData;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceData = {
        'fingerprint': info.fingerprint,
        'browserData': {
          'java': false,
          'language': Platform.localeName.split('_')[0],
          'colorDepth': 32,
          'screenHeight': window.physicalSize.height.toInt(),
          'screenWidth': window.physicalSize.width.toInt(),
          'tz': DateTime.now().timeZoneOffset.inMinutes,
          'userAgent': 'Mozilla/5.0 (Linux; Android ${info.version.release}; ${info.model})',
          'platform': 'Android',
        },
      };
    } else {
      final info = await deviceInfo.iosInfo;
      deviceData = {
        'fingerprint': info.identifierForVendor,
        'browserData': {
          'java': false,
          'language': Platform.localeName.split('_')[0],
          'colorDepth': 32,
          'screenHeight': window.physicalSize.height.toInt(),
          'screenWidth': window.physicalSize.width.toInt(),
          'tz': DateTime.now().timeZoneOffset.inMinutes,
          'userAgent': 'Mozilla/5.0 (${info.model}; CPU iPhone OS ${info.systemVersion.replaceAll('.', '_')})',
          'platform': 'iOS',
        },
      };
    }

    return deviceData;
  }
}