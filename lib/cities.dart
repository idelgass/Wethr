import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class City {
  final int id;
  final String name;
  final String country;

  City({
    required this.id,
    required this.name,
    required this.country
  });

  // TODO : Need to have an optional state param to include along with the country code
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      // Without this dart parses the id using the num type, super of both int and double
      // Then complains about double not being a subtype of int
      // My brother in christ, why would you have dynamic typing/parsing if you can't properly infer an int
      id: json['id'] is int ? json['id'] : (json['id'] as num).toInt(),
      name: json['name'],
      country: json['country'],
    );
  }
}

class CityProvider {
  List<City> _cities = [];

  Future<void> loadCities() async {
    final String response = await rootBundle.loadString('assets/city.list.json');
    final List<dynamic> cityData = json.decode(response);

    _cities = cityData.map((data) => City.fromJson(data)).toList();
  }

  List<String> getCityNames() {
    return _cities.map((city) => "${city.name}, ${city.country}").toList();
  }
}
