import 'dart:convert';

AqiData aqiDataFromJson(String str) => AqiData.fromJson(json.decode(str));

class AqiData {
  final int aqi;
  final String cityName;
  final String dominantPollutant;
  final String time;

  AqiData({
    required this.aqi,
    required this.cityName,
    required this.dominantPollutant,
    required this.time,
  });

  factory AqiData.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'ok') {
      throw Exception('API returned an error: ${json['data']}');
    }

    final data = json['data'];

    return AqiData(
      aqi: data['aqi'] as int,
      cityName: data['city']['name'] as String,
      dominantPollutant: data['dominentpol'] as String,
      time: data['time']['s'] as String,
    );
  }
}