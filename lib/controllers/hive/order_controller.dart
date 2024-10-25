import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../model/order.dart';
import '../../model/order_menus.dart';

class OrderServiceController extends GetxController {
  final String _orderBoxName = 'orders_list';
  final String _orderMenuBoxName = 'order_menus_list';

  Box<Order>? _orderBox; // Hive box to store orders
  Box<OrderMenus>? _orderMenuBox; // Hive box to store order menus

  // Observable lists to hold orders and menus
  var orders = <Order>[].obs;
  var orderMenus = <OrderMenus>[].obs;

  // Private method to check if the box is opened
  bool isBoxOpen(Box? box) => box != null;

  @override
  void onInit() {
    super.onInit();
    openBox(); // Open the Hive box when the controller is initialized
  }

  // Open the Hive box for orders
  Future<void> openBox() async {
    try {
      _orderBox = await Hive.openBox<Order>(_orderBoxName);
      _orderMenuBox = await Hive.openBox<OrderMenus>(_orderMenuBoxName);
      debugPrint('Order and Menu boxes opened successfully.');

      // Load orders and menus from Hive into observable lists
      orders.assignAll(_orderBox!.values.toList());
      orderMenus.assignAll(_orderMenuBox!.values.toList());

      // Listen to changes in Hive box and update observable lists accordingly
      _orderBox!.watch().listen((event) {
        // Reload orders when any change occurs
        orders.assignAll(_orderBox!.values.toList());
      });

      _orderMenuBox!.watch().listen((event) {
        // Reload menus when any change occurs
        orderMenus.assignAll(_orderMenuBox!.values.toList());
      });
    } catch (e) {
      debugPrint('Error opening boxes: $e');
    }
  }

  // Method to close the Hive box (usually called when the app is terminating)
  Future<void> closeBox() async {
    if (_orderBox != null) {
      await _orderBox!.close();
      _orderBox = null;
      debugPrint('Order box closed successfully.');
    } else {
      debugPrint('Order box is already closed or not opened.');
    }
  }

  // Create a new order and add it to the box
  Future<void> createOrder(Order order, List<OrderMenus> menus) async {
    if (!isBoxOpen(_orderBox)) return;

    try {
      // Assign an orderTrackId for the order
      String orderTrackId =
          DateTime.now().millisecondsSinceEpoch.toString(); // Unique ID
      Order newOrder = order.copyWith(orderTrackId: orderTrackId);

      await _orderBox!.add(newOrder);
      orders.add(newOrder); // Add to observable list

      // Save associated OrderMenus with the same orderTrackId
      for (var menu in menus) {
        OrderMenus newMenu = menu.copyWith(
            orderTrackId: orderTrackId); // Set the same orderTrackId
        await _orderMenuBox!.add(newMenu);
        orderMenus.add(newMenu); // Add to observable list
      }

      debugPrint(
          'Order created: ${newOrder.orderStatusId}, Track ID: $orderTrackId');
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow; // Optional: rethrow to handle it higher up
    }
  }

  // Method to get all OrderMenus by orderTrackId
  List<OrderMenus> getOrderMenus(String orderTrackId) {
    return orderMenus
        .where((menu) => menu.orderTrackId == orderTrackId)
        .toList();
  }

// Method to fetch order details by orderTrackId
  Order fetchOrderDetails(String orderTrackId) {
    try {
      // Fetch order from Hive instead of just the observable list to get the latest changes
      final order = _orderBox!.values.firstWhere(
        (o) => o.orderTrackId == orderTrackId,
        orElse: () => Order.empty(),
      );
      return order;
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      return Order.empty(); // Return empty order to indicate failure
    }
  }

  // Listen to changes in the box and update only the relevant order
  void watchOrder(String orderTrackId) {
    _orderBox!.watch().listen((event) {
      // Check if the event affects the specific orderTrackId
      final order = fetchOrderDetails(orderTrackId);
      if (order.orderTrackId != Order.empty().orderTrackId) {
        debugPrint('Order with trackId $orderTrackId has changed.');
        // Update the specific order details if necessary in the UI or logic
        // You can use GetX observables or methods here to notify the UI
      }
    });
  }

// Method to get a list of all orders
  List<Order> getAllOrdersList() {
    try {
      return _orderBox!.values.toList().cast<Order>();
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      return []; // Return an empty list in case of an error
    }
  }

  // Method to listen for changes in the orders box and update the list when changes occur
  void watchOrders() {
    _orderBox!.watch().listen((event) {
      // Whenever there's a change in the box, fetch the latest list of orders
      final updatedOrders = getAllOrdersList();
      debugPrint('Orders have changed. Updated orders list fetched.');

      // If you're using GetX, you can update the observable orders list like this:
      orders.value =
          updatedOrders; // Assuming 'orders' is an RxList<Order> in GetX

      // If you want to perform additional logic, do it here
      // For example, notify the UI or any dependent widgets
    });
  }

//-----------------------------------------------------------------------------------------------------------

