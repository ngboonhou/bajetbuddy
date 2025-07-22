class ReceiptData {
  final String receiptId;
  final String? storeName;
  final String? transactionDate;
  final double? total;
  final double? sst;
  final double? serviceTax;
  final List<LineItem> lineItems;

  ReceiptData({
    required this.receiptId,
    this.storeName,
    this.transactionDate,
    this.total,
    this.sst,
    this.serviceTax,
    required this.lineItems,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    var itemsList = json['line_items'] as List? ?? [];
    List<LineItem> parsedItems =
        itemsList.map((i) => LineItem.fromJson(i)).toList();
    return ReceiptData(
      receiptId: json['receipt_id'] as String? ??
          'id_${DateTime.now().millisecondsSinceEpoch}',
      storeName: json['store_name'] as String?,
      transactionDate: json['transaction_date'] as String?,
      total: (json['total'] as num?)?.toDouble(),
      sst: (json['sst'] as num?)?.toDouble(),
      serviceTax:
          (json['service_tax'] as num?)?.toDouble(),
      lineItems: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'store_name': storeName,
      'transaction_date': transactionDate,
      'total': total,
      'sst': sst,
      'service_tax': serviceTax,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'receipt_id': receiptId,
      'store_name': storeName,
      'transaction_date': transactionDate,
      'total': total,
      'sst': sst,
      'service_tax': serviceTax,
    };
  }
}

class LineItem {
  final int quantity;
  final String itemName;
  final double price;

  LineItem({required this.quantity, required this.itemName, required this.price});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      itemName: json['item_name'] as String? ?? 'Unknown Item',
      price: (json['price'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'item_name': itemName,
      'price': price,
    };
  }
}