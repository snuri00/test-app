import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/radar_screen.dart';
import 'services/flight_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FlightProvider(),
      child: const FlightRadarApp(),
    ),
  );
}

class FlightRadarApp extends StatelessWidget {
  const FlightRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKYWATCH ATC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RadarScreen(),
    );
  }
}
