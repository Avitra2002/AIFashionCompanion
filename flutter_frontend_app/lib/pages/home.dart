import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

  class _HomePageState extends State<HomePage> {
    String? _date;
    String? _location;
    String? _temp;
    String? _condition;

    @override
    void initState() {
      super.initState();
      _loadData();
    }

    Future<Map<String, dynamic>> fetchWeather() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      final lat = position.latitude;
      final lon = position.longitude;
      print ("Latitude: $lat, Longitude: $lon");

      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      final url =
        //for current weather data , but emulator is only able to pick up San Jose despite location change
          // 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

        //hard corded lat long for now
          'https://api.openweathermap.org/data/2.5/weather?lat=19.9090109798&lon=99.839318151&units=metric&appid=$apiKey';

      final response = await http.get(Uri.parse(url));
      print("weather results: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'location': data['name'],
          'temp': data['main']['temp'].toString(),
          'condition': data['weather'][0]['main'],
        };
      } else {
        throw Exception('Failed to fetch weather data');
      }
    }


    Future<void> _loadData() async {
      final now = DateTime.now();
      final formattedDate = DateFormat('MMMM d').format(now);

      try {
        final weather = await fetchWeather();
        print("Weather data: $weather");
        if (weather.isEmpty) {
          throw Exception('Weather data is empty');}
        setState(() {
          _date = formattedDate;
          _temp = weather['temp'];
          _condition = weather['condition'];
          _location = weather['location'];
        });
      } catch (e) {
        setState(() {
          _date = formattedDate;
          _temp = '--';
          _condition = 'Unavailable';
          _location = 'Unknown';
        });
      }
    }

                      

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0, // Hide default AppBar height
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _date ?? 'Loading...',
                        style: const TextStyle(fontSize: 16,),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Looks for ${_temp ?? '--'}° "),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on, color: Colors.orange),
                      Text (_location ?? ''),
                      const SizedBox(width: 4),
                      Text(_condition ?? '',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

            
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Chill look",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.refresh), // 
                ],
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text("Outfit suggestion goes here")),
                ),
              ),

            
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Dress for the occasion",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.refresh),
                ],
              ),

              const SizedBox(height: 12),

              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text("Outfit suggestion goes here")),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }


