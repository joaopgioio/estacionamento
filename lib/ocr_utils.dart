import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

Future<String> recognizeTextFromImage(File image) async {
  final inputImage = InputImage.fromFile(image);
  final textDetector = GoogleMlKit.vision.textRecognizer();
  final recognizedTextResult = await textDetector.processImage(inputImage);
  await textDetector.close();

  String placa = '';
  for (TextBlock block in recognizedTextResult.blocks) {
    placa += block.text + ' ';
  }
  return placa;
}

//bool isValidPlate(String text) {
//  final regex = RegExp(r'^[A-Z]{3} \d{4}$');
//  return regex.hasMatch(text);
//}

bool isValidPlate(String text) {

  // Formato padrão antigo: 3 letras + 4 números
  final oldPattern = RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{4}');

  // Formato padrão Mercosul: 3 letras + 1 número + 1 letra + 2 números
  final newPattern = RegExp(r'^[A-Z0-9]{4}[A-Z0-9][0-9]{2}');

  List<String> palavras = text.split(' ');

  String placa = "";

  if (palavras.length >= 3) {
    placa = palavras[2];
    print('Placa: $placa');
  } else {
    placa;
  }

  // Remove espaços extras
  placa = placa.replaceAll(' ', '');
  print("Placa : " + placa);

  // Verifica se a placa corresponde a um dos formatos
  return oldPattern.hasMatch(placa) || newPattern.hasMatch(placa);
}

String buscaValorPlaca(String text) {

  // Formato padrão antigo: 3 letras + 4 números
  final oldPattern = RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{4}');

  // Formato padrão Mercosul: 3 letras + 1 número + 1 letra + 2 números
  final newPattern = RegExp(r'^[A-Z0-9]{4}[A-Z0-9][0-9]{2}');

  List<String> palavras = text.split(' ');

  String placa = "";

  if (palavras.length >= 3) {
    placa = palavras[2];
    print('Placa: $placa');
  } else {
    placa;
  }

  // Remove espaços extras
  placa = placa.replaceAll(' ', '');
  print("Placa : " + placa);

  // Verifica se a placa corresponde a um dos formatos
  return placa;
}

// Método para transformar a placa em letras maiúsculas
String transform(String placa) {
  return placa.toUpperCase();
}

// Método para transformar a primeira letra do nome em maiúscula
String transformPrimeiraLetraNome(String nome) {
  List<String> palavras = nome.split(' ');
  List<String> preposicoes = ['da', 'de', 'do', 'dos', 'das', 'e'];

  for (int i = 0; i < palavras.length; i++) {
    // Verifica se a palavra é uma preposição
    if (!preposicoes.contains(palavras[i].toLowerCase())) {
      palavras[i] = palavras[i][0].toUpperCase() + palavras[i].substring(1).toLowerCase();
    } else {
      palavras[i] = palavras[i].toLowerCase();
    }
  }

    return palavras.join(' ');
  }

// Função para verificar se o botão "Salvar" pode ser habilitado
bool validarCampos(String nome, telefoneController, whatsappController) {
  final isNomeValid = nome.isNotEmpty;
  final isTelefoneValid = telefoneController.text.length == 19;
  final isWhatsappValid = whatsappController.text.length == 19;

  // Habilita o botão se todos os campos estiverem preenchidos corretamente
  return isNomeValid && isTelefoneValid && isWhatsappValid;
}