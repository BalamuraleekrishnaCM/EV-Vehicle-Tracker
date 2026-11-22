import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/vehicle.dart';
import '../domain/ownership_record.dart';

class LocalStore {
  LocalStore._();
  LocalStore.forDatabase(Database database) : _db = database;
  static final instance = LocalStore._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    return _db = await open(p.join(root, 'ev_vehicle_tracker.db'));
  }

  static Future<Database> open(
    String path, {
    DatabaseFactory? factory,
    int version = 2,
  }) {
    return (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
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
          await db.execute(
            'CREATE INDEX records_vehicle_date ON records(vehicle_id, created_at DESC)',
          );
          await _migrate(db, 1, version);
        },
        onUpgrade: _migrate,
      ),
    );
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from >= 2 || to < 2) return;
    for (final definition in [
      "variant TEXT NOT NULL DEFAULT ''",
      "connector TEXT NOT NULL DEFAULT ''",
      'archived INTEGER NOT NULL DEFAULT 0',
    ]) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN $definition');
    }
    for (final definition in [
      'energy_kwh REAL',
      'distance_km REAL',
      'start_soc REAL',
      'end_soc REAL',
      'tariff REAL',
      'minutes REAL',
      "detail TEXT NOT NULL DEFAULT ''",
      'due_date TEXT',
      'paid INTEGER NOT NULL DEFAULT 1',
    ]) {
      await db.execute('ALTER TABLE records ADD COLUMN $definition');
    }
  }

  Future<List<EvVehicle>> vehicles() async => (await (await database).query(
    'vehicles',
    orderBy: 'archived, id DESC',
  )).map(EvVehicle.fromMap).toList();

  Future<int> addVehicle(EvVehicle vehicle) async {
    vehicle.validate();
    return (await database).insert('vehicles', vehicle.toMap()..remove('id'));
  }

  Future<void> updateVehicle(EvVehicle vehicle) async {
    vehicle.validate();
    await (await database).update(
      'vehicles',
      vehicle.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> archiveVehicle(int id, bool archived) async {
    await (await database).update(
      'vehicles',
      {'archived': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVehicle(int id) async {
    await (await database).delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<OwnershipRecord>> records({int? vehicleId}) async =>
      (await (await database).query(
        'records',
        where: vehicleId == null ? null : 'vehicle_id = ?',
        whereArgs: vehicleId == null ? null : [vehicleId],
        orderBy: 'created_at DESC, id DESC',
      )).map(OwnershipRecord.fromMap).toList();

  Future<(List<EvVehicle>, List<OwnershipRecord>)> ownershipSnapshot() async =>
      (await database).transaction((txn) async {
        final vehicles = await txn.query(
          'vehicles',
          orderBy: 'archived, id DESC',
        );
        final records = await txn.query(
          'records',
          orderBy: 'created_at DESC, id DESC',
        );
        return (
          vehicles.map(EvVehicle.fromMap).toList(),
          records.map(OwnershipRecord.fromMap).toList(),
        );
      });

  Future<List<OwnershipRecord>> recordsFor(int vehicleId) =>
      records(vehicleId: vehicleId);

  Future<int> addRecord(OwnershipRecord record) async {
    record.validate();
    return (await database).insert('records', record.toMap()..remove('id'));
  }

  Future<void> addInstallments(OwnershipRecord first, int count) async {
    first.validate();
    final due = first.dueDate?.toLocal();
    if (first.category != RecordCategory.finance ||
        due == null ||
        first.amountMinor == 0 ||
        count < 2 ||
        count > 120) {
      throw const FormatException(
        'Enter a positive installment, first due date and 2–120 monthly payments.',
      );
    }
    await (await database).transaction((txn) async {
      for (var offset = 0; offset < count; offset++) {
        final month = DateTime(due.year, due.month + offset);
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        final day = due.day <= lastDay ? due.day : lastDay;
        final row = first.toMap()
          ..remove('id')
          ..['title'] = '${first.title} (${offset + 1}/$count)'
          ..['paid'] = 0
          ..['due_date'] = DateTime(
            month.year,
            month.month,
            day,
          ).toUtc().toIso8601String();
        await txn.insert('records', row);
      }
    });
  }

  Future<void> updateRecord(OwnershipRecord record) async {
    record.validate();
    await (await database).update(
      'records',
      record.toMap()..remove('id'),
      where: 'id = ? AND vehicle_id = ?',
      whereArgs: [record.id, record.vehicleId],
    );
  }

  Future<void> deleteRecord(int id, int vehicleId) async {
    await (await database).delete(
      'records',
      where: 'id = ? AND vehicle_id = ?',
      whereArgs: [id, vehicleId],
    );
  }

  Future<String> exportBackup() async =>
      (await database).transaction((txn) async {
        return jsonEncode({
          'version': 1,
          'vehicles': await txn.query('vehicles', orderBy: 'id'),
          'records': await txn.query('records', orderBy: 'id'),
        });
      });

  Future<void> restoreBackup(String contents) async {
    final decoded = jsonDecode(contents);
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['vehicles'] is! List ||
        decoded['records'] is! List) {
      throw const FormatException('Unsupported backup format.');
    }
    final vehicles = <int, EvVehicle>{};
    final records = <int, OwnershipRecord>{};
    try {
      for (final row in decoded['vehicles'] as List) {
        final vehicle = EvVehicle.fromMap(
          Map<String, Object?>.from(row as Map),
        );
        vehicle.validate();
        final id = vehicle.id;
        if (id == null || id <= 0 || vehicles.containsKey(id)) {
          throw const FormatException('Invalid or duplicate vehicle ID.');
        }
        vehicles[id] = vehicle;
      }
      for (final row in decoded['records'] as List) {
        final record = OwnershipRecord.fromMap(
          Map<String, Object?>.from(row as Map),
        );
        record.validate();
        final id = record.id;
        if (id == null ||
            id <= 0 ||
            records.containsKey(id) ||
            !vehicles.containsKey(record.vehicleId)) {
          throw const FormatException('Invalid record ID or vehicle link.');
        }
        records[id] = record;
      }
    } on TypeError {
      throw const FormatException('The backup contains invalid fields.');
    } on ArgumentError {
      throw const FormatException(
        'The backup contains an unknown vehicle or record type.',
      );
    }
    await (await database).transaction((txn) async {
      await txn.delete('records');
      await txn.delete('vehicles');
      for (final vehicle in vehicles.values) {
        await txn.insert('vehicles', vehicle.toMap());
      }
      for (final record in records.values) {
        await txn.insert('records', record.toMap());
      }
    });
  }

  Future<String> exportCsv() async => (await database).transaction((txn) async {
    final vehicles = {
      for (final row in await txn.query('vehicles')) row['id']: row,
    };
    final rows = await txn.query('records', orderBy: 'created_at, id');
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (value is String && RegExp(r"^\s*[=+@-]|^[\r\n\t]").hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    final output = StringBuffer(
      'vehicle_id,vehicle,category,title,amount_inr,date,paid,odometer_km,distance_km,energy_kwh,detail,due_date,notes\r\n',
    );
    for (final row in rows) {
      final vehicle = vehicles[row['vehicle_id']]!;
      output.write(
        [
          row['vehicle_id'],
          "${vehicle['brand']} ${vehicle['model']}",
          row['category'],
          row['title'],
          ((row['amount_minor'] as int) / 100).toStringAsFixed(2),
          row['created_at'],
          row['paid'],
          row['odometer_km'],
          row['distance_km'],
          row['energy_kwh'],
          row['detail'],
          row['due_date'],
          row['notes'],
        ].map(cell).join(','),
      );
      output.write('\r\n');
    }
    return output.toString();
  });
}
