import 'package:cashcow/app_binding.dart';
import 'package:cashcow/model/food_category.dart';
import 'package:cashcow/model/order_menus.dart';
import 'package:cashcow/model/order_status.dart';
import 'package:cashcow/model/payement_type.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'controllers/hive/order_controller.dart';
import 'model/food_menu.dart';
import 'model/order.dart';
import 'model/order_type.dart';

Future<void> main() async {
  // Ensure WidgetsBinding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register adapters
  await _initHive();

  // Register dependencies after Hive initialization
  AppBindings().dependencies();

  // Run the app
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Enables DevicePreview only in non-release mode
      builder: (context) => const MyApp(), // Wrap your app
    ),
  );
}

Future<void> _initHive() async {
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(
        appDocumentDir.path); // Initialize Hive with the document directory

    // Register all adapters
    Hive.registerAdapter(FoodMenuAdapter());
    Hive.registerAdapter(FoodCategoryAdapter());
    Hive.registerAdapter(OrderAdapter());
    Hive.registerAdapter(OrderTypeAdapter());
    Hive.registerAdapter(OrderMenusAdapter());
    Hive.registerAdapter(OrderStatusAdapter());
    Hive.registerAdapter(PaymentTypeAdapter());

    // Open required boxes
    // Initialize the OrderServiceController only after Hive initialization
    OrderServiceController orderServiceController =
        Get.put(OrderServiceController());
    await orderServiceController.openBox();
  } catch (e) {
    // Handle any errors related to Hive initialization
    debugPrint('Error initializing Hive: $e');
  }
}
