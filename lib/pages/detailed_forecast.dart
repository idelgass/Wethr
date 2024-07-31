import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

import 'package:wethr_app/timezones.dart';


class DetailedForecastView extends StatelessWidget{
  final Weather _weather;
  final List<Weather> _forecast;
  final TimeZoneData _timeZoneData;

  // TODO: Clean up
  DetailedForecastView({
    super.key,
    required Weather weather,
    required List<Weather> forecast,
    required TimeZoneData timeZoneData
  }): _weather = weather,
      _forecast = forecast,
      _timeZoneData = timeZoneData;

  @override
  Widget build(BuildContext context){
    final DateTime forecastDateUtc = _weather.date!.toUtc();
    final Duration timeZoneOffset = _timeZoneData.offset;
    final DateTime forecastDate = forecastDateUtc.add(timeZoneOffset);
    List<Weather> hourlyForecast = getHourlyForecast(forecastDateUtc);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Forecast for ${DateFormat("EEEE, MMM d").format(forecastDate)}",
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
                      "https://openweathermap.org/img/wn/${_weather.weatherIcon}@4x.png",
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _weather.weatherDescription ?? '',
                style: const TextStyle(fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                "Temperature: ${_weather.temperature!.fahrenheit!.toStringAsFixed(0)}° F",
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                "Humidity: ${_weather.humidity}%",
                style: const TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                "Wind Speed: ${_weather.windSpeed} m/s",
                style: const TextStyle(
                    fontSize: 18
                ),
              ),
              Expanded(
                child: _displayHourly(hourlyForecast)
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayHourly(List<Weather> hourlyForecast){
    return ListView.builder(
      itemCount: hourlyForecast.length,
      itemBuilder: (context, index){
        Weather hourWeather = hourlyForecast.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                "${DateFormat("h a").format(hourWeather.date!)}:",
              ),
              Image.network(
                "https://openweathermap.org/img/wn/${hourWeather.weatherIcon}@2x.png",
              ),
              Text(
                "${hourWeather.temperature!.fahrenheit!.toStringAsFixed(0)}° F",
              ),
            ],
          ),
        );
      },
    );
  }

  List<Weather> getHourlyForecast(DateTime date){
    return _forecast.where((wthr) => wthr.date!.day == date.day).toList();
  }

}

