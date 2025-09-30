import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/models/brewing_step.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Database? _database;
  
  final Map<String, Coffee> _coffeeCache = {};
  final Map<String, List<Brewing>> _brewingsCache = {};
  
  static const String _dbName = "flowstate.db";
  static const int _dbVersion = 1;

  static const String _coffeeTable = 'coffees';
  static const String _brewingTable = 'brewings';
  static const String _stepTable = 'brewing_steps';

  Future<void> initialize() async {
    if (_database != null) return;
    
    try {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _dbName);
      
      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDb,
        onUpgrade: _upgradeDb,
      );
      
      debugPrint('Database initialized at $path');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE $_coffeeTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          roaster TEXT,
          origin TEXT,
          flavorProfile TEXT,
          roastDate INTEGER,
          createdAt INTEGER NOT NULL,
          imageUrl TEXT
        )
      ''');
      
      await txn.execute('''
        CREATE TABLE $_brewingTable (
          id TEXT PRIMARY KEY,
          coffeeId TEXT NOT NULL,
          coffeeDose REAL NOT NULL,
          grindSetting TEXT NOT NULL,
          waterTemperature REAL NOT NULL,
          preInfusionTime INTEGER,
          preInfusionWater REAL,
          totalBrewTimeInSeconds INTEGER NOT NULL,
          rating INTEGER NOT NULL,
          notes TEXT,
          brewDate INTEGER NOT NULL,
          FOREIGN KEY (coffeeId) REFERENCES $_coffeeTable (id) ON DELETE CASCADE
        )
      ''');
      
      await txn.execute('''
        CREATE TABLE $_stepTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          brewingId TEXT NOT NULL,
          stepNumber INTEGER NOT NULL,
          waterAmount REAL NOT NULL,
          time INTEGER,
          FOREIGN KEY (brewingId) REFERENCES $_brewingTable (id) ON DELETE CASCADE
        )
      ''');
      
      debugPrint('Database tables created');
    });
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _coffeeCache.clear();
      _brewingsCache.clear();
      debugPrint('Database connection closed');
    }
  }

  Future<void> clearDatabase() async {
    final db = _database;
    if (db != null) {
      await db.transaction((txn) async {
        await txn.delete(_stepTable);
        await txn.delete(_brewingTable);
        await txn.delete(_coffeeTable);
      });
      _coffeeCache.clear();
      _brewingsCache.clear();
      notifyListeners();
      debugPrint('Database cleared');
    }
  }


  Future<List<Coffee>> getAllCoffees() async {
    try {
      final db = _database!;
      final List<Map<String, dynamic>> maps = await db.query(
        _coffeeTable,
        orderBy: 'createdAt DESC',
      );
      
      final coffees = List.generate(maps.length, (i) {
        final coffee = Coffee.fromMap(maps[i]);
        _coffeeCache[coffee.id] = coffee;
        return coffee;
      });
      
      return coffees;
    } catch (e) {
      debugPrint('Error getting all coffees: $e');
      rethrow;
    }
  }
  
  Future<Coffee> getCoffeeById(String id) async {
    if (_coffeeCache.containsKey(id)) {
      return _coffeeCache[id]!;
    }
    
    try {
      final db = _database!;
      final List<Map<String, dynamic>> maps = await db.query(
        _coffeeTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        throw Exception('Coffee with ID $id not found');
      }
      
      final coffee = Coffee.fromMap(maps.first);
      _coffeeCache[id] = coffee;
      return coffee;
    } catch (e) {
      debugPrint('Error getting coffee by ID $id: $e');
      rethrow;
    }
  }
  
  Future<Coffee> addCoffee(Coffee coffee) async {
    try {
      final db = _database!;
      final id = const Uuid().v4();
      final newCoffee = Coffee(
        id: id,
        name: coffee.name,
        roaster: coffee.roaster,
        origin: coffee.origin,
        flavorProfile: coffee.flavorProfile,
        roastDate: coffee.roastDate,
        createdAt: DateTime.now(),
        imageUrl: coffee.imageUrl,
      );
      
      await db.insert(_coffeeTable, newCoffee.toMap());
      
      _coffeeCache[id] = newCoffee;
      notifyListeners();
      return newCoffee;
    } catch (e) {
      debugPrint('Error adding coffee: $e');
      rethrow;
    }
  }
  
  Future<void> updateCoffee(Coffee coffee) async {
    try {
      final db = _database!;
      await db.update(
        _coffeeTable,
        coffee.toMap(),
        where: 'id = ?',
        whereArgs: [coffee.id],
      );
      
      _coffeeCache[coffee.id] = coffee;
      
      _brewingsCache.remove(coffee.id);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating coffee ${coffee.id}: $e');
      rethrow;
    }
  }
  
  Future<void> deleteCoffee(String id) async {
    try {
      final db = _database!;
      await db.transaction((txn) async {
        await txn.delete(
          _coffeeTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      
      _coffeeCache.remove(id);
      _brewingsCache.remove(id);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting coffee $id: $e');
      rethrow;
    }
  }


  Future<List<Brewing>> getBrewingsForCoffee(String coffeeId) async {
    if (_brewingsCache.containsKey(coffeeId)) {
      return _brewingsCache[coffeeId]!;
    }
    
    try {
      final db = _database!;
      
      return await db.transaction((txn) async {
        final List<Map<String, dynamic>> brewingMaps = await txn.query(
          _brewingTable,
          where: 'coffeeId = ?',
          whereArgs: [coffeeId],
          orderBy: 'brewDate DESC',
        );
        
        final brewings = <Brewing>[];
        
        for (var brewingMap in brewingMaps) {
          final brewingId = brewingMap['id'] as String;
          final List<Map<String, dynamic>> stepMaps = await txn.query(
            _stepTable,
            where: 'brewingId = ?',
            whereArgs: [brewingId],
            orderBy: 'stepNumber ASC',
          );
          
          final steps = stepMaps.map((stepMap) => BrewingStep(
            stepNumber: stepMap['stepNumber'] as int,
            waterAmount: stepMap['waterAmount'] as double,
            time: stepMap['time'] as int?,
          )).toList();
          
          final brewing = Brewing.fromMap({
            ...brewingMap,
            'steps': steps.map((step) => step.toMap()).toList(),
          });
          
          brewings.add(brewing);
        }
        
        _brewingsCache[coffeeId] = brewings;
        
        return brewings;
      });
    } catch (e) {
      debugPrint('Error getting brewings for coffee $coffeeId: $e');
      rethrow;
    }
  }
  
  Future<Brewing> addBrewing(Brewing brewing) async {
    try {
      final db = _database!;
      
      final id = const Uuid().v4();
      final newBrewing = Brewing(
        id: id,
        coffeeId: brewing.coffeeId,
        coffeeDose: brewing.coffeeDose,
        grindSetting: brewing.grindSetting,
        waterTemperature: brewing.waterTemperature,
        preInfusionTime: brewing.preInfusionTime,
        preInfusionWater: brewing.preInfusionWater,
        totalBrewTime: brewing.totalBrewTime,
        steps: brewing.steps,
        rating: brewing.rating,
        notes: brewing.notes,
        brewDate: brewing.brewDate,
      );
      
      await db.transaction((txn) async {
        await txn.insert(_brewingTable, {
          'id': newBrewing.id,
          'coffeeId': newBrewing.coffeeId,
          'coffeeDose': newBrewing.coffeeDose,
          'grindSetting': newBrewing.grindSetting,
          'waterTemperature': newBrewing.waterTemperature,
          'preInfusionTime': newBrewing.preInfusionTime,
          'preInfusionWater': newBrewing.preInfusionWater,
          'totalBrewTimeInSeconds': newBrewing.totalBrewTime.inSeconds,
          'rating': newBrewing.rating,
          'notes': newBrewing.notes,
          'brewDate': newBrewing.brewDate.millisecondsSinceEpoch,
        });
        
        for (var step in newBrewing.steps) {
          await txn.insert(_stepTable, {
            'brewingId': newBrewing.id,
            'stepNumber': step.stepNumber,
            'waterAmount': step.waterAmount,
            'time': step.time,
          });
        }
      });
      
      _brewingsCache.remove(brewing.coffeeId);
      
      notifyListeners();
      return newBrewing;
    } catch (e) {
      debugPrint('Error adding brewing: $e');
      rethrow;
    }
  }
  
  Future<void> updateBrewing(Brewing brewing) async {
    try {
      final db = _database!;
      
      await db.transaction((txn) async {
        await txn.update(
          _brewingTable,
          {
            'coffeeDose': brewing.coffeeDose,
            'grindSetting': brewing.grindSetting,
            'waterTemperature': brewing.waterTemperature,
            'preInfusionTime': brewing.preInfusionTime,
            'preInfusionWater': brewing.preInfusionWater,
            'totalBrewTimeInSeconds': brewing.totalBrewTime.inSeconds,
            'rating': brewing.rating,
            'notes': brewing.notes,
            'brewDate': brewing.brewDate.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [brewing.id],
        );
        
        await txn.delete(
          _stepTable,
          where: 'brewingId = ?',
          whereArgs: [brewing.id],
        );
        
        for (var step in brewing.steps) {
          await txn.insert(_stepTable, {
            'brewingId': brewing.id,
            'stepNumber': step.stepNumber,
            'waterAmount': step.waterAmount,
            'time': step.time,
          });
        }
      });
      
      _brewingsCache.remove(brewing.coffeeId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating brewing ${brewing.id}: $e');
      rethrow;
    }
  }
  
  Future<void> deleteBrewing(String id, String coffeeId) async {
    try {
      final db = _database!;
      
      await db.delete(
        _brewingTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      _brewingsCache.remove(coffeeId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting brewing $id: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getCoffeeStats(String coffeeId) async {
    try {
      final db = _database!;
      
      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as brewCount,
          AVG(rating) as avgRating,
          MIN(brewDate) as firstBrew,
          MAX(brewDate) as lastBrew
        FROM $_brewingTable
        WHERE coffeeId = ?
      ''', [coffeeId]);
      
      if (results.isEmpty) {
        return {
          'brewCount': 0,
          'avgRating': 0.0,
          'firstBrew': null,
          'lastBrew': null,
        };
      }
      
      return {
        'brewCount': results.first['brewCount'] as int,
        'avgRating': (results.first['avgRating'] as num?)?.toDouble() ?? 0.0,
        'firstBrew': results.first['firstBrew'] != null ? 
            DateTime.fromMillisecondsSinceEpoch(results.first['firstBrew'] as int) : null,
        'lastBrew': results.first['lastBrew'] != null ?
            DateTime.fromMillisecondsSinceEpoch(results.first['lastBrew'] as int) : null,
      };
    } catch (e) {
      debugPrint('Error getting stats for coffee $coffeeId: $e');
      rethrow;
    }
  }
}