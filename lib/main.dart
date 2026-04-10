import 'package:flutter/material.dart';
import 'ui/screens/decision_tree_screen.dart';
import 'ui/screens/food_zones_screen.dart';
import 'ui/screens/navigation_screen.dart';
import 'ui/screens/meal_route_screen.dart';
import 'ui/screens/tour_screen.dart';

void main() {
  runApp(const TopKartaApp());
}

class TopKartaApp extends StatelessWidget {
  const TopKartaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Karta (ТГУ)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005AAB)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF005AAB),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    FoodZonesScreen(),
    NavigationScreen(),
    MealRouteScreen(),
    TourScreen(),
    DecisionTreeScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Зоны еды',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Навигация'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Маршрут',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.hiking), label: 'Тур'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: 'Дерево',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF005AAB),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
