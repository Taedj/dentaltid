import 'dart:convert';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class RemoteConfig {
  final String supportEmail;
  final String supportPhone;
  final String websiteUrl;
  final String paymentInfoUrl;

  RemoteConfig({
    required this.supportEmail,
    required this.supportPhone,
    required this.websiteUrl,
    required this.paymentInfoUrl,
  });

  factory RemoteConfig.defaults() {
    return RemoteConfig(
      supportEmail: 'zitounitidjani@gmail.com',
      supportPhone: '+213657293332',
      websiteUrl: 'https://github.com/zitounitidjani', // Placeholder
      paymentInfoUrl: 'https://github.com/zitounitidjani', // Placeholder
    );
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      supportEmail: json['support_email'] ?? 'zitounitidjani@gmail.com',
      supportPhone: json['support_phone'] ?? '+213657293332',
      websiteUrl: json['website_url'] ?? '',
      paymentInfoUrl: json['payment_info_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'support_email': supportEmail,
      'support_phone': supportPhone,
      'website_url': websiteUrl,
      'payment_info_url': paymentInfoUrl,
    };
  }
}

class RemoteConfigService {
  static const String _configKey = 'remote_app_config';
  // Default URL - User can change this in Developer settings if needed, but usually hardcoded to a master repo
  static const String _defaultUrl = 'https://gist.githubusercontent.com/Taedj/9bf1dae53f37681b9c13dab8cde8472f/raw/155052a4f8a8d5c25be339821cfcfb5ecf08ec56/config.json'; 

  Future<void> fetchAndCacheConfig() async {
    try {
      final customUrl = SettingsService.instance.getString('config_source_url') ?? _defaultUrl;
      final response = await http.get(Uri.parse(customUrl));
      
      if (response.statusCode == 200) {
        final data = response.body;
        // Validate JSON
        jsonDecode(data); 
        // Save to cache
        await SettingsService.instance.setString(_configKey, data);
      }
    } catch (e) {
      // Fail silently, use cache
      print('Config fetch failed: $e');
    }
  }

  RemoteConfig getConfig() {
    final cachedData = SettingsService.instance.getString(_configKey);
    if (cachedData != null) {
      try {
        final json = jsonDecode(cachedData);
        return RemoteConfig.fromJson(json);
      } catch (_) {}
    }
    return RemoteConfig.defaults();
  }
}

final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  // We can't watch async fetch here easily without FutureProvider, 
  // but we want immediate synchronous access for UI.
  // The fetch happens in background (void).
  return RemoteConfigService().getConfig();
});
