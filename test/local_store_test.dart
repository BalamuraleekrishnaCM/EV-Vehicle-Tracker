import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ev_vehicle_tracker/data/local_store.dart';
import 'package:ev_vehicle_tracker/domain/ownership_record.dart';
import 'package:ev_vehicle_tracker/domain/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

void main() {
  const vehicle = EvVehicle(
    type: VehicleType.scooter,
    brand: 'Ather',
    model: 'Rizta',
    batteryKwh: 3,
  );
  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }
  sqfliteFfiInit();
  final factory = createDatabaseFactoryFfi(noIsolate: true);

  test('v1 migration preserves vehicles and legacy records', () async {
    final directory = await Directory.systemTemp.createTemp('ev-db-migration-');
    addTearDown(() => directory.delete(recursive: true));
    final dbPath = '${directory.path}/migration-test.db';
    final old = await LocalStore.open(dbPath, factory: factory, version: 1);
    await old.insert('vehicles', {
      'type': 'scooter',
      'brand': 'Ather',
      'model': 'Rizta',
      'battery_kwh': 3,
    });
    await old.insert('records', {
      'vehicle_id': 1,
      'category': 'charging',
      'title': 'Legacy',
      'created_at': '2026-01-01T00:00:00Z',
    });
    await old.close();
    final updated = await LocalStore.open(dbPath, factory: factory);
    addTearDown(() async {
      await updated.close();
      await factory.deleteDatabase(dbPath);
    });
    final store = LocalStore.forDatabase(updated);
    expect((await store.vehicles()).single.model, 'Rizta');
    final record = (await store.recordsFor(1)).single;
    expect(record.title, 'Legacy');
    expect(record.energyKwh, isNull);
    expect(record.paid, isTrue);
  });

  test(
    'monthly installments preserve month-end dates and start unpaid',
    () async {
      final database = await LocalStore.open(
        inMemoryDatabasePath,
        factory: factory,
      );
      addTearDown(database.close);
      final store = LocalStore.forDatabase(database);
      final id = await store.addVehicle(vehicle);
      await store.addInstallments(
        OwnershipRecord(
          vehicleId: id,
          category: RecordCategory.finance,
          title: 'Vehicle EMI',
          amountMinor: 500000,
          createdAt: DateTime(2026, 1, 31),
          dueDate: DateTime(2026, 1, 31),
        ),
        3,
      );
      final records = await store.recordsFor(id);
      expect(
        records.every((record) => !record.paid && record.amountMinor == 500000),
        isTrue,
      );
      expect(records.reversed.map((record) => record.dueDate!.toLocal().day), [
        31,
        28,
        31,
      ]);
    },
  );

  test(
    'backup round-trips structured records and rejects a bad vehicle link',
    () async {
      final database = await LocalStore.open(
        inMemoryDatabasePath,
        factory: factory,
      );
      addTearDown(database.close);
      final store = LocalStore.forDatabase(database);
      final id = await store.addVehicle(vehicle);
      final id2 = await store.addVehicle(vehicle);
      await store.archiveVehicle(id2, true);
      await store.addRecord(
        OwnershipRecord(
          vehicleId: id,
          category: RecordCategory.trip,
          title: '=Test trip',
          amountMinor: 0,
          createdAt: DateTime.utc(2026),
          distanceKm: 25,
          energyKwh: 1.25,
        ),
      );
      final backup = await store.exportBackup();
      expect(await store.exportCsv(), contains("'=Test trip"));
      final invalid = jsonDecode(backup);
      invalid['records'][0]['vehicle_id'] = 812;
      await expectLater(
        store.restoreBackup(jsonEncode(invalid)),
        throwsFormatException,
      );
      expect((await store.recordsFor(id)).single.whPerKm, 50);
      await store.deleteVehicle(id);
      expect(await store.records(), isEmpty);
      await store.restoreBackup(backup);
      expect((await store.recordsFor(id)).single.whPerKm, 50);
      expect((await store.vehicles()).last.archived, isTrue);
      expect(await store.recordsFor(id2), isEmpty);
    },
  );
}
