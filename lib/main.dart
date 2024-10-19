import 'package:estacionamento/placa_recognition_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reconhecimento de Placas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlacaRecognitionScreen(),
    );
  }
}