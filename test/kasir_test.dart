import '../bin/kasir.dart';
import 'package:test/test.dart';

void main() {
  group('parseOrder', () {
    test('parses valid items with surrounding spaces', () {
      final result = parseOrder(' P01 x2 , P03x1 ');

      expect(result.validItems, hasLength(2));
      expect(result.rejectedItems, isEmpty);
      expect(result.validItems.first.code, 'P01');
      expect(result.validItems.first.quantity, 2);
    });

    test('records unknown codes and invalid quantities without throwing', () {
      final result = parseOrder('P01x2, P99x1, P03xabc, P04x0, salah');

      expect(result.validItems, hasLength(1));
      expect(result.rejectedItems, hasLength(4));
    });
  });

  group('createReceipt', () {
    test('applies discount at the exact threshold and deduplicates set', () {
      final receipt = createReceipt(parseOrder('P01x1, P02x1'));

      expect(receipt.total, 100000);
      expect(receipt.discount, 10000);
      expect(receipt.amountDue, 90000);
      expect(receipt.categories, {'Kopi'});
    });

    test('calculates discount above the threshold', () {
      final receipt = createReceipt(parseOrder('P01x2, P03x1'));

      expect(receipt.total, 115000);
      expect(receipt.discount, 11500);
      expect(receipt.amountDue, 103500);
      expect(receipt.categories, {'Kopi', 'Teh'});
    });

    test('does not apply discount below the threshold', () {
      final receipt = createReceipt(parseOrder('P01x2'));

      expect(receipt.total, 90000);
      expect(receipt.discount, 0);
      expect(receipt.amountDue, 90000);
    });
  });

  test('formats Indonesian rupiah amounts', () {
    expect(formatRupiah(100000), 'Rp100.000');
  });
}
