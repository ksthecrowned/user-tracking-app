import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:user_tacking_app/database_helper.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'dart:async';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  bool isTracking = false;
  List<Point> trackPoints = [];
  List<List<Point>> trackHistory = [];
  List<MapObject<dynamic>> mapObjects = [];
  Point? currentPosition;
  YandexMapController? mapController;
  StreamSubscription<Position>? positionStream;
  double totalDistance = 0.0;
  double trackTime = 0.0;
  Placemark place = Placemark();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> getTrackHistory() async {
    List<List<Point>> history = await DatabaseHelper().getTrackHistory();
    setState(() {
      trackHistory = history;
    });
  }

  Future<void> getAddressFromLatLng() async {
    if (currentPosition != null) {
      try {
        await setLocaleIdentifier("fr");
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );

        setState(() {
          place = placemarks[0];
        });
      } catch (e) {
        print("Erreur lors de la récupération de l'adresse : $e");
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    // Get initial position
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = Point(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });

      await getTrackHistory();
      await getAddressFromLatLng();
      print("History--------------: $trackHistory");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _toggleTracking() {
    setState(() {
      isTracking = !isTracking;
    });

    if (isTracking) {
      _startTracking();
    } else {
      _stopTracking();
    }
  }

  void _startTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        currentPosition = Point(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        trackPoints.add(currentPosition!);

        // Calcul de la distance parcourue
        if (trackPoints.length > 1 && isTracking) {
          totalDistance += Geolocator.distanceBetween(
            trackPoints[trackPoints.length - 2].latitude,
            trackPoints[trackPoints.length - 2].longitude,
            currentPosition!.latitude,
            currentPosition!.longitude,
          ) / 1000;
        }

        _updateMapObjects();
      });
    });
  }

  void _stopTracking() async {
    positionStream?.cancel();
    if(trackPoints.length > 1) {
      await DatabaseHelper().insertTrack(trackPoints); 
    }
    trackPoints = []; 
  }

  void _updateMapObjects() async {
    if (mapController != null && currentPosition != null) {
      mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition!,
            zoom: 16,
          ),
        ),
      );
    }

    await getTrackHistory();
    await getAddressFromLatLng();
    print("History--------------: $trackHistory");

    setState(() {
      mapObjects = [
        PlacemarkMapObject(
          mapId: const MapObjectId('current_location'),
          point: currentPosition!,
          opacity: 1.0,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/Pin_current_location.png'),
              anchor: Offset(0.5, 1.0),
              scale: 3.0,
              zIndex: 100,
            ),
          ),
        ),
        if (trackPoints.length >= 2)
          PolylineMapObject(
            mapId: MapObjectId('track_${DateTime.now().millisecondsSinceEpoch}'), // ID unique
            polyline: Polyline(points: List.from(trackPoints)), // Créer une nouvelle liste
            strokeColor: Colors.deepPurple[700]!,
            strokeWidth: 3,
          ),
          // Marqueur au début du trajet
          if (trackPoints.isNotEmpty)
            PlacemarkMapObject(
              mapId: const MapObjectId('start_marker'),
              point: trackPoints.first, // Première position du trajet
              opacity: 1.0,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage('assets/start_marker.png'),
                  scale: 0.25,
                  anchor: Offset(0.5, 1.0),
                ),
              ),
            ),
        for (var track in trackHistory) 
          if (track.length >= 2) 
            ...[
              // Ajouter la polyline
              PolylineMapObject(
                mapId: MapObjectId('track_${trackHistory.indexOf(track)}'),
                polyline: Polyline(points: track),
                strokeColor: Colors.grey,
                strokeWidth: 3,
              ),
              // Ajouter le marqueur au début du trajet
              PlacemarkMapObject(
                mapId: MapObjectId('start_marker_${trackHistory.indexOf(track)}'),
                point: track.first,  // Première position du trajet
                // opacity: 1.0,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/location_pin.png'),
                    scale: 0.25,
                    anchor: Offset(0.5, 1.0),
                  ),
                ),
              ),
              // Ajouter le marqueur à la fin du trajet
              PlacemarkMapObject(
                mapId: MapObjectId('end_marker_${trackHistory.indexOf(track)}'),
                point: track.last,  // Dernière position du trajet
                // opacity: 1.0,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/location_pin.png'),
                    scale: 0.25,
                    anchor: Offset(0.5, 1.0),
                  ),
                ),
              ),
            ]
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Yandex
          currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : YandexMap(
                  onMapCreated: (YandexMapController controller) {
                    mapController = controller;
                    controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: currentPosition!,
                          zoom: 16,
                        ),
                      ),
                    );
                  },
                  mapObjects: mapObjects.length > 0 ? mapObjects : [
                    if (currentPosition != null)
                      PlacemarkMapObject(
                        mapId: const MapObjectId('current_location'),
                        point: currentPosition!,
                        opacity: 1.0,
                        icon: PlacemarkIcon.single(
                          PlacemarkIconStyle(
                            image: BitmapDescriptor.fromAssetImage(
                                'assets/Pin_current_location.png'),
                            scale: 3.0,
                            anchor: Offset(0.5, 1.0),
                            zIndex: 100,
                          ),
                        ),
                      ),
                    if (trackPoints.length >= 2)
                      PolylineMapObject(
                        mapId: const MapObjectId('track'),
                        polyline: Polyline(points: trackPoints),
                        strokeColor: Colors.blue[700]!,
                        strokeWidth: 3,
                      ),
                    for (var track in trackHistory) 
                      if (track.length >= 2) 
                        ...[
                          // Ajouter la polyline
                          PolylineMapObject(
                            mapId: MapObjectId('track_${trackHistory.indexOf(track)}'),
                            polyline: Polyline(points: track),
                            strokeColor: Colors.grey,
                            strokeWidth: 3,
                          ),
                          // Ajouter le marqueur au début du trajet
                          PlacemarkMapObject(
                            mapId: MapObjectId('start_marker_${trackHistory.indexOf(track)}'),
                            point: track.first,  // Première position du trajet
                            // opacity: 1.0,
                            icon: PlacemarkIcon.single(
                              PlacemarkIconStyle(
                                image: BitmapDescriptor.fromAssetImage('assets/location_pin.png'),
                                scale: 0.25,
                                anchor: Offset(0.5, 1.0),
                              ),
                            ),
                          ),
                          // Ajouter le marqueur à la fin du trajet
                          PlacemarkMapObject(
                            mapId: MapObjectId('end_marker_${trackHistory.indexOf(track)}'),
                            point: track.last,  // Dernière position du trajet
                            // opacity: 1.0,
                            icon: PlacemarkIcon.single(
                              PlacemarkIconStyle(
                                image: BitmapDescriptor.fromAssetImage('assets/location_pin.png'),
                                scale: 0.25,
                                anchor: Offset(0.5, 1.0),
                              ),
                            ),
                          ),
                        ]
                  ],
                  // mapObjects: mapObjects,
                ),

          Positioned(
            bottom: 120,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    spreadRadius: 10,
                  )
                ]
              ),
              child: IconButton(
                iconSize: 40,
                icon: Icon(
                  isTracking ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: _toggleTracking,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(
                right: 16,
                left: 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    spreadRadius: 10,
                  )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/Avatar.png'), // Remplace par ton image
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${place.locality ?? '- '}, ${place.country ?? '-'}", // ${place.street},
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Distance traquée: ${totalDistance.toStringAsFixed(2)} km",
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}