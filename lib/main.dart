import 'package:flutter/material.dart';
import 'package:planificator/app/app.dart';
import 'app/app_initializer.dart';

void main() async {
  await AppInitializer.initialize();
  runApp(const MyApp());
}
