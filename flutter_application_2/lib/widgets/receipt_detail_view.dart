import 'package:flutter/material.dart';
import '../models/receipt_data.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final ReceiptData receipt;
  const ReceiptDetailScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.storeName ?? 'Receipt Details'),
      ),
      body: ReceiptDetailView(receipt: receipt),
    );
  }
}

class ReceiptDetailView extends StatelessWidget {
  final ReceiptData receipt;
  final ScrollController? scrollController;

  const ReceiptDetailView(
      {Key? key, required this.receipt, this.scrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(receipt.storeName ?? 'Store Name Not Found',
            style: textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(receipt.transactionDate ?? 'Date Not Found',
            style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
        const Divider(height: 32, thickness: 1),
        ...receipt.lineItems
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.quantity}x',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(item.itemName, style: textTheme.bodyLarge)),
                      const SizedBox(width: 12),
                      Text('\$${item.price.toStringAsFixed(2)}',
                          style: textTheme.bodyLarge),
                    ],
                  ),
                ))
            .toList(),
        const Divider(height: 32, thickness: 1),
        if (receipt.serviceTax != null && receipt.serviceTax! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Service Tax:', style: textTheme.bodyLarge),
                Text('\$${receipt.serviceTax!.toStringAsFixed(2)}',
                    style: textTheme.bodyLarge),
              ],
            ),
          ),
        if (receipt.sst != null && receipt.sst! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SST:', style: textTheme.bodyLarge),
                Text('\$${receipt.sst!.toStringAsFixed(2)}',
                    style: textTheme.bodyLarge),
              ],
            ),
          ),
        if (receipt.total != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('\$${receipt.total!.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
            ],
          ),
      ],
    );
  }
}