// TODO: Store a TextStyle object (potentially in another file) to make repeated reference to

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:wethr_app/api_keys.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:wethr_app/cities.dart';
import 'dart:async';

import 'package:wethr_app/pages/detailed_forecast.dart';
import 'package:wethr_app/timezones.dart';

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
  // TODO: Make timezonedb key an arg to match weather factory
  final TimeZoneProvider _timeZoneProvider = TimeZoneProvider();

  // Stores weather-query response from OpenWeatherMap
  Weather? _weather;
  List<Weather>? _forecast;
  Timer? _updateTimer;
  City? _selectedCity;
  TimeZoneData? _timeZoneData;


  @override
  void initState() {
    super.initState();
    _loadCities();
    _initPeriodicRefresh();
  }

  @override
  void dispose(){
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext buildContext){
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _displayLocationSearch(),
            Expanded(
              child: _buildUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUI() {
    // Loading screen
    if (_weather == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Load of OpenWeatherMap API successful
    return LayoutBuilder(
        builder: (context, constraints){
          return Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Padding
              SizedBox(
                height: constraints.maxHeight * 0.02,
              ),
              _displayLocation(),
              // Padding
              SizedBox(
                height: constraints.maxHeight * 0.01,
              ),
              _displayDateTime(),
              // Padding
              SizedBox(
                  height: constraints.maxHeight * 0.1
              ),
              _displayWeather(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _displayTemp(),
                  // Padding
                  SizedBox(
                    width: constraints.maxWidth * 0.1,
                  ),
                  _displayHumidity()
                ],
              ),
              // Padding
              SizedBox(
                height: constraints.maxHeight * 0.05,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "5-Day Forecast",
                ),
              ),
              _displayForecast(),
            ],
          );
        }
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
      _selectedCity = _cityProvider.getCities().elementAt(20000);
      // TODO: Make sure this bang is kosher
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownSearch<City>(
        popupProps: const PopupProps.menu(
          // showSelectedItems: true,
          showSearchBox: true,
        ),
        items: _cityProvider.getCities(),
        dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select a city",
            hintText: "Filter results using the search bar",
          ),
        ),
        itemAsString: (City? city) => city?.toString() ?? 'Error: City could not be loaded',
        onChanged: (City? newCity){
          _selectedCity = newCity;
          _updateWeather(newCity);
        },
        // selectedItem: _selectedCity,
      ),
    );
  }

  // Handles logic for updating weather info and changing cities
  void _updateWeather(City? city){
    // Guard condition for nullable type city
    if(city == null){
      print("Error: Attempted to update whether while selected city is null");
      return;
    }

    _weatherFactory.currentWeatherByLocation(city.lat, city.lon).then((fweather){
      // Ensure UI updates on retrieval
      setState(() {
        _weather = fweather;
      });
    }).catchError((e){
      print('Error retrieving weather data: $e');
    });

    _weatherFactory.fiveDayForecastByLocation(city.lat, city.lon).then((fforecast){
      setState(() {
        _forecast = fforecast;
      });
    }).catchError((e){
      print("Error retrieving forecast data: $e");
    });

    _timeZoneProvider.getTimeZoneData(city.lat, city.lon).then((fzoneData){
      setState(() {
        _timeZoneData = fzoneData;
      });
    }).catchError((e){
      print("Error retrieving timezone data: $e");
    });
  }

  // TODO: Need to update this information in real time
  // TODO: Localize times to selected city
  // TODO: Null safety here is a MESS, need to work some stuff out here
  // Returns current time, date, and day of the week
  Widget _displayDateTime(){
    // TODO: Make this a _weather? call and add a null case for the datetime
    final DateTime weatherDateTimeUtc = _weather!.date!.toUtc();
    final Duration? timeZoneOffset = _timeZoneData?.offset;
    final DateTime? weatherDateTime = weatherDateTimeUtc.add(timeZoneOffset ?? Duration(seconds: 0));

    return Column(
      children: [
        // Display time as Hour:minutes am/pm
        Text(
            "Retrieved: ${DateFormat("EEEE").format(weatherDateTime ?? weatherDateTimeUtc)}, "
                "${DateFormat("d.M.y").format(weatherDateTime ?? weatherDateTimeUtc)} "
                "at ${DateFormat("h:mm a").format(weatherDateTime ?? weatherDateTimeUtc)}",
                // " ${timeZoneOffset ?? "UTC"}",
            style: const TextStyle(
              //TODO: Set text style later
            )
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
        // Weather description
        Text(
          _weather?.weatherDescription ?? "",
          style: const TextStyle(
            // TODO: Set custom style later
          )
        ),
        // Padding
        // Weather icon
        Container(
          height: MediaQuery.sizeOf(context).height * 0.3,
          decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(
                  "https://openweathermap.org/img/wn/${_weather?.weatherIcon}@${_iconSize}.png"))
          ),
        ),
      ],
    );
  }

  // Returns current temp
  // TODO: Let user select fahrenheit vs celsius
  Widget _displayTemp(){
    return Text(
      "${_weather?.temperature?.fahrenheit?.toStringAsFixed(0)}° F",
      style: const TextStyle(
        //TODO: Set custom text style
      )
    );
  }

  Widget _displayHumidity(){
    return Text(
      "Humidity: ${_weather?.humidity?.toStringAsFixed(0)}%",
      style: const TextStyle(
        // TODO: Set text style
    ),
    );
  }


  // TODO: Check null safety
  //
  // Currently just adds 24h (-3h on the last day) and gets the weather at that time
  // TODO: Implement some method of getting forecast at set time (like 7-10am or midday) or checking for conditions like rain
  //
  // Last day occasionally displays same day as prev if current time is close enough to 12am
  // TODO: maybe just calculate displayed days instead of retrieving from forecast object
  //
  // Consider displaying forecast as a single column that users can scroll through
  // Could retrieve first weather object from each day as the th,umbnail or maybe the one between 7-10am
  // Then retain popup functionality w more detailed display
  Widget _displayForecast(){
    if(_forecast == null || _weather == null){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    print("Length of forecast object: " + _forecast!.length.toString());
    print("_forecast.first: " + _forecast!.first.date.toString());
    print("_forecast day 1: " + _forecast!.elementAt(8).date.toString());
    print("_forecast day 2: " + _forecast!.elementAt(16).date.toString());
    print("_forecast day 3: " + _forecast!.elementAt(24).date.toString());
    print("_forecast day 4: " + _forecast!.elementAt(32).date.toString());
    print("_forecast day 5: " + _forecast!.elementAt(39).date.toString());

    debugPrint(_forecast.toString(), wrapWidth: 1024);

    // Forecast gives current info + next 5 days for 6 total cards
    final int length = 6;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // May want to adjust number of columns based on screen width, const for now
          int crossAxisCount = length;
          double cardHeight = constraints.maxHeight;


          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: (constraints.maxWidth / crossAxisCount) / constraints.maxHeight
            ),
            itemCount: length,
            itemBuilder: (context, index) {
              // For SOME REASON the provided 5 day forecast does not include the very last time
              // So we subtract the stupid bit from the index to not attempt access of element 40 (out of range)
              int stupidBit = index == 5 ? 1 : 0;
              Weather forecastWeather = _forecast!.elementAt(index * 8 - stupidBit);
              final DateTime forecastDateTimeUtc = forecastWeather!.date!.toUtc();
              final Duration? timeZoneOffset = _timeZoneData?.offset;
              final DateTime? forecastDateTime = forecastDateTimeUtc.add(timeZoneOffset ?? Duration(seconds: 0));

              return GestureDetector(
                onTap: () {
                  // TODO: Implement detailed view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DetailedForecastView(weather: forecastWeather, forecast: _forecast!, timeZoneData: _timeZoneData!,),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(DateFormat("E").format(forecastDateTime ?? forecastDateTimeUtc)),
                      // Padding
                      // SizedBox(
                      //   height: cardHeight * 0.08,
                      // ),
                      Visibility(
                        visible: cardHeight >= 105,
                        child: Container(
                          height: cardHeight * 0.5,
                          width: cardHeight * 0.5,
                          decoration: BoxDecoration(
                              image: DecorationImage(image: NetworkImage(
                                  "https://openweathermap.org/img/wn/${forecastWeather.weatherIcon}@2x.png"))
                          ),
                        ),
                      ),
                      // Padding
                      // SizedBox(
                      //   height: cardHeight * 0.08,
                      // ),
                      Text(
                          "${forecastWeather.temperature!.fahrenheit!.toStringAsFixed(0)}° F"
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }

}