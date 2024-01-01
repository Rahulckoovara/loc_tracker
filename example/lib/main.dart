import 'dart:async';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:background_location_tracker_example/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

//import 'package:permission_handler/permission_handler.dart';



@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
    (data) async => Repo().update(data),
  );
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: loc(),
    );
  }
}




class loc extends StatefulWidget {
  @override
  _locState createState() => _locState();
}

class _locState extends State<loc> {
  var isTracking = false;
  DatabaseHelper _databaseHelper = DatabaseHelper();

   List<Map<String, dynamic>> locations = [];
    final GlobalKey<_locState> locKey = GlobalKey<_locState>();

  @override
  void initState() {
    super.initState();
    _getTrackingStatus();
    
    // _startLocationsUpdatesStream();
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  Future<void> track(int seconds) async {
    await BackgroundLocationTrackerManager.initialize(
      backgroundCallback,
      config: BackgroundLocationTrackerConfig(
        loggingEnabled: true,
        androidConfig: AndroidConfig(
          notificationIcon: 'explore',
          trackingInterval: Duration(seconds: 10),
          distanceFilterMeters: null,
        ),
        iOSConfig: const IOSConfig(
          activityType: ActivityType.FITNESS,
          distanceFilterMeters: null,
          restartAfterKill: true,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Live Locator'),
        ),
         
        body: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children: [

                  // Text('Send notification'),
                   

                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      // child: TextField(
                      //   controller: textEditingController,
                      //   decoration: const InputDecoration(
                      //     border: OutlineInputBorder(),
                      //     labelText: 'Tracking Interval (Seconds)',
                      //   ),
                      //   keyboardType: TextInputType.number,
                      //   inputFormatters: [
                      //     FilteringTextInputFormatter.allow(RegExp(r'\d'))
                      //   ],
                      // ),
                    ),
                    Padding(
                     
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      // child: TextField(
                      //   controller: textEditingUploadIntervalController,
                      //   decoration: const InputDecoration(
                      //     border: OutlineInputBorder(),
                      //     labelText: 'Upload Interval',
                      //   ),
                      //   keyboardType: TextInputType.number,
                      //   inputFormatters: [
                      //     FilteringTextInputFormatter.allow(RegExp(r'\d'))
                      //   ],
                      // ),
                    ),
                   
                    MaterialButton(
                      child: const Text('Stop Tracking'),
                      onPressed: isTracking
                          ? () async {
                             
                              await BackgroundLocationTrackerManager
                                  .stopTracking();
                              setState(() => isTracking = false);
                            }
                          : null,
                    ),
                     MaterialButton(
                       child: const Text('Start Tracking'),
                       onPressed: isTracking
                           ? null
                           : () async {
                            // await track();
                             await BackgroundLocationTrackerManager
                               .startTracking();
                             setState(() => isTracking = true);
                           },
                     ),

                     TextButton(onPressed: (){
                      _showDatabaseDataAlert();
                    //  _showDatabaseDataAlert();
                     }, child: Text('Show Updated Locations')),
                   
                  TextButton(onPressed: (){
                    _deleteRecords();
                  }, child: Text('Delete Records')),
                    // Display the location updates here
                   

                    
                     Column(
                      
                       children: Repo._()._locations.map((location) {
                  return Text(location);
                }).toList(),
                    ),
                  
                
                  
                ],
                ),
              ],
            ),
          ),
        ),
      
    );
  }




 Future<void> _showDatabaseDataAlert() async {
    final storedLocations = await Repo()._databaseHelper.getLocations();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Database Data'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: storedLocations.length,
              itemBuilder: (context, index) {
                final location = storedLocations[index];
                return Card(
                  child: Column(
                    children: [
                      Text(
                          'Latitude: ${location['latitude']} ',style: TextStyle(color: Colors.red)),
                          Text('Longitude: ${location['longitude']}',style: TextStyle(color: Colors.blue)),
                          Text('PlaceName: ${location['placeName']} ',style: TextStyle(color: Colors.green)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

 Future<void> _deleteRecords() async {
    await _databaseHelper.removeAllLocations();
    Repo._()._locations.clear();
    setState(() {});
  }


  Future<void> _getTrackingStatus() async {
    isTracking = await BackgroundLocationTrackerManager.isTracking();
    setState(() {});
  }

  // Future<void> _requestLocationPermission() async {
  //   final result = await Permission.locationAlways.request();
  //   if (result == PermissionStatus.granted) {
  //     print('GRANTED'); // ignore: avoid_print
  //   } else {
  //     print('NOT GRANTED'); // ignore: avoid_print
  //   }
  
  // }
  }
 
class Repo {
  static Repo? _instance;
  DatabaseHelper _databaseHelper = DatabaseHelper();
  final List<String> _locations = [];

  Repo._();

  factory Repo() => _instance ??= Repo._();


  // List<String> getLocationUpdates() {
  //   return _locations;
  // }

  Future<void> update(BackgroundLocationUpdateData data) async {
    final text = 'Latitude: ${data.lat} Longitude: ${data.lon} ';
     print(text); // ignore: avoid_print
     final placeName = await _getPlaceName(data.lat, data.lon);
    final fullText = '$text PlaceName: $placeName';
    


    _locations.add(fullText);
    await _databaseHelper.insertLocation(data.lat, data.lon,placeName);
    await _printStoredLocations();
   

  }
Future<String> _getPlaceName(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
     // final name = placemark.name ?? placemark.thoroughfare ?? placemark.subLocality ?? 'Unknown';
      final area = placemark.locality ?? 'Unknown';
      final country = placemark.country ?? 'Unknown';

      return ' $area, $country';//$name
    }
  } catch (e) {
    print('Error getting place name: $e');
  }

  return 'Unknown';
}

  
  Future<void> _printStoredLocations() async {
    final storedLocations = await _databaseHelper.getLocations();
    print('Stored Locations:');
    for (final location in storedLocations) {
      print('Latitude: ${location['latitude']} Longitude: ${location['longitude']} PlaceName: ${location['placeName']}');
    }
  }


 Future<void> deleteAllLocations() async {
    await _databaseHelper.removeAllLocations();
    await _printStoredLocations();
  }

    
  }




