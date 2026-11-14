import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/vehicle.dart';
import '../domain/ownership_record.dart';

class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    _db = await openDatabase(
      p.join(root, 'ev_vehicle_tracker.db'),
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK(type IN ('car', 'scooter')),
            brand TEXT NOT NULL,
            model TEXT NOT NULL,
            battery_kwh REAL NOT NULL CHECK(battery_kwh > 0),
            odometer_km REAL NOT NULL DEFAULT 0 CHECK(odometer_km >= 0)
          )
        ''');
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            amount_minor INTEGER NOT NULL DEFAULT 0 CHECK(amount_minor >= 0),
            created_at TEXT NOT NULL,
            odometer_km REAL,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('CREATE INDEX records_vehicle_date ON records(vehicle_id, created_at DESC)');
      },
    );
    return _db!;
  }

  Future<List<EvVehicle>> vehicles() async => (await (await database)
          .query('vehicles', orderBy: 'id DESC'))
      .map(EvVehicle.fromMap)
      .toList();

  Future<int> addVehicle(EvVehicle vehicle) async {
    if (vehicle.brand.trim().isEmpty || vehicle.model.trim().isEmpty ||
        vehicle.batteryKwh <= 0 || vehicle.odometerKm < 0) {
      throw const FormatException('Invalid vehicle');
    }
    final map = vehicle.toMap()..remove('id');
    return (await database).insert('vehicles', map);
  }

  Future<List<OwnershipRecord>> recordsFor(int vehicleId) async =>
      (await (await database).query(
        'records',
        where: 'vehicle_id = ?',
        whereArgs: [vehicleId],
        orderBy: 'created_at DESC, id DESC',
      ))
          .map(OwnershipRecord.fromMap)
          .toList();

  Future<int> addRecord(OwnershipRecord record) async {
    if (record.title.trim().isEmpty || record.amountMinor < 0 ||
        (record.odometerKm != null && record.odometerKm! < 0)) {
      throw const FormatException('Invalid record');
    }
    final map = record.toMap()..remove('id');
    return (await database).insert('records', map);
  }

  Future<void> deleteRecord(int id, int vehicleId) async {
    await (await database).delete(
      'records',
      where: 'id = ? AND vehicle_id = ?',
      whereArgs: [id, vehicleId],
    );
  }
}
