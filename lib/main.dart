import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:user_tacking_app/location_tracker_screen.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Modifier la couleur de la barre de navigation (en bas)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white, // Couleur de fond
    systemNavigationBarIconBrightness: Brightness.dark, // Icônes claires ou sombres
    systemNavigationBarDividerColor: Colors.transparent, // Bordure si applicable
  ));

  AndroidYandexMap.useAndroidViewSurface = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // home: const LocationTrackerScreen(),
      home: AnimatedSplashScreen(
        splash: Center(
          child: Lottie.asset('assets/Animation-1739066636266.json')
        ),
        nextScreen: const LocationTrackerScreen(),
        splashIconSize: 300,
        backgroundColor: Colors.white,
        duration: 0,
      )
    );
  }
}