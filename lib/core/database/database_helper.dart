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
    ...xelSteamAssets,
  ];

  DatabaseHelper._init();

  static const Set<String> _validItemColumns = {
    'id',
    'name',
    'category',
    'purchase_price',
    'current_valuation',
    'purchase_date',
    'warranty_expiry_date',
    'serial_number',
    'image_url',
    'is_collectible',
    'is_marketable',
    'market_hash_name',
    'blockchain_hash',
  };

  Map<String, dynamic> _sanitizeItemForDb(Map<String, dynamic> item) {
    final clean = <String, dynamic>{};
    for (var entry in item.entries) {
      if (_validItemColumns.contains(entry.key)) {
        clean[entry.key] = entry.value;
      }
    }
    return clean;
  }

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE items ADD COLUMN is_marketable INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE items ADD COLUMN market_hash_name TEXT');
          } catch (_) {}
        }
      },
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
        is_marketable INTEGER NOT NULL DEFAULT 0,
        market_hash_name TEXT,
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
      await db.insert('items', _sanitizeItemForDb(item));
    }
  }

  Future<Map<String, dynamic>?> authenticateUser(String username, String rawPassword) async {
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = rawPassword.trim();

    if (kIsWeb) {
      if (cleanUser == 'azzaky' && cleanPass == 'admin123') {
        return {
          'id': 1,
          'username': 'azzaky',
          'full_name': 'Azzaky Raihan',
        };
      }
      return null;
    }

    try {
      final db = await database;
      if (db == null) {
        if (cleanUser == 'azzaky' && cleanPass == 'admin123') {
          return {'id': 1, 'username': 'azzaky', 'full_name': 'Azzaky Raihan'};
        }
        return null;
      }

      final hash = sha256.convert(utf8.encode(cleanPass)).toString();

      // Check if user table has any user, seed default demo user if empty
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
      if (count == 0) {
        final initialHash = sha256.convert(utf8.encode('admin123')).toString();
        await db.insert('users', {
          'username': 'azzaky',
          'password_hash': initialHash,
          'full_name': 'Azzaky Raihan',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      final results = await db.query(
        'users',
        where: 'LOWER(username) = ? AND password_hash = ?',
        whereArgs: [cleanUser, hash],
      );
      if (results.isNotEmpty) {
        return results.first;
      }

      // Safety fallback for demo user 'azzaky' / 'admin123'
      if (cleanUser == 'azzaky' && cleanPass == 'admin123') {
        try {
          final initialHash = sha256.convert(utf8.encode('admin123')).toString();
          await db.insert(
            'users',
            {
              'username': 'azzaky',
              'password_hash': initialHash,
              'full_name': 'Azzaky Raihan',
              'created_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
        return {
          'id': 1,
          'username': 'azzaky',
          'full_name': 'Azzaky Raihan',
        };
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Authentication notice: $e');
      if (cleanUser == 'azzaky' && cleanPass == 'admin123') {
        return {
          'id': 1,
          'username': 'azzaky',
          'full_name': 'Azzaky Raihan',
        };
      }
    }

    return null;
  }

  Future<bool> registerUser(String username, String rawPassword, {String? fullName}) async {
    if (kIsWeb) {
      return true;
    }
    final db = await database;
    if (db == null) return false;
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = rawPassword.trim();
    final hash = sha256.convert(utf8.encode(cleanPass)).toString();
    try {
      await db.insert('users', {
        'username': cleanUser,
        'password_hash': hash,
        'full_name': (fullName?.trim().isNotEmpty == true) ? fullName!.trim() : username.trim(),
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    if (kIsWeb) {
      return List.from(_webItems);
    }
    try {
      final db = await database;
      if (db == null) return List.from(_webItems);
      var items = await db.query('items', orderBy: 'id DESC');

      // Heal accidental bogus entries from previous broken parser (e.g. "masukkan laptop victus")
      try {
        await db.delete(
          'items',
          where: "name LIKE 'masukkan %' OR name LIKE 'tambahkan %' OR (name LIKE '%laptop victus%' AND current_valuation < 0.1)",
        );
        // Correct corrupted Hp Xiaomi 17 entry from previous regex bug
        await db.rawUpdate(
          "UPDATE items SET name = 'Hp Xiaomi 17', purchase_price = 18999000.0 / 15850.0, current_valuation = 18999000.0 / 15850.0 WHERE name LIKE '%Xiaomi 17%' AND (current_valuation < 100 OR name LIKE '%,000%')",
        );
        // Heal entries where 10% auto-depreciation was mistakenly applied upon initial entry
        await db.rawUpdate(
          "UPDATE items SET current_valuation = purchase_price WHERE purchase_price > 0 AND NOT category LIKE 'Steam%'",
        );
      } catch (_) {}
      if (!items.any((i) => i['category'].toString().startsWith('Steam'))) {
        for (var asset in xelSteamAssets) {
          await db.insert('items', _sanitizeItemForDb(asset));
        }
        items = await db.query('items', orderBy: 'id DESC');
      }
      return items;
    } catch (e) {
      debugPrint('[DatabaseHelper] getItems fallback: $e');
      return List.from(_webItems);
    }
  }

  Future<int> insertItem(Map<String, dynamic> item) async {
    if (kIsWeb) {
      _webItems.add(item);
      return _webItems.length;
    }
    try {
      final db = await database;
      if (db == null) {
        _webItems.add(item);
        return _webItems.length;
      }
      return await db.insert('items', _sanitizeItemForDb(item));
    } catch (e) {
      debugPrint('[DatabaseHelper] insertItem fallback: $e');
      _webItems.add(item);
      return _webItems.length;
    }
  }

  Future<void> removeMockItems() async {
    if (kIsWeb) {
      _webItems.removeWhere((i) =>
          i['name'] == 'AK-47 | Case Hardened (Tier 2 Blue Gem)' ||
          i['name'] == 'Butterfly Knife | Doppler (Phase 2)');
      return;
    }
    try {
      final db = await database;
      if (db == null) return;
      await db.delete('items',
          where: 'name IN (?, ?)',
          whereArgs: [
            'AK-47 | Case Hardened (Tier 2 Blue Gem)',
            'Butterfly Knife | Doppler (Phase 2)',
          ]);
    } catch (_) {
      _webItems.removeWhere((i) =>
          i['name'] == 'AK-47 | Case Hardened (Tier 2 Blue Gem)' ||
          i['name'] == 'Butterfly Knife | Doppler (Phase 2)');
    }
  }

  Future<void> replaceSteamItems(List<Map<String, dynamic>> newItems) async {
    if (kIsWeb) {
      _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
      _webItems.addAll(newItems);
      return;
    }
    try {
      final db = await database;
      if (db == null) {
        _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
        _webItems.addAll(newItems);
        return;
      }
      await db.delete('items', where: "category LIKE 'Steam%'");
      for (var item in newItems) {
        final insertMap = _sanitizeItemForDb(item);
        insertMap.remove('id');
        await db.insert('items', insertMap);
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] replaceSteamItems fallback: $e');
      _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
      _webItems.addAll(newItems);
    }
  }

  Future<void> clearSteamItems() async {
    _webItems.removeWhere((i) => i['category'].toString().startsWith('Steam'));
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.delete('items', where: "category LIKE 'Steam%'");
    } catch (_) {}
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

