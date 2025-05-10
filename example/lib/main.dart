import 'package:location_autocomplete/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Address Search Field Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Replace with your actual Google API key
    var googleApiKey = "<YOUR_GOOGLE_API_KEY>";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, style: TextStyle(fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SimpleAddressSearchField(
                inputDecoration: InputDecoration(
                  labelText: "Search address",
                  hintText: "Search address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                googleApiKey: googleApiKey,
                onSelected:
                    (address) =>
                        address != null
                            ? ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Address selected: ${address.formattedAddress}',
                                ),
                              ),
                            )
                            : null,
              ),
              const SizedBox(height: 20),
              LocationSearchField(
                hintText: "Location Search address",
                labelText: "Location: in person or virtual",
                googleApiKey: googleApiKey,
                onSelected:
                    (address) =>
                        address != null
                            ? ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Location selected: ${address.displayText}',
                                ),
                              ),
                            )
                            : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
