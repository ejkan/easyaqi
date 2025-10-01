import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'Aqi.dart';

class DisplayOutputPage extends StatefulWidget {
  const DisplayOutputPage({super.key});

  @override
  State<DisplayOutputPage> createState() => _DisplayOutputPageState();
}

class _DisplayOutputPageState extends State<DisplayOutputPage> {
  // Use FutureBuilder to handle async operations and UI states gracefully
  late Future<AqiData> _aqiDataFuture;
  final String _token = "dc044cf74c997c33523325b4d725f96aa77fc36f"; // My API token

  @override
  void initState() {
    super.initState();
    // Start fetching data as soon as the widget is created
    _aqiDataFuture = _fetchAqiData();
  }

  // Method to get user's current position
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  // Method to call the API and parse the data
  Future<AqiData> _fetchAqiData() async {
    try {
      // 1. Get GPS coordinates
      Position position = await _determinePosition();
      double lat = position.latitude;
      double lon = position.longitude;

      // 2. Make the API call using the coordinates
      final uri = Uri.parse('https://api.waqi.info/feed/geo:$lat;$lon/?token=$_token');
      final response = await http.get(uri);

      // 3. Check for a successful response and parse it
      if (response.statusCode == 200) {
        return aqiDataFromJson(response.body);
      } else {
        throw Exception('Failed to load AQI data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw the exception to be caught by the FutureBuilder
      throw Exception('An error occurred: $e');
    }
  }

  // Helper to get colour and level based on AQI value
  ({Color color, String level}) _getAqiInfo(int aqi) {
    if (aqi <= 50) return (color: Colors.green, level: "Good");
    if (aqi <= 100) return (color: Colors.yellow, level: "Moderate");
    if (aqi <= 150) return (color: Colors.orange, level: "Unhealthy for Sensitive Groups");
    if (aqi <= 200) return (color: Colors.red, level: "Unhealthy");
    if (aqi <= 300) return (color: Colors.purple, level: "Very Unhealthy");
    return (color: Colors.brown, level: "Hazardous");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time AQI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _aqiDataFuture = _fetchAqiData();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<AqiData>(
          future: _aqiDataFuture,
          builder: (context, snapshot) {
            // 1. If the future is still running, show a loading spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            // 2. If the future completed with an error, show the error
            else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              );
            }
            // 3. If the future completed with data, display it
            else if (snapshot.hasData) {
              final aqiData = snapshot.data!;
              final aqiInfo = _getAqiInfo(aqiData.aqi);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      aqiData.cityName,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: aqiInfo.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: aqiInfo.color, width: 4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${aqiData.aqi}',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: aqiInfo.color,
                            ),
                          ),
                          const Text('AQI'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      aqiInfo.level,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: aqiInfo.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dominant Pollutant: ${aqiData.dominantPollutant.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last Updated: ${aqiData.time}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }
            // Default case
            return const Text('Press refresh to get data.');
          },
        ),
      ),
    );
  }
}