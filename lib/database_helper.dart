import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class DatabaseHelper {
  static Database? _database;

  static const String tableName = "trackHistory";
  static const String columnId = "id";
  static const String columnTrack = "track"; // Stockera la liste des points sous forme JSON

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDB();
      return _database!;
    }
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), '_track_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table des itinéraires (trackHistory)
        await db.execute('''
          CREATE TABLE trackHistory (
            id INTEGER PRIMARY KEY AUTOINCREMENT
          )
        ''');

        // Table des points de suivi (trackPoints)
        await db.execute('''
          CREATE TABLE trackPoints (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idTrack INTEGER,
            latitude REAL,
            longitude REAL,
            FOREIGN KEY (idTrack) REFERENCES trackHistory(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }


  // Insère une liste de points en une seule ligne (après suppression des anciennes données)
  Future<void> insertTrack(List<Point> trackPoints) async {
    final db = await database;

    // Insérer un nouvel itinéraire vide et récupérer son ID
    int idTrack = await db.insert('trackHistory', {}, nullColumnHack: 'id');

    // Vérifier si on a bien un ID valide
    if (idTrack > 0) {
      Batch batch = db.batch();
      for (var point in trackPoints) {
        batch.insert('trackPoints', {
          'idTrack': idTrack,
          'latitude': point.latitude,
          'longitude': point.longitude,
        });
      }
      await batch.commit();
    }
  }


  // Récupère toutes les traces sous forme de List<List<Point>>
  Future<List<List<Point>>> getTrackHistory() async {
    final db = await database;

    // Récupérer tous les tracks
    final List<Map<String, dynamic>> tracks = await db.query('trackHistory');

    List<List<Point>> trackHistory = [];
    for (var track in tracks) {
      int idTrack = track['id'];

      // Récupérer tous les points associés à ce track
      final List<Map<String, dynamic>> points = await db.query(
        'trackPoints',
        where: 'idTrack = ?',
        whereArgs: [idTrack],
      );

      List<Point> trackPoints = points.map((p) => Point(latitude: p['latitude'], longitude: p['longitude'])).toList();
      trackHistory.add(trackPoints);
    }

    return trackHistory;
  }

  // Supprime toutes les traces
  Future<void> deleteAllTracks() async {
    final db = await database;
    await db.delete(tableName);
  }
}
