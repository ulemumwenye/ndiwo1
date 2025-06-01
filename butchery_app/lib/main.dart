import 'package:flutter/material.dart';
import 'package:butchery_app/ui/main_app_shell.dart'; // Import MainAppShell
import 'package:butchery_app/locator.dart'; // Import the locator

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized for async main
  await setupLocator(); // Setup the service locator
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Butchery Management',
      theme: ThemeData(
        primarySwatch: Colors.blue, // You can customize the theme
        // For newer Flutter versions, you might prefer ColorScheme.fromSeed
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainAppShell(), // Use MainAppShell here
    );
  }
}
// The MyHomePage widget and its state can be removed if no longer directly used.
// For this subtask, we'll leave it to avoid accidental deletion if it's referenced elsewhere,
// though typically it would be cleaned up.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
