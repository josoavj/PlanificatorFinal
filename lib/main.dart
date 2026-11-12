import 'package:material_ui/material_ui.dart';
import 'package:planificator/app/app.dart';
import 'app/app_initializer.dart';

void main() async {
  await AppInitializer.initialize();
  runApp(const MyApp());
}
