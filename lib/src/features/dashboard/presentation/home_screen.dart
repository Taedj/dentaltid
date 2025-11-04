import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome to DentalTid!',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 50.0,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Remaining Patients: 5'),
              Text('Last Sync: Never'),
            ],
          ),
        ),
      ),
    );
  }
}
