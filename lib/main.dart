import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF0051A0),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, color: Colors.white),
              SizedBox(width: 8),
              Text('THE BEST TOP-KARTA IN THE WORLD',style: TextStyle(color: Colors.white),),
            ],
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'web/icons/images/university_logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0051A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                  },
                  child: const Text(
                    'открыть карту',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}