import 'package:cashcow/view/pages/cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../widgets/common/kart_icon.dart';
import 'new_order.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final CartController cartController = Get.find();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController
    _tabController = TabController(length: 3, vsync: this); // Assuming 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Cashcow'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              const Tab(
                icon: Icon(Icons.add_shopping_cart),
                text: 'New Order',
              ),
              Tab(
                icon: KCartIcon(cartController: cartController),
                text: 'cart',
              ),
              const Tab(
                icon: Icon(Icons.payments_sharp),
                text: 'Payment',
              ),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings))
          ],
        ),
        body: TabBarView(controller: _tabController, children: [
          NewOrderPage(
            tabController: _tabController,
          ),
          CartPage(),
          const PaymentPage(),
        ]),
      ),
    );
  }
}

// Payment Page
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Payment Tab',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
