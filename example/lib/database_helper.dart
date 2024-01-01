import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {

  static final DatabaseHelper _instance = DatabaseHelper._internal();
factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

   Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }


   Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'location.db');
    return openDatabase(path, version: 1, onCreate: _createDatabase);
  }

 Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
        CREATE TABLE locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        placeName TEXT
       )
    ''');
  }



//  formattedtimestamp TEXT,
//         placeName TEXT
 Future<int> insertLocation(double latitude, double longitude, String placeName) async { // String timestamp,String placeName
    final db = await database;
    return await db.insert('locations', {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName
      //'formattedtimestamp': timestamp,
      
    });
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('locations');
  }

  Future<void> removeAllLocations() async {
  final db = await database;
  await db.delete('locations');
}
}