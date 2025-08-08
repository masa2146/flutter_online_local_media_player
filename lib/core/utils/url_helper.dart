import 'dart:io';

class MediaUrlHelper {
  static String sanitizeUrl(String url) {
    // URL'i decode et
    String decodedUrl = Uri.decodeFull(url);

    // Geçerli bir URL olup olmadığını kontrol et
    Uri? uri;
    try {
      uri = Uri.parse(decodedUrl);
    } catch (e) {
      throw Exception('Invalid URL format: $e');
    }

    // HTTP/HTTPS protokol kontrolü
    if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
      throw Exception('URL must use HTTP or HTTPS protocol');
    }

    return decodedUrl;
  }

  static bool isNetworkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkUrlConnectivity(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.headUrl(uri);
      final response = await request.close();
      client.close();

      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      print('URL connectivity check failed: $e');
      return false;
    }
  }
}

