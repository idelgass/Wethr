import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class DetailedForecastView extends StatelessWidget{
  final Weather weather;

  const DetailedForecastView({
    super.key,
    required this.weather
  });

  @override
  Widget build(BuildContext context){
    final DateTime forecastDate = weather.date!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Forecast for ${DateFormat("EEEE, MMM d, y").format(forecastDate)}",
        ),
      ),
      body: SizedBox(
        width: MediaQuery
            .sizeOf(context)
            .width,
        height: MediaQuery
            .sizeOf(context)
            .height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.sizeOf(context).height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      "https://openweathermap.org/img/wn/${weather.weatherIcon}@4x.png",
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                weather.weatherDescription ?? '',
                style: const TextStyle(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                "Temperature: ${weather.temperature!.fahrenheit!.toStringAsFixed(0)}° F",
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                "Humidity: ${weather.humidity}%",
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                "Wind Speed: ${weather.windSpeed} m/s",
                style: const TextStyle(
                    fontSize: 18
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}