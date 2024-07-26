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
  List<Weather>? _forecast;
  Timer? _updateTimer;
  City? _selectedCity;


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
            Expanded(child: _buildUI(),),
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
            // _displayLocationSearch(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.02,
            ),
            _displayLocation(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.01,
            ),
            _displayDateTime(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.1
            ),
            _displayWeather(),
            // Padding
            // SizedBox(
            //   height: MediaQuery.sizeOf(context).height * 0.1
            // ),
            _displayTemp(),
            // Padding
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.15,
            ),
            _displayForecast(),
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
        popupProps: PopupProps.menu(
          // showSelectedItems: true,
          showSearchBox: true,
        ),
        items: _cityProvider.getCities(),
        dropdownDecoratorProps: DropDownDecoratorProps(
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
  }

  // TODO: Need to update this information in real time
  // TODO: Localize times to selected city
  // Returns current time, date, and day of the week
  Widget _displayDateTime(){
    // TODO: Make this a _weather? call and add a null case for the datetime
    final DateTime weatherDateTime = _weather!.date!;
    return Column(
      children: [
        // Display time as Hour:minutes am/pm
        Text(
            "Retrieved: ${DateFormat("EEEE").format(weatherDateTime)}, "
                "${DateFormat("d.M.y").format(weatherDateTime)} "
                "at ${DateFormat("h:mm a").format(weatherDateTime)}",
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
  // TODO: Let user select farenheight vs celsius
  Widget _displayTemp(){
    return Text(
      "${_weather?.temperature?.fahrenheit?.toStringAsFixed(0)}° F",
      style: const TextStyle(
        //TODO: Set custom text style
      )
    );
  }

  // Currently just adds 24h (-3h on the last day) and gets the weather at that time
  // TODO: Implement some method of getting forecast at set time (like 7-10am or midday) or checking for conditions like rain
  //
  // Last day occasionally displays same day as prev if current time is close enough to 12am
  // TODO: maybe just calculate displayed days instead of retrieving from forecast object
  //
  // Consider displauing forecast as a single column that users can scroll through
  // Could retrieve first weather object from each day as the thumbnail or maybe the one between 7-10am
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

    final DateTime currentDateTime = _weather!.date!;
    // Forecast gives current info + next 5 days for 6 total cards
    final int length = 6;
    final DateTime endDate = currentDateTime.add(Duration(days: length));

    return Expanded(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: length,
          crossAxisSpacing: 2,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7
        ),
        itemCount: length,
        itemBuilder: (context, index) {
          DateTime date = currentDateTime.add(Duration(days: index));
          // For SOME REASON the provided 5 day forecast does not include the very last time
          // So we subtract the stupid bit from the index to not attempt access of element 40 (out of range)
          int stupidBit = index == 5 ? 1 : 0;
          Weather forecastWeather = _forecast!.elementAt(index * 8 - stupidBit);

          return GestureDetector(
            onTap: () {
              // TODO: Implement detailed view
            },
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text(DateFormat("E").format(date)),
                  Text(DateFormat("E").format(forecastWeather.date!)),
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        image: DecorationImage(image: NetworkImage(
                            "https://openweathermap.org/img/wn/${forecastWeather.weatherIcon}@${_iconSize}.png"))
                    ),
                  ),
                  Text(
                      "${forecastWeather.temperature!.celsius!.toStringAsFixed(0)}C"
                  ),
                  //Text('${forecastDay.temperature!.celsius!.toStringAsFixed(0)}°C'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}