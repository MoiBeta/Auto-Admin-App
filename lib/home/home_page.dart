import 'package:auto_admin_app/home/widget/home_drawer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(),
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
          Text('Bienvenido al Home'),
        ],
      ),
    );
  }
}
