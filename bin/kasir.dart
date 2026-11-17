import 'dart:io';

typedef Product = ({String name, String category, int price});
typedef OrderedProduct = ({String code, Product product, int quantity});
typedef ReceiptLine = ({
  String code,
  Product product,
  int quantity,
  int subtotal,
});
typedef OrderParseResult = ({
  List<OrderedProduct> validItems,
  List<String> rejectedItems,
});
typedef Receipt = ({
  List<ReceiptLine> items,
  List<String> rejectedItems,
  int total,
  int discount,
  int amountDue,
  Set<String> categories,
});

const int discountThreshold = 100000;
const Map<String, Product> catalog = {
  'P01': (
    name: 'Kopi Sidikalang 250 g',
    category: 'Kopi',
    price: 45000,
  ),
  'P02': (name: 'Kopi Gayo 250 g', category: 'Kopi', price: 55000),
  'P03': (name: 'Teh Kayu Aro 100 g', category: 'Teh', price: 25000),
  'P04': (name: 'Gula Aren 500 g', category: 'Pemanis', price: 30000),
  'P05': (name: 'Bolu Meranti', category: 'Makanan', price: 80000),
};

void main() {
  stdout.writeln('=== KASIR OLEH-OLEH MEDAN ===');
  printCatalog();
  stdout.writeln();
  stdout.write('Pesanan (contoh: P01x2, P03x1): ');

  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    stdout.writeln('Pesanan kosong atau input tidak terbaca.');
    return;
  }

  final receipt = createReceipt(parseOrder(input));
  printReceipt(receipt);
}

void printCatalog() {
  const codeWidth = 8;
  const nameWidth = 24;
  const categoryWidth = 14;

  stdout.writeln('KATALOG TOKO');
  stdout.writeln(
    '${'KODE'.padRight(codeWidth)}'
    '${'NAMA'.padRight(nameWidth)}'
    '${'KATEGORI'.padRight(categoryWidth)}'
    '${'HARGA'.padLeft(12)}',
  );
  stdout.writeln('-' * 58);

  for (final entry in catalog.entries) {
    final product = entry.value;
    stdout.writeln(
      '${entry.key.padRight(codeWidth)}'
      '${product.name.padRight(nameWidth)}'
      '${product.category.padRight(categoryWidth)}'
      '${formatRupiah(product.price).padLeft(12)}',
    );
  }
}

OrderParseResult parseOrder(String input) {
  final validItems = <OrderedProduct>[];
  final rejectedItems = <String>[];

  for (final rawItem in input.split(',')) {
    final item = rawItem.trim();
    final parts = item.split('x');
    if (parts.length != 2) {
      rejectedItems.add('$item (format harus KODExJUMLAH)');
      continue;
    }

    final code = parts[0].trim().toUpperCase();
    final product = catalog[code];
    if (product == null) {
      rejectedItems.add('$item (kode produk tidak ditemukan)');
      continue;
    }

    final quantity = int.tryParse(parts[1].trim());
    if (quantity == null || quantity <= 0) {
      rejectedItems.add('$item (jumlah harus bilangan bulat positif)');
      continue;
    }

    validItems.add((code: code, product: product, quantity: quantity));
  }

  return (validItems: validItems, rejectedItems: rejectedItems);
}

Receipt createReceipt(OrderParseResult result) {
  final receiptLines = result.validItems
      .map(
        (item) => (
          code: item.code,
          product: item.product,
          quantity: item.quantity,
          subtotal: item.product.price * item.quantity,
        ),
      )
      .toList(growable: false);
  final total = receiptLines
      .map((line) => line.subtotal)
      .fold<int>(0, (sum, subtotal) => sum + subtotal);
  final discount = total >= discountThreshold ? (total * 10) ~/ 100 : 0;
  final categories = receiptLines.map((line) => line.product.category).toSet();

  return (
    items: receiptLines,
    rejectedItems: result.rejectedItems,
    total: total,
    discount: discount,
    amountDue: total - discount,
    categories: categories,
  );
}

void printReceipt(Receipt receipt) {
  stdout.writeln();
  stdout.writeln('================ STRUK BELANJA ================');

  if (receipt.items.isEmpty) {
    stdout.writeln('Tidak ada item valid yang dapat dibeli.');
  } else {
    var acceptedItemCount = 0;
    for (final item in receipt.items) {
      acceptedItemCount++;
      stdout.writeln(
        '${item.code} ${item.product.name} x${item.quantity} '
        '= ${formatRupiah(item.subtotal)}',
      );
    }
    stdout.writeln('Item diterima: $acceptedItemCount');
  }

  if (receipt.rejectedItems.isNotEmpty) {
    stdout.writeln('\nItem ditolak:');
    for (final item in receipt.rejectedItems) {
      stdout.writeln('- $item');
    }
  }

  stdout.writeln('-----------------------------------------------');
  stdout.writeln('Total       : ${formatRupiah(receipt.total)}');
  stdout.writeln('Diskon 10%  : ${formatRupiah(receipt.discount)}');
  stdout.writeln('Jumlah bayar: ${formatRupiah(receipt.amountDue)}');
  final categories = receipt.categories.toList()..sort();
  stdout.writeln(
    'Kategori    : ${categories.isEmpty ? '-' : categories.join(', ')}',
  );
  stdout.writeln('===============================================');
}

String formatRupiah(int amount) {
  final groupedAmount = amount
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return 'Rp$groupedAmount';
}
