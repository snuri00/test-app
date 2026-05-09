import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import 'flight_service.dart';

enum FetchStatus { idle, loading, success, error, rateLimited }

class FlightProvider extends ChangeNotifier {
  final FlightService _service = FlightService();

  List<Flight> _flights = [];
  Flight? _selectedFlight;
  FetchStatus _status = FetchStatus.idle;
  String? _errorMessage;
  DateTime? _lastUpdate;
  Timer? _refreshTimer;
  int _totalCount = 0;
  String _filterQuery = '';
  String _statusFilter = 'ALL';

  static const refreshInterval = Duration(seconds: 30);

  List<Flight> get flights => _filtered;
  List<Flight> get allFlights => _flights;
  Flight? get selectedFlight => _selectedFlight;
  FetchStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  int get totalCount => _totalCount;
  String get filterQuery => _filterQuery;
  String get statusFilter => _statusFilter;
  bool get isLoading => _status == FetchStatus.loading;

  List<Flight> get _filtered {
    return _flights.where((f) {
      final q = _filterQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          f.displayCallsign.toLowerCase().contains(q) ||
          (f.originCountry?.toLowerCase().contains(q) ?? false) ||
          f.icao24.contains(q);
      final matchesStatus = _statusFilter == 'ALL' ||
          f.flightStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get airborne => _flights.where((f) => !f.onGround).length;
  int get onGround => _flights.where((f) => f.onGround).length;

  void startAutoRefresh() {
    fetchFlights();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => fetchFlights());
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> fetchFlights() async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    notifyListeners();

    try {
      final result = await _service.fetchAllFlights();
      _flights = result;
      _totalCount = result.length;
      _lastUpdate = DateTime.now();
      _status = FetchStatus.success;
      _errorMessage = null;
    } on RateLimitException {
      _status = FetchStatus.rateLimited;
      _errorMessage = 'RATE LIMIT - RETRY IN 60s';
    } catch (e) {
      _status = FetchStatus.error;
      _errorMessage = e.toString().toUpperCase();
    }
    notifyListeners();
  }

  void selectFlight(Flight? flight) {
    _selectedFlight = flight;
    notifyListeners();
  }

  void setFilter(String query) {
    _filterQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
