import 'package:get_it/get_it.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:butchery_app/services/sales_service.dart';
import 'package:butchery_app/services/notification_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // Services are registered as lazy singletons. They will be created once they are first requested.
  locator.registerLazySingleton(() => InventoryService());

  // NotificationService needs to be initialized before it's used by SalesService or other parts of the app
  final notificationService = NotificationService();
  await notificationService.initialize(); // Call initialize here
  locator.registerSingleton<NotificationService>(notificationService); // Register as a non-lazy singleton

  // SalesService depends on InventoryService and NotificationService
  locator.registerLazySingleton(() => SalesService(
    locator<InventoryService>(),
    locator<NotificationService>(),
  ));

  // You can register other services or view models here as needed
}
