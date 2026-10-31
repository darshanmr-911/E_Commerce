import 'address.dart';
import 'cart_item.dart';

enum PaymentStatus { pending, failed }

class GroceryOrder {
  const GroceryOrder({
    required this.id,
    required this.address,
    required this.items,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.discountPaise,
    required this.totalPaise,
    required this.paymentMethod,
    required this.paymentStatus,
    this.isServerBacked = false,
  });

  final String id;
  final DeliveryAddress address;
  final List<CartItem> items;
  final int subtotalPaise;
  final int deliveryFeePaise;
  final int discountPaise;
  final int totalPaise;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final bool isServerBacked;

  GroceryOrder copyWith({PaymentStatus? paymentStatus, bool? isServerBacked}) {
    return GroceryOrder(
      id: id,
      address: address,
      items: items,
      subtotalPaise: subtotalPaise,
      deliveryFeePaise: deliveryFeePaise,
      discountPaise: discountPaise,
      totalPaise: totalPaise,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isServerBacked: isServerBacked ?? this.isServerBacked,
    );
  }
}
