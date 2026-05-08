import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/shop_page.dart';
import 'pages/survey_page.dart';
import 'services/route_service.dart';
import 'services/channel_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterSharedComponentsApp());
}

class FlutterSharedComponentsApp extends StatelessWidget {
  const FlutterSharedComponentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter共享组件',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: RouteService.loginRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RouteService.loginRoute:
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
              settings: settings,
            );
          case RouteService.shopRoute:
            return MaterialPageRoute(
              builder: (_) => const ShopPage(),
              settings: settings,
            );
          case RouteService.surveyRoute:
            return MaterialPageRoute(
              builder: (_) => const SurveyPage(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
              settings: settings,
            );
        }
      },
    );
  }
}
