import 'package:cashcow/utils/extension/sizedbox.dart';
import 'package:cashcow/view/widgets/order_details_props.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/hive/order_controller.dart';
import '../../model/order.dart';
import '../../model/order_menus.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderTrackId;

  const OrderDetailsPage({super.key, required this.orderTrackId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrderServiceController orderServiceController = Get.find();
  var orderInfo = Order.empty().obs;
  var orderMenus = <OrderMenus>[].obs;
  var totalAmount = 0.0.obs;
  var isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  void _fetchOrderDetails() {
    try {
      isLoading.value = true; // Set loading to true before fetching

      orderInfo.value = orderInfo.value =
          (orderServiceController.fetchOrderDetails(widget.orderTrackId));
      if (orderInfo.value.orderTrackId != Order.empty().orderTrackId) {
        // Start watching for changes to this specific order
        orderServiceController.watchOrder(widget.orderTrackId);
      }
      orderMenus.value =
          orderServiceController.getOrderMenus(widget.orderTrackId);
      totalAmount.value = orderServiceController
          .getOrderMenus(widget.orderTrackId)
          .fold(0.0, (total, item) => total + (item.price! * item.quantity!));
      debugPrint(
          "Updated order details: Order Status ID - ${orderInfo.value.orderStatusId}");
    } catch (e) {
      Get.snackbar('Error', 'Failed to load order details: $e');
    } finally {
      isLoading.value = false; // Set loading to false once fetching is done
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total amount for the order

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Obx(
          () {
            if (isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderDetailsCard(order: orderInfo.value),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Order Items: ${orderMenus.length}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      itemCount: orderMenus.length,
                      itemBuilder: (context, index) {
                        final item = orderMenus[index];
                        return OrderMenuItem(
                          item: item,
                          onStatusChange: (status) async {
                            await orderServiceController.updateIsPrepared(
                              widget.orderTrackId,
                              item.id.toString(),
                              status,
                            );
                            // Refresh order menu to reflect changes
                            _fetchOrderDetails();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 150,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount To Pay:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "\$ ${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              10.ph,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.shopping_cart, color: Colors.white),
                      onPressed: () {
                        debugPrint("Proceeding to payment");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: const Text(
                        "Proceed to Payment",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New widget to represent each order menu item
class OrderMenuItem extends StatelessWidget {
  final OrderMenus item;
  final Function(int) onStatusChange;

  const OrderMenuItem(
      {super.key, required this.item, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    RxInt isPrepared = item.isPrepared.obs; // Use item-specific observable

    return ListTile(
      title: Text(item.name!),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              // Open the modal bottom sheet to change status
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return OrderStatusDropdown(
                    initialStatus: isPrepared.value,
                    onStatusChange: (status) {
                      onStatusChange(status);
                      isPrepared.value = status; // Update local status
                      Get.back(); // Close bottom sheet
                    },
                  );
                },
              );
            },
            child: Obx(() => StatusIcon(
                status: isPrepared.value)), // Watch individual item status
          ),
          Flexible(
            child: Text(
              '\$ ${(item.price! * item.quantity!).toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '( ${item.quantity} X \$ ${item.price} )',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
