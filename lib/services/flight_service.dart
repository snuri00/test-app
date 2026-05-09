import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/flight.dart';

class FlightService {
  static const _baseUrl = 'https://opensky-network.org/api';
  static const _timeout = Duration(seconds: 15);

  Future<List<Flight>> fetchAllFlights({
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) async {
    String url = '$_baseUrl/states/all';
    if (minLat != null && maxLat != null && minLon != null && maxLon != null) {
      url += '?lamin=$minLat&lomin=$minLon&lamax=$maxLat&lomax=$maxLon';
    }

    final response = await http
        .get(Uri.parse(url))
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final states = data['states'] as List<dynamic>?;
      if (states == null) return [];
      return states
          .where((s) => s != null && s.length >= 14)
          .map((s) => Flight.fromStateVector(s as List<dynamic>))
          .where((f) => f.hasPosition)
          .toList();
    } else if (response.statusCode == 429) {
      throw RateLimitException('API rate limit exceeded');
    } else {
      throw ApiException('HTTP ${response.statusCode}');
    }
  }

  Future<List<Flight>> fetchFlightsInBounds(
    double minLat, double maxLat, double minLon, double maxLon,
  ) async {
    return fetchAllFlights(
      minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon,
    );
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class RateLimitException implements Exception {
  final String message;
  const RateLimitException(this.message);
  @override
  String toString() => 'RateLimitException: $message';
}