  // Method to delete all orders and their corresponding menus
  Future<void> deleteAllOrders() async {
    if (!isBoxOpen(_orderBox)) return;

    try {
      await _orderBox!.clear();
      await _orderMenuBox!.clear();
      orders.clear();
      orderMenus.clear();
      debugPrint(
          'All orders and their corresponding menus deleted successfully.');
    } catch (e) {
      debugPrint('Error deleting all orders: $e');
      rethrow;
    }
  }

  // Method to update the isPrepared status of an OrderMenus item
  Future<void> updateIsPrepared(
      String orderTrackId, String id, int isPrepared) async {
    if (!isBoxOpen(_orderMenuBox)) return;

    try {
      var menuList = _orderMenuBox!.values
          .where((menu) => menu.orderTrackId == orderTrackId)
          .toList();
      if (menuList.isEmpty) {
        debugPrint('No menu items found for orderTrackId $orderTrackId');
        return;
      }

      var menu = menuList.firstWhere((menu) => menu.id == id);
      OrderMenus updatedMenu = menu.copyWith(isPrepared: isPrepared);
      await _saveUpdatedMenu(updatedMenu, menu);

      // Handle deletion of menu if isPrepared status is 4
      if (isPrepared == 4) {
        await _deleteMenuItem(menu);
      }

      // Update order status based on the menu list
      await _updateOrderStatusBasedOnMenu(menuList, orderTrackId);

      // If all items are deleted, prompt for order deletion
      if (menuList.isEmpty || menuList.every((menu) => menu.isPrepared == 4)) {
        _showDeleteOrderConfirmation(orderTrackId);
      }
    } catch (e) {
      debugPrint('Error updating isPrepared status: $e');
    }
  }

  // Method to save updated menu back to Hive
  Future<void> _saveUpdatedMenu(
      OrderMenus updatedMenu, OrderMenus oldMenu) async {
    int menuIndex = _orderMenuBox!.values.toList().indexOf(oldMenu);

    if (menuIndex != -1) {
      await _orderMenuBox!.putAt(menuIndex, updatedMenu);

      int orderMenuIndex = orderMenus.indexWhere((m) => m.id == oldMenu.id);
      if (orderMenuIndex != -1) {
        orderMenus[orderMenuIndex] = updatedMenu;
      }

      debugPrint('Menu status updated: isPrepared = ${updatedMenu.isPrepared}');
    } else {
      debugPrint('Error: Menu not found in the Hive box.');
    }
  }

  // Method to delete a menu item if its isPrepared status is 4
  Future<void> _deleteMenuItem(OrderMenus menu) async {
    await _orderMenuBox!.delete(menu.id);
    orderMenus.removeWhere((m) => m.id == menu.id);
    debugPrint('Menu item with id ${menu.id} deleted.');
  }

  // Method to update order status based on prepared statuses of menu items
  Future<void> _updateOrderStatusBasedOnMenu(
      List<OrderMenus> menuList, String orderTrackId) async {
    bool allPrepared = menuList.every((menu) => menu.isPrepared == 1);
    bool allProcessed = menuList.every((menu) => menu.isPrepared == 3);

    if (allPrepared) {
      await _updateOrderStatus(orderTrackId, 1); // All items prepared
    } else if (allProcessed) {
      await _updateOrderStatus(orderTrackId, 3); // All items processed
    } else {
      await _updateOrderStatus(orderTrackId, 2); // Cooking in progress
    }
  }

  // Method to update order status in Hive
  Future<void> _updateOrderStatus(String orderTrackId, int newStatus) async {
    if (!isBoxOpen(_orderBox)) return;

    try {
      final order = _orderBox!.values.firstWhere(
        (o) => o.orderTrackId == orderTrackId,
        orElse: () => throw Exception('Order not found'),
      );

      Order updatedOrder = order.copyWith(orderStatusId: newStatus);
      int orderIndex = _orderBox!.values.toList().indexOf(order);
      await _orderBox!.putAt(orderIndex, updatedOrder);

      debugPrint(
          'Order status updated to $newStatus for orderTrackId: $orderTrackId');
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  // Method to show confirmation dialog for deleting an order
  void _showDeleteOrderConfirmation(String orderTrackId) {
    Get.defaultDialog(
      title: "Delete Order",
      middleText: "This order has no items left. Do you want to delete it?",
      onConfirm: () async {
        await _deleteOrder(orderTrackId);
        Get.back(); // Close the dialog
      },
      onCancel: () {
        Get.back(); // Close the dialog without action
      },
    );
  }

  // Method to delete an order
  Future<void> _deleteOrder(String orderTrackId) async {
    try {
      // Find the key of the order that matches the orderTrackId
      final orderKey = _orderBox?.keys.firstWhere(
        (key) => _orderBox?.get(key)?.orderTrackId == orderTrackId,
        orElse: () => null,
      );

      // Check if the order exists
      if (orderKey != null) {
        await _orderBox?.delete(orderKey); // Delete the order using its key
        orders.assignAll(
            _orderBox!.values.toList()); // Refresh the observable list
        debugPrint('Order with orderTrackId: $orderTrackId deleted');
      } else {
        debugPrint('Order with orderTrackId: $orderTrackId not found');
      }
    } catch (e) {
      debugPrint('Error deleting order with orderTrackId $orderTrackId: $e');
    }
  }




}
