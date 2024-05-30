import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _locationController = TextEditingController();
  String _location = 'Unknown Location';
  String _temperature = '--';
  String _weatherDescription = 'N/A';
  String _weatherIcon = '';
  String _humidity = '--';
  String _windSpeed = '--';
  String _pressure = '--';
  String _aqi = '--';
  String _aqiDescription = 'N/A';
  bool _isLoading = false;
  List<dynamic> _forecast = [];

  Future<void> _fetchWeatherData(String location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=bd5e378503939ddaee76f12ad7a97608&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];
        setState(() {
          _location = data['name'];
          _temperature = '${data['main']['temp']}°C';
          _weatherDescription = data['weather'][0]['description'];
          _weatherIcon = _getWeatherIcon(data['weather'][0]['icon']);
          _humidity = '${data['main']['humidity']}%';
          _windSpeed = '${data['wind']['speed']} m/s';
          _pressure = '${data['main']['pressure']} hPa';
        });
        await _fetchForecastData(lat, lon);
        await _fetchAQIData(lat, lon);
      } else {
        _showErrorDialog('Failed to fetch weather data. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchForecastData(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,alerts&appid=bd5e378503939ddaee76f12ad7a97608&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _forecast = data['daily'];
        });
      } else {
        print('Forecast API Error: ${response.body}');
        _showErrorDialog('Failed to fetch forecast data. Please try again.');
      }
    } catch (error) {
      print('Error: $error');
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  Future<void> _fetchAQIData(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=bd5e378503939ddaee76f12ad7a97608'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aqi = data['list'][0]['main']['aqi'];
        setState(() {
          _aqi = aqi.toString();
          _aqiDescription = _getAQIDescription(aqi);
        });
      } else {
        print('AQI API Error: ${response.body}');
        _showErrorDialog('Failed to fetch AQI data. Please try again.');
      }
    } catch (error) {
      print('Error: $error');
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  String _getAQIDescription(int aqi) {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  String _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return '☀️';
      case '01n':
        return '🌙';
      case '02d':
      case '02n':
        return '🌤️';
      case '03d':
      case '03n':
        return '🌥️';
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧️';
      case '10d':
      case '10n':
        return '🌦️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '❓';
    }
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=bd5e378503939ddaee76f12ad7a97608&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];
        setState(() {
          _location = data['name'];
          _temperature = '${data['main']['temp']}°C';
          _weatherDescription = data['weather'][0]['description'];
          _weatherIcon = _getWeatherIcon(data['weather'][0]['icon']);
          _humidity = '${data['main']['humidity']}%';
          _windSpeed = '${data['wind']['speed']} m/s';
          _pressure = '${data['main']['pressure']} hPa';
        });
        await _fetchForecastData(lat, lon);
        await _fetchAQIData(lat, lon);
      } else {
        _showErrorDialog('Failed to fetch weather data. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blueGrey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _locationController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter your location',
                        labelStyle: TextStyle(color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () =>
                              _fetchWeatherData(_locationController.text),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _getCurrentLocationWeather,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text('Get Current Location Weather'),
                    ),
                    if (_isLoading) Center(child: CircularProgressIndicator()),
                    if (!_isLoading)
                      Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                            'Location: $_location',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Temperature: $_temperature',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Weather: $_weatherDescription',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Humidity: $_humidity',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Wind Speed: $_windSpeed',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Pressure: $_pressure',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Air Quality Index: $_aqi',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Text(
                            'AQI Description: $_aqiDescription',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '$_weatherIcon',
                            style: TextStyle(fontSize: 50, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_forecast.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      '7-Day Forecast',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    ..._forecast.map((day) {
                      return Card(
                        color: Colors.blueGrey[800],
                        child: ListTile(
                          leading: Text(
                            _formatDate(day['dt']),
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          title: Text(
                            'Temp: ${day['temp']['day']}°C',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Weather: ${day['weather'][0]['description']}',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          trailing: Text(
                            _getWeatherIcon(day['weather'][0]['icon']),
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
