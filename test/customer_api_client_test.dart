import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:e_commerce/services/customer_api_client.dart';

void main() {
  test(
    'maps backend category products into exact paise and stock limits',
    () async {
      late Uri requestedUri;
      final client = CustomerApiClient(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 42,
                  'category_id': 3,
                  'category_name': 'Vegetables',
                  'name': 'Tomato',
                  'description': 'Fresh tomatoes',
                  'image': 'https://example.test/tomato.jpg',
                  'selling_price': '39.50',
                  'original_price': '45.00',
                  'unit': 'kg',
                  'is_available': true,
                  'stock_quantity': 12,
                  'minimum_order_quantity': 2,
                  'maximum_order_quantity': 5,
                },
                {
                  'id': 43,
                  'category_id': 2,
                  'category_name': 'Fruits',
                  'name': 'Apple',
                  'description': '',
                  'image': '',
                  'selling_price': '100.00',
                  'original_price': '100.00',
                  'unit': 'kg',
                  'is_available': true,
                  'stock_quantity': 2,
                  'minimum_order_quantity': 1,
                  'maximum_order_quantity': 50,
                },
              ],
            }),
            200,
          );
        }),
      );

      final products = await client.fetchProducts(categoryName: 'Vegetables');

      expect(requestedUri.queryParameters['search'], 'Vegetables');
      expect(products, hasLength(1));
      expect(products.single.productId, '42');
      expect(products.single.minimumOrderQuantity, 2);
      expect(products.single.stockCount, 5);
      expect(products.single.pricePaise, 4500);
      expect(products.single.discountedPricePaise, 3950);
      expect(products.single.discountedPriceLabel, '₹39.50/kg');
    },
  );
}
