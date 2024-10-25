import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/order.dart';
import '../../model/order_status.dart';
import '../../model/order_type.dart';

class OrderDetailsCard extends StatefulWidget {
  final Order order;
  const OrderDetailsCard({super.key, required this.order});

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard> {
  @override
  Widget build(BuildContext context) {
    Order orderDetails = widget.order;
    String formattedDate =
        DateFormat('MMMM dd, yyyy, hh:mm a').format(orderDetails.startDateTime);
    return Card(
      elevation: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Order Type
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0)),
            child: Container(
              width: 60,
              height: 100,
              color: orderDetails.orderTypeId == 1
                  ? Colors.deepPurple
                  : Colors.pink,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(
                  child: Text(
                    orderType
                        .where((item) => item.id == orderDetails.orderTypeId)
                        .first
                        .name
                        .toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          //Order Id & customer details & date time information
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${orderDetails.orderTrackId}",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    orderDetails.customerName == null
                        ? "CUSTOMER"
                        : "${orderDetails.customerName}",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    orderDetails.phoneNo == null || orderDetails.phoneNo == ""
                        ? "PHONE NUMBER"
                        : "${orderDetails.phoneNo}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  //Date Time
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          //Payment and Order status
          OrderStatusIndicator(orderStatusId: orderDetails.orderStatusId)
        ],
      ),
    );
  }
}

class OrderStatusIndicator extends StatefulWidget {
  final int orderStatusId;
  const OrderStatusIndicator({super.key, required this.orderStatusId});

  @override
  State<OrderStatusIndicator> createState() => _OrderStatusIndicatorState();
}

class _OrderStatusIndicatorState extends State<OrderStatusIndicator> {
  @override
  Widget build(BuildContext context) {
    int id = widget.orderStatusId;
    String statusText =
        getOrderStatusList.firstWhere((data) => data.id == id).name.toString();
    Color color = id == 1
        ? Colors.lightBlue
        : id == 2
            ? Colors.deepOrange
            : id == 3
                ? Colors.lightGreen
                : id == 4
                    ? Colors.red
                    : id == 5
                        ? Colors.pink
                        : Colors.lightBlue;
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(vertical: 5),
        width: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            statusText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class StatusIcon extends StatefulWidget {
  final int status;

  const StatusIcon({super.key, required this.status});

  @override
  State<StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<StatusIcon> {
  bool reverse = false; // Track color direction for case 2 animation

  @override
  Widget build(BuildContext context) {
    switch (widget.status) {
      case 1:
        // Case 1: Show disabled icon
        return const Icon(
          Icons.local_fire_department_outlined,
          color: Colors.grey, // Disabled color
        );

      case 2:
        // Case 2: Show animated icon with color change
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            begin: reverse ? Colors.orange : Colors.red,
            end: reverse ? Colors.red : Colors.orange,
          ),
          duration: const Duration(seconds: 1),
          onEnd: () {
            // Reverse the color direction to loop the animation
            setState(() {
              reverse = !reverse;
            });
          },
          builder: (BuildContext context, Color? color, Widget? child) {
            return Icon(
              Icons.local_fire_department,
              color: color ?? Colors.red, // Animated color
            );
          },
        );

      case 3:
        // Case 3: Show static green icon
        return const Icon(
          Icons.local_fire_department,
          color: Colors.green,
        );

      default:
        return const Icon(
          Icons.local_fire_department_outlined,
          color: Colors.grey, // Default case for invalid status
        );
    }
  }
}

class OrderStatusDropdown extends StatefulWidget {
  final int initialStatus;
  final Function(int) onStatusChange;

  const OrderStatusDropdown(
      {super.key, required this.initialStatus, required this.onStatusChange});

  @override
  _OrderStatusDropdownState createState() => _OrderStatusDropdownState();
}

class _OrderStatusDropdownState extends State<OrderStatusDropdown> {
  late int selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Choose the Order Status",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold, // Bold text
                    color: Colors.black87, // Custom color
                  ),
            ),
          ),
          const SizedBox(
              height: 10), // Adjusted spacing instead of using `10.ph`
          Container(
            width: double.infinity, // Full width of the screen
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Rounded corners
              border: Border.all(color: Colors.grey), // Grey border
              color: Colors.white, // Background color for dropdown
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0), // Inner padding
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true, // Ensures dropdown takes the full width
                value: selectedStatus,
                items: getOrderStatusList.map((OrderStatus status) {
                  return DropdownMenuItem<int>(
                    value: status.id,
                    child: Text(
                      status.name.toString(),
                      style: const TextStyle(
                        fontSize: 16, // Customize the font size
                        fontWeight: FontWeight.w500, // Medium weight
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                  widget.onStatusChange(selectedStatus); // Update the status
                },
                icon: const Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                iconSize: 24, // Customize the icon size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
