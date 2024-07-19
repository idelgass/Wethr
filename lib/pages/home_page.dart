import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:wethr_app/api_keys.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  // TODO: Replace this with dynamic city selection using a separate page/dropdown
  final String _cityName = "Philadelphia";

  // Access weather for a specific location from OpenWeatherMap
  final WeatherFactory _weatherFactory = WeatherFactory(OPEN_WEATHER_MAP_KEY);

  // Stores weather-query response from OpenWeatherMap
  Weather? _weather;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _weatherFactory.currentWeatherByCityName(_cityName).then((fweather){
      // Ensure UI updates on retrieval
      setState(() {
        _weather = fweather;
      });
    });
  }

  @override
  Widget build(BuildContext buildContext){
    return Scaffold(body: _buildUI());
  }

  Widget _buildUI() {
    // Loading screen
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Load of OpenWeatherMap API successful
    return SizedBox(
        width: MediaQuery
            .sizeOf(context)
            .width,
        height: MediaQuery
            .sizeOf(context)
            .height,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _displayLocation(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.05,
            ),
            _displayDateTime(),
          ],
        )
    );
  }

  Widget _displayLocation(){
    return Text(
      _weather?.areaName ?? "",
      style: const TextStyle(
        //TODO: Set text style later
      )
    );
  }

  Widget _displayDateTime(){
    DateTime currentDateTime = _weather!.date!;
    return Column(
      children: [
        // Display time as Hour:minutes am/pm
        Text(
          DateFormat("h:mm a").format(currentDateTime),
          style: const TextStyle(
            //TODO: Set text style later
          )
        ),
        // Padding
        const SizedBox(
          height: 8,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              // EEEE -> Day of the week
              DateFormat("EEEE").format(currentDateTime),
              style: const TextStyle(
                //TODO: Set text style later
              )
            ),
            Text(
              // day, month, year
              "  ${DateFormat("d.m.y").format(currentDateTime)}",
              style: const TextStyle(
                //TODO: Set text style later
              )
            ),
          ],
        ),
      ],
    );
  }

}