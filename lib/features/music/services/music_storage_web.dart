import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> saveToIndexedDB(String key, String value) async {
  try {
    final idb = html.window.indexedDB;
    if (idb == null) return;

    final db = await idb.open(
      'MaatrivaMusicDB',
      version: 1,
      onUpgradeNeeded: (event) {
        final dynamic target = event.target;
        final dynamic upgradeDb = target.result;
        if (upgradeDb != null && !upgradeDb.objectStoreNames.contains('custom_songs')) {
          upgradeDb.createObjectStore('custom_songs');
        }
      },
    );

    final txn = db.transaction('custom_songs', 'readwrite');
    final store = txn.objectStore('custom_songs');
    store.put(value, key);
    await txn.completed;
    db.close();
  } catch (e) {
    debugPrint('[IndexedDB] Save exception: $e');
  }
}

Future<String?> loadFromIndexedDB(String key) async {
  try {
    final idb = html.window.indexedDB;
    if (idb == null) return null;

    final db = await idb.open(
      'MaatrivaMusicDB',
      version: 1,
      onUpgradeNeeded: (event) {
        final dynamic target = event.target;
        final dynamic upgradeDb = target.result;
        if (upgradeDb != null && !upgradeDb.objectStoreNames.contains('custom_songs')) {
          upgradeDb.createObjectStore('custom_songs');
        }
      },
    );

    final txn = db.transaction('custom_songs', 'readonly');
    final store = txn.objectStore('custom_songs');
    final result = await store.getObject(key);
    db.close();
    return result as String?;
  } catch (e) {
    debugPrint('[IndexedDB] Load exception: $e');
    return null;
  }
}
