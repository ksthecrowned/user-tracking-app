// lib/database_helper.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static const String tableName = "trackHistory";
  static const String columnId = "id";
  static const String columnLatitude = "latitude";
  static const String columnLongitude = "longitude";
  static const String columnTimestamp = "timestamp";

  // Crée la base de données
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDB();
      return _database!;
    }
  }

  Future<Database> _initDB() async {
    // Récupérer le répertoire de l'application pour stocker la base de données
    String path = join(await getDatabasesPath(), 'track_history.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE $tableName (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnLatitude REAL,
            $columnLongitude REAL,
            $columnTimestamp TEXT
          )
        ''');
      },
    );
  }

  // Insère un point de suivi dans la base de données
  Future<void> insertTrackPoint(double latitude, double longitude, String timestamp) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        columnLatitude: latitude,
        columnLongitude: longitude,
        columnTimestamp: timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insérer une liste de points de suivi
  Future<void> insertTrackPoints(List<Map<String, dynamic>> trackPoints) async {
    final db = await database;
    // Utiliser un batch pour insérer plusieurs points à la fois
    Batch batch = db.batch();
    for (var point in trackPoints) {
      batch.insert(
        tableName,
        {
          columnLatitude: point['latitude'],
          columnLongitude: point['longitude'],
          columnTimestamp: point['timestamp'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  // Récupère tous les points de suivi
  Future<List<Map<String, dynamic>>> getTrackHistory() async {
    final db = await database;
    return await db.query(tableName);
  }

  // Supprimer tous les points de suivi
  Future<void> deleteAllTrackPoints() async {
    final db = await database;
    await db.delete(tableName);
  }
}
