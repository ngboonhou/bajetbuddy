import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/receipt_data.dart';
import '../services/database_service.dart';
import '../widgets/receipt_detail_view.dart';

enum SortOption { date, total, storeName }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SqfliteHistoryService _historyService = SqfliteHistoryService();
  List<ReceiptData> _allReceipts = [];
  List<ReceiptData> _displayReceipts = [];
  List<String> _storeNames = [];

  SortOption _currentSortOption = SortOption.date;
  bool _isSortAscending = false;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final loadedReceipts = await _historyService.loadReceipts();
    final uniqueStores = loadedReceipts
        .map((r) => r.storeName)
        .whereType<String>()
        .toSet()
        .toList();
    uniqueStores.sort();

    if (mounted) {
      setState(() {
        _allReceipts = loadedReceipts;
        _storeNames = uniqueStores;
        _sortAndFilterReceipts();
      });
    }
  }

  void _sortAndFilterReceipts() {
    List<ReceiptData> tempReceipts = List.from(_allReceipts);

    if (_selectedStore != null) {
      tempReceipts =
          tempReceipts.where((r) => r.storeName == _selectedStore).toList();
    }

    switch (_currentSortOption) {
      case SortOption.date:
        tempReceipts.sort((a, b) {
          final dateA = a.transactionDate ?? '';
          final dateB = b.transactionDate ?? '';
          return _isSortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
      case SortOption.total:
        tempReceipts.sort((a, b) {
          final totalA = a.total ?? 0.0;
          final totalB = b.total ?? 0.0;
          return _isSortAscending ? totalA.compareTo(totalB) : totalB.compareTo(totalA);
        });
        break;
      case SortOption.storeName:
        tempReceipts.sort((a, b) {
          final nameA = a.storeName ?? '';
          final nameB = b.storeName ?? '';
          return _isSortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });
        break;
    }

    setState(() {
      _displayReceipts = tempReceipts;
    });
  }

  void _deleteSingleReceipt(String receiptId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.deleteReceipt(receiptId);
              await _loadHistory();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAllReceipts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Receipts'),
        content: const Text(
            'This will permanently delete all saved receipts. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.deleteAllReceipts();
              await _loadHistory();
              if (mounted) Navigator.pop(context);
            },
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _backupHistory() async {
    if (_allReceipts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History is empty, nothing to back up.')));
      return;
    }
    try {
      final List<Map<String, dynamic>> json =
          _allReceipts.map((r) => r.toJson()).toList();
      final String jsonString = jsonEncode(json);

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/receipt_history_backup.json');
      await backupFile.writeAsString(jsonString);
      await Share.shareXFiles(
        [XFile(backupFile.path, name: 'receipt_history_backup.json')],
        text: 'My Receipt Scanner Backup',
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating backup: $e')));
    }
  }

  Future<void> _restoreHistory() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final File backupFile = File(result.files.single.path!);
        final String backupJson = await backupFile.readAsString();

        final List<dynamic> decodedList = jsonDecode(backupJson);
        final List<ReceiptData> importedReceipts =
            decodedList.map((item) => ReceiptData.fromJson(item)).toList();
        
        await _historyService.deleteAllReceipts();
        for (final receipt in importedReceipts) {
          await _historyService.saveReceipt(receipt);
        }

        await _loadHistory();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History restored successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error restoring backup: $e. Is the file valid?')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt History'),
        actions: [
          IconButton(
            tooltip: 'Toggle Sort Order',
            icon: Icon(_isSortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _isSortAscending = !_isSortAscending;
                _sortAndFilterReceipts();
              });
            },
          ),
          PopupMenuButton<SortOption>(
            tooltip: 'Sort By',
            icon: const Icon(Icons.sort),
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
                _sortAndFilterReceipts();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.date,
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.total,
                child: Text('Sort by Total'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.storeName,
                child: Text('Sort by Store Name'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'backup') _backupHistory();
              if (value == 'restore') _restoreHistory();
              if (value == 'delete_all') _deleteAllReceipts();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'backup',
                child: ListTile(
                    leading: Icon(Icons.cloud_upload),
                    title: Text('Backup History')),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                child: ListTile(
                    leading: Icon(Icons.cloud_download),
                    title: Text('Restore History')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete_all',
                enabled: _allReceipts.isNotEmpty,
                child: const ListTile(
                    leading: Icon(Icons.delete_sweep, color: Colors.red),
                    title: Text('Delete All',
                        style: TextStyle(color: Colors.red))),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_storeNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Store',
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _selectedStore != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedStore = null;
                              _sortAndFilterReceipts();
                            });
                          },
                        )
                      : null,
                ),
                value: _selectedStore,
                hint: const Text('Show All Stores'),
                isExpanded: true,
                items:
                    _storeNames.map<DropdownMenuItem<String>>((String storeName) {
                  return DropdownMenuItem<String>(
                    value: storeName,
                    child: Text(storeName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStore = newValue;
                    _sortAndFilterReceipts();
                  });
                },
              ),
            ),
          Expanded(
            child: _displayReceipts.isEmpty
                ? const Center(child: Text('Your saved receipts will appear here.'))
                : ListView.builder(
                    itemCount: _displayReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = _displayReceipts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(receipt.storeName ?? 'Unknown Store'),
                          subtitle: Text(
                              '${receipt.transactionDate ?? 'No Date'} - Total: \$${receipt.total?.toStringAsFixed(2) ?? 'N/A'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () =>
                                _deleteSingleReceipt(receipt.receiptId),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReceiptDetailScreen(receipt: receipt),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}