import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wethr_app/api_keys.dart';

class TimeZoneData{
  final String zoneName;
  final Duration offset;

  TimeZoneData({
    required this.zoneName,
    required this.offset,
  });

  factory TimeZoneData.fromJson(Map<String, dynamic> json) {
    final String zoneName = json['zoneName'];
    final int offsetInSeconds = json['gmtOffset'];
    final Duration offset = Duration(seconds: offsetInSeconds);

    return TimeZoneData(
      zoneName: zoneName,
      offset: offset,
    );
  }

  @override
  String toString() {
    return "$zoneName (Offset: ${offset.inHours} hours)";
  }
}

class TimeZoneProvider {
  Future<TimeZoneData> getTimeZoneData(double latitude, double longitude) async {
    final url = 'http://api.timezonedb.com/v2.1/get-time-zone?key=${TIME_ZONE_DB_KEY}&format=json&by=position&lat=$latitude&lng=$longitude';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load timezone data');
    }

    final data = jsonDecode(response.body);
    return TimeZoneData.fromJson(data);
  }
}