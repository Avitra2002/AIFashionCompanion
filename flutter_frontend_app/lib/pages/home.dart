import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_frontend_app/model/lookcard.dart';
import 'package:flutter_frontend_app/services/api.dart';
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
    List<dynamic> _chillLooks = [];
    List<dynamic> _dressyLooks = [];


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
        //TODO: for current weather data , but emulator is only able to pick up San Jose despite location change
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

    Future<void> _generateHomepageLooks() async {
      try {
        final tempValue = double.tryParse(_temp ?? '')?.round();
        final tempDisplay = tempValue != null ? tempValue.toString() : '--';

        final chillPrompt = "chill everyday look for $tempDisplay degrees and $_condition weather";
        final dressyPrompt = "put together and dressy look for $tempDisplay degrees and $_condition weather";
        // TODO: Running both API calls in parallel


        // final results = await Future.wait([
        //   ApiService.chatWithAI(chillPrompt),
        //   ApiService.chatWithAI(dressyPrompt),
        // ]);

        // final chillLooks = results[0];
        // final dressyLooks = results[1];
        print ("Sending look request");
        // Running sequentially due to limited resources
        final chillLooks = await ApiService.chatWithAI(chillPrompt);
        final dressyLooks = await ApiService.chatWithAI(dressyPrompt);

        setState(() {
          _chillLooks = chillLooks;
          _dressyLooks = dressyLooks;
        });
      } catch (e) {
        print('❌ Failed to generate homepage looks: $e');
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
        await _generateHomepageLooks();
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
        body: SafeArea(child: SingleChildScrollView (
        child: Padding(
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
                children: [
                  Text(
                    "Chill Everyday look",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generateHomepageLooks,
                  ), 
                ],
              ),

              SizedBox(
                height: 320,
                child: _chillLooks.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _chillLooks.length,
                        itemBuilder: (context, index) {
                          final look = _chillLooks[index];
                          return LookCard(
                            lookData: look,
                            lookName: look['look_name'],
                            description: look['description'],
                            collageBase64: look['collage_base64'],
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Dress for the occasion",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Icon(Icons.refresh),
                ],
              ),

              const SizedBox(height: 12),

              
              SizedBox(
                height: 320,
                child: _dressyLooks.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dressyLooks.length ,
                        itemBuilder: (context, index) {
                          final look = _dressyLooks[index];
                          return LookCard(
                            lookData: look,
                            lookName: look['look_name'],
                            description: look['description'],
                            collageBase64: look['collage_base64'],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        )
        )
      );
    }
  }


