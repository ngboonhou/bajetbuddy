import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/receipt_data.dart';

class SqfliteHistoryService {
  static const _dbName = 'receipt_history.db';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        receipt_id TEXT PRIMARY KEY,
        store_name TEXT,
        transaction_date TEXT,
        total REAL,
        sst REAL,
        service_tax REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id TEXT,
        quantity INTEGER,
        item_name TEXT,
        price REAL,
        FOREIGN KEY (receipt_id) REFERENCES receipts (receipt_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> saveReceipt(ReceiptData receipt) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('receipts', receipt.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await txn
          .delete('line_items', where: 'receipt_id = ?', whereArgs: [receipt.receiptId]);

      for (final item in receipt.lineItems) {
         await txn.insert('line_items', {
          'receipt_id': receipt.receiptId,
          'quantity': item.quantity,
          'item_name': item.itemName,
          'price': item.price,
        });
      }
    });
  }

  Future<List<ReceiptData>> loadReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> receiptMaps =
        await db.query('receipts', orderBy: 'transaction_date DESC');
    final List<ReceiptData> receipts = [];
    for (final receiptMap in receiptMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'line_items',
        where: 'receipt_id = ?',
        whereArgs: [receiptMap['receipt_id']],
      );
      final lineItems = itemMaps
          .map((itemMap) => LineItem(
                quantity: itemMap['quantity'],
                itemName: itemMap['item_name'],
                price: itemMap['price'],
              ))
          .toList();
      receipts.add(ReceiptData(
        receiptId: receiptMap['receipt_id'],
        storeName: receiptMap['store_name'],
        transactionDate: receiptMap['transaction_date'],
        total: receiptMap['total'],
        sst: receiptMap['sst'],
        serviceTax: receiptMap['service_tax'],
        lineItems: lineItems,
      ));
    }
    return receipts;
  }

  Future<void> deleteReceipt(String receiptId) async {
    final db = await database;
    await db.delete('receipts', where: 'receipt_id = ?', whereArgs: [receiptId]);
  }

  Future<void> deleteAllReceipts() async {
    final db = await database;
    await db.delete('receipts');
    await db.delete('line_items');
  }
}