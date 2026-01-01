import 'dart:convert';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart'; // Added import

class RemoteConfig {
  final String supportEmail;
  final String supportPhone;
  final String websiteUrl;
  final String paymentInfoUrl;
  final Map<String, dynamic> pricing;

  RemoteConfig({
    required this.supportEmail,
    required this.supportPhone,
    required this.websiteUrl,
    required this.paymentInfoUrl,
    this.pricing = const {},
  });
  factory RemoteConfig.defaults() {
    return RemoteConfig(
      supportEmail: 'zitounitidjani@gmail.com',
      supportPhone: '+213657293332',
      websiteUrl: 'https://taedj.dev',
      paymentInfoUrl: 'https://taedj.dev/pricing',
      pricing: const {
        'DZD': {
          'symbol': 'DZD',
          'position': 'suffix',
          'plans': {
            'premium': {
              'monthly': '2,000',
              'yearly': '20,000',
              'lifetime': '60,000',
            },
            'crown': {
              'monthly': '4,000',
              'yearly': '40,000',
              'lifetime': '100,000',
            },
          },
        },
        'USD': {
          'symbol': r'$',
          'position': 'prefix',
          'plans': {
            'premium': {'monthly': '15', 'yearly': '150', 'lifetime': '450'},
            'crown': {'monthly': '30', 'yearly': '300', 'lifetime': '900'},
          },
        },
      },
    );
  }
  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      supportEmail: json['support_email'] ?? 'zitounitidjani@gmail.com',
      supportPhone: json['support_phone'] ?? '+213657293332',
      websiteUrl: json['website_url'] ?? '',
      paymentInfoUrl: json['payment_info_url'] ?? '',
      pricing: json['pricing'] ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'support_email': supportEmail,
      'support_phone': supportPhone,
      'website_url': websiteUrl,
      'payment_info_url': paymentInfoUrl,
      'pricing': pricing,
    };
  }
}

class RemoteConfigService {
  static const String _configKey = 'remote_app_config';
  static const String _defaultUrl =
      'https://gist.githubusercontent.com/Taedj/9bf1dae53f37681b9c13dab8cde8472f/raw/config.json';

  final SettingsService _settingsService;
  final Logger _log = Logger('RemoteConfig');

  RemoteConfigService()
    : _settingsService = SettingsService.instance; // Using singleton

  Future<void> fetchAndCacheConfig() async {
    _log.info('Fetching remote config from Gist...');
    try {
      final customUrl =
          _settingsService.getString('config_source_url') ?? _defaultUrl;
      final response = await http.get(Uri.parse(customUrl));

      if (response.statusCode == 200) {
        final data = response.body;
        jsonDecode(data); // Validate JSON
        await _settingsService.setString(_configKey, data);
        _log.info('Successfully fetched and cached remote config.');
      } else {
        _log.warning(
          'Failed to fetch remote config. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log.severe(
        'Error fetching remote config: $e. Using cached/default values.',
      );
    }
  }

  RemoteConfig getConfig() {
    final cachedData = _settingsService.getString(_configKey);
    if (cachedData != null) {
      try {
        final json = jsonDecode(cachedData);
        return RemoteConfig.fromJson(json);
      } catch (_) {
        _log.severe('Failed to parse cached config. Using defaults.');
      }
    }
    return RemoteConfig.defaults();
  }
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

final remoteConfigProvider = FutureProvider<RemoteConfig>((ref) async {
  final service = ref.watch(remoteConfigServiceProvider);
  await service.fetchAndCacheConfig();
  return service.getConfig();
});
