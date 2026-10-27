import 'package:flutter/material.dart';

import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
      ),
      home: const WeatherScreen(),
    );
  }
}

IconData iconFor(int code) {
  if (code == 0) {
    return Icons.wb_sunny;
  }

  if (code <= 3) {
    return Icons.cloud;
  }

  if (code == 45 || code == 48) {
    return Icons.foggy;
  }

  if (code >= 95) {
    return Icons.thunderstorm;
  }

  if (code >= 51) {
    return Icons.water_drop;
  }

  return Icons.help_outline;
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  City city = cities.first;
  Weather? weather;
  bool loading = true;
  bool offline = false;
  String? error;

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    final saved = await loadCity();
    setState(() {
      city = saved;
    });
    await load();
  }

  Future<void> load() async {
    final asked = city;
    try {
      final result = await fetchWeather(asked);
      await saveWeather(asked, result);
      // The user may have tapped another city while we were waiting.
      if (!mounted || asked != city) return;
      setState(() {
        weather = result;
        loading = false;
        offline = false;
        error = null;
      });
    } catch (e) {
      final saved = await loadSavedWeather(asked);
      if (!mounted || asked != city) return;
      setState(() {
        loading = false;
        if (saved != null) {
          weather = saved;
          offline = true;
          error = null;
        } else {
          weather = null;
          error = 'Could not load the weather. Check your internet connection.';
        }
      });
    }
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  void choose(City chosen) {
    if (chosen == city) return;
    setState(() {
      city = chosen;
      weather = null;
      loading = true;
      offline = false;
      error = null;
    });
    saveCity(chosen);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${city.name} Weather')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final c in cities)
                  ChoiceChip(
                    label: Text(c.name),
                    selected: c == city,
                    onSelected: (_) => choose(c),
                  ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (offline)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.yellow.shade300,
                            child: Text(
                              'Offline: showing the weather saved at ${weather!.hour}',
                            ),
                          ),
                        WeatherCard(weather: weather!),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(iconFor(weather.code), size: 72),
            const SizedBox(height: 8),
            Text(
              '${weather.temperature.round()}°C',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              describe(weather.code),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined),
                    const SizedBox(width: 4),
                    Text('${weather.humidity}%'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.air),
                    const SizedBox(width: 4),
                    Text('${weather.wind} km/h'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Updated at ${weather.hour}'),
          ],
        ),
      ),
    );
  }
}
