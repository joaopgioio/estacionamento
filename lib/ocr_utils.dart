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

bool isValidPlate(String text) {

  // Se texto for null, retorne false imediatamente
  if (text == null) {
    return false;
  } else {
    String texto = "";
    // Remove o "-"
    texto = text.replaceAll(RegExp(r'[-.·]'), '').trim();

    // Continue a execução se 'texto' não for nulo
    String? placa = buscaValorPlaca(texto);

    // Verifica se a placa encontrada é válida e não é nula
    if (placa != null && validFormatPlate(placa)) {
      return true; // Placa válida
    } else {
      return false; // Placa inválida ou não encontrada
    }
  }
}

String enviaPlaca(texto){

  // Chama a função que remove o hífen, busca e valida a placa
  String? placa = buscaValorPlaca(texto);

  // Verifica se a placa encontrada é válida e não é nula
  if (placa != null && validFormatPlate(placa)) {
    return placa; // Retorna a placa validada
  } else {
    return 'Nenhuma placa encontrada'; // Retorna null se a placa não for válida ou não existir
  }
}

String? buscaValorPlaca(String texto) {
  // Remover espaços extras e transformar o texto para letras maiúsculas
  texto = texto.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  // Expressão regular para o formato antigo: 3 letras + 4 números (ex: FBI5551)
  RegExp oldPattern = RegExp(r'[A-Z]{3}[0-9]{4}');

  // Expressão regular para o formato Mercosul: 3 letras + 1 número + 1 letra + 2 números (ex: ABC1D23)
  RegExp newPattern = RegExp(r'[A-Z]{3}[0-9]{1}[A-Z]{1}[0-9]{2}');

  // Verifica se há correspondência com o formato antigo
  Match? matchOld = oldPattern.firstMatch(texto);

  // Verifica se há correspondência com o formato Mercosul
  Match? matchNew = newPattern.firstMatch(texto);

  // Retorna a placa encontrada se algum dos padrões corresponder
  if (matchOld != null) {
    return matchOld.group(0); // Placa no formato antigo
  } else if (matchNew != null) {
    return matchNew.group(0); // Placa no formato Mercosul
  } else {
    return null; // Nenhuma placa encontrada
  }
}

bool validFormatPlate(String placa) {

  // Formato padrão antigo: 3 letras + 4 números
  final oldPattern = RegExp(r'[A-Z]{3}[0-9]{4}');

  // Formato padrão Mercosul: 3 letras + 1 número + 1 letra + 2 números
  final newPattern = RegExp(r'[A-Z]{3}[0-9]{1}[A-Z]{1}[0-9]{2}');

  bool resultado = oldPattern.hasMatch(placa) || newPattern.hasMatch(placa);
  return resultado;

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
bool validarCampos(nomeController, telefoneController, whatsappController) {

  RegExp nomeRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$'); // Permite letras, acentos e espaços

  final isNomeValid = nomeRegex.hasMatch(nomeController) && nomeController.length >= 3;
  final isTelefoneValid = telefoneController.text.length == 19;
  final isWhatsappValid = whatsappController.text.length == 19;

  if (!isNomeValid) {
    print('Nome inválido: deve conter apenas letras e espaços e ter no mínimo 3 caracteres.');
  }
  if (!isTelefoneValid) {
    print('Telefone inválido: formato inválido. Exemplo: +55 (11) 91234-5678');
  }
  if (!isWhatsappValid) {
    print('WhatsApp inválido: formato inválido. Exemplo: +55 (11) 91234-5678');
  }

  // Habilita o botão se todos os campos estiverem preenchidos corretamente
  return isNomeValid && isTelefoneValid && isWhatsappValid;
}