import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:user_tacking_app/components/tracking_bottom_bar.dart';
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

  Future<void> getAddressFromLatLng() async {
  if (currentPosition != null) {
    try {
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

      await getAddressFromLatLng();
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
    print("trackHistory length ${trackHistory.length}");
    print("trackHistory ${trackHistory}");
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
          );
        }

        _updateMapObjects();
      });
    });
  }

  void _stopTracking() {
    positionStream?.cancel();
    trackHistory.add(trackPoints);
    trackPoints = [];
    print("trackHistory length ${trackHistory.length}");
    print("trackHistory ${trackHistory}"); 
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

    await getAddressFromLatLng();

    setState(() {
      mapObjects = [
        PlacemarkMapObject(
          mapId: const MapObjectId('current_location'),
          point: currentPosition!,
          opacity: 1.0,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/Pin_current_location.png'),
              scale: 3.0,
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
                  image: BitmapDescriptor.fromAssetImage('assets/start_marker.png'), // Remplacer par ton image
                  scale: 0.25,
                ),
              ),
            ),
        for (var track in trackHistory) 
          if (track.length >= 2) 
            ...[
              // Ajouter la polyline
              PolylineMapObject(
                mapId: MapObjectId('track_${trackHistory.indexOf(track)}'), // ID unique pour chaque itinéraire
                polyline: Polyline(points: track),  // Utiliser l'itinéraire correspondant
                strokeColor: Colors.grey,  // Couleur unique
                strokeWidth: 3,
              ),
              // Ajouter le marqueur au début du trajet
              PlacemarkMapObject(
                mapId: MapObjectId('start_marker_${trackHistory.indexOf(track)}'),
                point: track.first,  // Première position du trajet
                opacity: 1.0,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/start_marker.png'),
                    scale: 0.25,
                  ),
                ),
              ),
              // Ajouter le marqueur à la fin du trajet
              PlacemarkMapObject(
                mapId: MapObjectId('end_marker_${trackHistory.indexOf(track)}'),
                point: track.last,  // Dernière position du trajet
                opacity: 1.0,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/end_marker.png'),
                    scale: 0.25,
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
                  ],
                  // mapObjects: mapObjects,
                ),

          Positioned(
            top: 40,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8), 
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[400], 
                  borderRadius: BorderRadius.circular(8), 
                ),
                child: IconButton(
                  onPressed: () {
                    // Action du bouton
                  },
                  icon: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TrackingBottomBar(
        isTracking: isTracking,
        onToggleTracking: _toggleTracking,
        totalDistance: totalDistance / 1000,
        place: place,
      ),
    );
  }
}