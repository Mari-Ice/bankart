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
  final String token;
  final String fingerprint;
  final String cardType;
  final String cardHolder;
  final String binDigits;
  final String firstSixDigits;
  final String lastFourDigits;
  final String expirationMonth;
  final String expirationYear;

  TokenizationResponse({
    required this.token,
    required this.fingerprint,
    required this.cardType,
    required this.cardHolder,
    required this.binDigits,
    required this.firstSixDigits,
    required this.lastFourDigits,
    required this.expirationMonth,
    required this.expirationYear,
  });

  factory TokenizationResponse.fromJson(Map<String, dynamic> json) {
    final creditcard = json['creditcard'] as Map<String, dynamic>;
    return TokenizationResponse(
      token: json['token'],
      fingerprint: json['fingerprint'],
      cardType: creditcard['cardType'],
      cardHolder: creditcard['cardHolder'],
      binDigits: creditcard['binDigits'],
      firstSixDigits: creditcard['firstSixDigits'],
      lastFourDigits: creditcard['lastFourDigits'],
      expirationMonth: creditcard['expirationMonth'],
      expirationYear: creditcard['expirationYear'],
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
  Future<String> tokenize(CardData cardData) async {
    try {

      // Get device fingerprint
      final deviceData = await _getDeviceData();

      // Get initial tokenization data
      final tokenData = await _getInitialToken(cardData);

      // Prepare additional data using response values
      final Map<String, dynamic> additionalData = {
        ...cardData.additionalData ?? {},
        'card_type': tokenData.cardType,
        'full_name': tokenData.cardHolder,
        'bin_digits': tokenData.binDigits,
        'first_six_digits': tokenData.firstSixDigits,
        'last_four_digits': tokenData.lastFourDigits,
        'month': tokenData.expirationMonth,
        'year': tokenData.expirationYear,
        'fingerprint': tokenData.fingerprint,
      };

      // Make final tokenization request
      final response = await _httpClient.post(
        Uri.parse('$_gatewayHost/integrated/tokenize/$_integrationKey'),
        body: {
          'token': tokenData.token,
          'additionalData': jsonEncode(additionalData),
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
    } catch (e) {
      throw 'Tokenization failed: $e';
    }
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

  Future<Map<String, dynamic>> _getDeviceData() async {
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