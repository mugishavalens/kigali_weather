import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Weather {
  Weather({
    required this.temperature,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.time,
  });

  final double temperature;
  final int humidity;
  final double wind;
  final int code;
  final String time;

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      wind: (json['wind_speed_10m'] as num).toDouble(),
      code: (json['weather_code'] as num).toInt(),
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature_2m': temperature,
      'relative_humidity_2m': humidity,
      'wind_speed_10m': wind,
      'weather_code': code,
      'time': time,
    };
  }

  // time looks like '2026-10-27T12:30', so this gives '12:30'.
  String get hour => time.substring(11, 16);
}

String describe(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 2) return 'Partly cloudy';
  if (code == 3) return 'Cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 57) return 'Drizzle';
  if (code >= 61 && code <= 67) return 'Rain';
  if (code >= 80 && code <= 82) return 'Rain showers';
  if (code >= 95) return 'Thunderstorm';
  return 'Unknown';
}

class City {
  const City(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

const cities = [
  City('Kigali', -1.9441, 30.0619),
  City('Huye', -2.5967, 29.7394),
  City('Musanze', -1.4998, 29.6344),
  City('Rubavu', -1.6792, 29.2585),
];

Future<Weather> fetchWeather(City city) async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=${city.latitude}&longitude=${city.longitude}'
    '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
    '&timezone=Africa%2FKigali',
  );

  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception(
      'The weather server answered ${response.statusCode}',
    );
  }

  final data =
      jsonDecode(response.body) as Map<String, dynamic>;

  return Weather.fromJson(
    data['current'] as Map<String, dynamic>,
  );
}

// Step 7: remember the chosen city.

Future<void> saveCity(City city) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('city', city.name);
}

Future<City> loadCity() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('city');
  for (final city in cities) {
    if (city.name == name) return city;
  }
  return cities.first; // First time: Kigali.
}

// Step 8: keep the last weather of each city.

Future<void> saveWeather(City city, Weather weather) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('weather_${city.name}', jsonEncode(weather.toJson()));
}

Future<Weather?> loadSavedWeather(City city) async {
  final prefs = await SharedPreferences.getInstance();
  final text = prefs.getString('weather_${city.name}');
  if (text == null) return null;
  return Weather.fromJson(jsonDecode(text) as Map<String, dynamic>);
}
