import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../data/real_steam_assets.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web fallback in-memory cache
  final List<Map<String, dynamic>> _webItems = [
    {
      'id': 1,
      'name': 'Charizard ★ δ (Delta Species)',
      'category': 'Collectibles',
      'purchase_price': 21.00,
      'current_valuation': 27500.00,
      'purchase_date': '2019-04-12',
      'warranty_expiry_date': null,
      'serial_number': 'PSA-9-EX-DF-100',
      'image_url': 'https://images.pokemontcg.io/ex15/100_hires.png',
      'is_collectible': 1,
      'blockchain_hash': '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
    },
    ...xelSteamAssets,
  ];

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('vaulted.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        purchase_price REAL NOT NULL,
        current_valuation REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        warranty_expiry_date TEXT,
        serial_number TEXT,
        image_url TEXT,
        is_collectible INTEGER NOT NULL DEFAULT 0,
        blockchain_hash TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_name TEXT NOT NULL,
        cost REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        billing_cycle TEXT NOT NULL DEFAULT 'monthly',
        renewal_date TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    final initialPasswordHash = sha256.convert(utf8.encode('admin123')).toString();
    await db.insert('users', {
      'username': 'azzaky',
      'password_hash': initialPasswordHash,
      'full_name': 'Azzaky Raihan',
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var item in _webItems) {
      await db.insert('items', item);
    }
  }

  Future<Map<String, dynamic>?> authenticateUser(String username, String rawPassword) async {
    if (kIsWeb) {
      if (username == 'azzaky' && rawPassword == 'admin123') {
        return {
          'id': 1,
          'username': 'azzaky',
          'full_name': 'Azzaky Raihan',
        };
      }
      return null;
    }

    final db = await database;
    if (db == null) return null;
    final hash = sha256.convert(utf8.encode(rawPassword)).toString();
    final results = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hash],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<bool> registerUser(String username, String rawPassword, {String? fullName}) async {
    if (kIsWeb) {
      return true;
    }
    final db = await database;
    if (db == null) return false;
    final hash = sha256.convert(utf8.encode(rawPassword)).toString();
    try {
      await db.insert('users', {
        'username': username,
        'password_hash': hash,
        'full_name': fullName ?? username,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    if (kIsWeb) {
      return List.from(_webItems);
    }
    final db = await database;
    if (db == null) return [];
    var items = await db.query('items', orderBy: 'id DESC');
    if (!items.any((i) => i['category'].toString().startsWith('Steam'))) {
      for (var asset in xelSteamAssets) {
        await db.insert('items', Map<String, dynamic>.from(asset));
      }
      items = await db.query('items', orderBy: 'id DESC');
    }
    return items;
  }

  Future<int> insertItem(Map<String, dynamic> item) async {
    if (kIsWeb) {
      _webItems.add(item);
      return _webItems.length;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.insert('items', item);
  }

  Future<void> removeMockItems() async {
    if (kIsWeb) {
      _webItems.removeWhere((i) =>
          i['name'] == 'AK-47 | Case Hardened (Tier 2 Blue Gem)' ||
          i['name'] == 'Butterfly Knife | Doppler (Phase 2)');
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('items',
        where: 'name IN (?, ?)',
        whereArgs: [
          'AK-47 | Case Hardened (Tier 2 Blue Gem)',
          'Butterfly Knife | Doppler (Phase 2)',
        ]);
  }

  Future<void> replaceSteamItems(List<Map<String, dynamic>> newItems) async {
    if (kIsWeb) {
      _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
      _webItems.addAll(newItems);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('items', where: "category LIKE 'Steam%'");
    for (var item in newItems) {
      final insertMap = Map<String, dynamic>.from(item);
      insertMap.remove('id');
      await db.insert('items', insertMap);
    }
  }

  Future<void> clearSteamItems() async {
    if (kIsWeb) {
      _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('items', where: "category LIKE 'Steam%'");
  }

  final List<Map<String, dynamic>> _webSubscriptions = [
    {
      'id': 1,
      'service_name': 'ChatGPT Plus',
      'cost': 20.00,
      'currency': 'USD',
      'billing_cycle': 'monthly',
      'renewal_date': '2026-10-15',
      'category': 'AI & Productivity',
    },
    {
      'id': 2,
      'service_name': 'Netflix Premium 4K',
      'cost': 12.00,
      'currency': 'USD',
      'billing_cycle': 'monthly',
      'renewal_date': '2026-10-22',
      'category': 'Entertainment',
    },
    {
      'id': 3,
      'service_name': 'Spotify Family',
      'cost': 6.00,
      'currency': 'USD',
      'billing_cycle': 'monthly',
      'renewal_date': '2026-10-28',
      'category': 'Music Streaming',
    },
  ];

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    if (kIsWeb) {
      return List.from(_webSubscriptions);
    }
    final db = await database;
    if (db == null) return [];
    return await db.query('subscriptions', orderBy: 'id DESC');
  }

  Future<int> insertSubscription(Map<String, dynamic> sub) async {
    if (kIsWeb) {
      _webSubscriptions.add(sub);
      return _webSubscriptions.length;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.insert('subscriptions', sub);
  }
}

