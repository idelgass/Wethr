import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:wethr_app/api_keys.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:wethr_app/cities.dart';
import 'dart:async';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  final String _iconSize = "4x";
  // Access weather for a specific location from OpenWeatherMap
  final WeatherFactory _weatherFactory = WeatherFactory(OPEN_WEATHER_MAP_KEY);
  final CityProvider _cityProvider = CityProvider();

  // Stores weather-query response from OpenWeatherMap
  Weather? _weather;
  Timer? _updateTimer;
  String _selectedCity = "Los Angeles";


  @override
  void initState() {
    super.initState();
    _loadCities();
    // _weatherFactory.currentWeatherByCityName(_selectedCity).then((fweather){
    //   // Ensure UI updates on retrieval
    //   setState(() {
    //     _weather = fweather;
    //   });
    // });
    _updateWeather(_selectedCity);
    _initPeriodicRefresh();
  }

  @override
  void dispose(){
    _updateTimer?.cancel();
    super.dispose();
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
            _displayLocationSearch(),
            _displayLocation(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.1,
            ),
            _displayDateTime(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.1
            ),
            _displayWeather(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.1
            ),
            _displayTemp(),
          ],
        )
    );
  }

  void _initPeriodicRefresh(){
    _updateTimer = Timer.periodic(
      const Duration(minutes: 10),
      (timer){
        _updateWeather(_selectedCity);
        print("Refreshing...");
      }
    );
  }

  // TODO : Include state along with country code for duplicates
  // Populates dropdown_search with list of cities from OpenWeatherMap
  Future<void> _loadCities() async{
    await _cityProvider.loadCities();
    // TODO: Do I need this call here if there is already one in updateWeather?
    setState(() {
      // Set a default city if none is selected yet
      _selectedCity = "New York";
      _updateWeather(_selectedCity);
    });
  }

  // Returns currently selected location that weather data is being retrieved for
  Widget _displayLocation(){
    return Text(
      _weather?.areaName ?? "",
      style: const TextStyle(
        //TODO: Set text style later
      )
    );
  }

  Widget _displayLocationSearch(){
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        // showSelectedItems: true,
        showSearchBox: true,
      ),
      items: _cityProvider.getCityNames(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select a city",
          hintText: "Filter results using the search bar",
        ),
      ),
      onChanged: (String? newCity){
        if(newCity != null) _updateWeather(newCity);
      },
      // selectedItem: "Brazil",
    );
  }

  // Handles logic for changing selected city
  void _updateWeather(String cityName){
    _weatherFactory.currentWeatherByCityName(cityName).then((fweather){
      // Ensure UI updates on retrieval
      setState(() {
        _weather = fweather;
      });
    }).catchError((e){
      print('Error retrieving weather data: $e');
    });
  }

  // TODO: Need to update this information in real time
  // TODO: Localize times to selected city
  // Returns current time, date, and day of the week
  Widget _displayDateTime(){
    // TODO: Make this a _weather? call and add a null case for the datetime
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
              // do NOT use "m" - minutes not month
              "  ${DateFormat("d.M.y").format(currentDateTime)}",
              style: const TextStyle(
                //TODO: Set text style later
              )
            ),
          ],
        ),
      ],
    );
  }

  // Returns icon indicating current weather condition along with text label
  Widget _displayWeather(){
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Weather icon
        Container(
          height: MediaQuery.sizeOf(context).height * 0.3,
          decoration: BoxDecoration(
            image: DecorationImage(image: NetworkImage(
                "https://openweathermap.org/img/wn/${_weather?.weatherIcon}@${_iconSize}.png"))
          ),
        ),
        // Weather description
        Text(
          _weather?.weatherDescription ?? "",
          style: const TextStyle(
            // TODO: Set custom style later
          )
        ),
      ],
    );
  }

  // Returns current temp
  // TODO: Let user select farenheight vs celsius
  Widget _displayTemp(){
    return Text(
      "${_weather?.temperature?.fahrenheit?.toStringAsFixed(0)}° F",
      style: const TextStyle(
        //TODO: Set custom text style
      )
    );
  }

  Widget _displayForecast(){
    return SizedBox();
  }

}