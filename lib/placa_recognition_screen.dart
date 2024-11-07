import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ocr_utils.dart';
import 'database_helper.dart';
import 'dart:io';

class PlacaRecognitionScreen extends StatefulWidget {
  @override
  PlacaRecognitionScreenState createState() => PlacaRecognitionScreenState();
}

class PlacaRecognitionScreenState extends State<PlacaRecognitionScreen> {
  String recognizedText = '';
  final TextEditingController plateController = TextEditingController();

  static const Color titleColor = Color(0xFFEC995B);
  static const Color closeButtonColor = Color(0xFFFFF2E8);
  static const Color closeButtonTextColor = Color(0xFFEC995B);
  static const Color closeButtonIconColor = Color(0xFFE47724);
  static const Color contentTextColor = Color(0xFF555555);
  static const Color plateTextColor = Color(0xFF333333);
  static const Color nameTextColor = Color(0xFF777777);
  static const Color buttonBackgroundColor = Color(0xFFFFF2E8);
  static const Color buttonTextColor = Color(0xFFEC995B);
  static const Color buttonIconColor = Color(0xFFE47724);
  static const TextStyle buttonTextStyle = TextStyle(color: buttonTextColor);
  static const Color primaryColor = Color(0xFFEC995B);
  static const Color secondaryColor = Color(0xFFFFF2E8);
  static const Color accentColor = Color(0xFFE47724);

  void makeCall(String phone, BuildContext context) async {
    final Uri url = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showErrorDialog(context, 'Não foi possível ligar para $phone');
      }
    } catch (e) {
      showErrorDialog(context, 'Não foi possível ligar para $phone');
    }
  }

  Future<void> openWhatsApp(String whatsapp, BuildContext context) async {
    final String formattedWhatsApp = whatsapp.replaceAll(
        RegExp(r'\D'), ''); // Remove todos os caracteres não numéricos
    final Uri url = Uri.parse('whatsapp://send?phone=$formattedWhatsApp');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode
            .externalApplication); // Usa o modo de aplicação externa
      } else {
        showErrorDialog(
            context, 'Não foi possível abrir o WhatsApp para $whatsapp');
      }
    } catch (e) {
      showErrorDialog(
          context, 'Não foi possível abrir o WhatsApp para $whatsapp');
    }
  }

  Future<String> recognizeTextFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textDetector = GoogleMlKit.vision.textRecognizer();

    try {
      final RecognizedText recognizedText = await textDetector.processImage(
          inputImage);

      // Concatena os textos de cada bloco, separados por espaço
      final placa = recognizedText.blocks.map((block) => block.text).join(' ');

      return placa
          .trim(); // Remove possíveis espaços extras no início/fim da string
    } finally {
      await textDetector
          .close(); // Garante que o textDetector será fechado mesmo em caso de erro
    }
  }

  Future<void> pickImage() async {
    setState(() {
      recognizedText =
      ''; // Limpa o texto reconhecido antes de iniciar um novo reconhecimento
    });

    final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera);

    if (image != null) {
      final File file = File(image.path);
      String text = await recognizeTextFromImage(file);

      if (isValidPlate(text)) {
        String placa = enviaPlaca(text);
        print("Caiu no isValidPlate: $placa");
        if (placa == 'Nenhuma placa encontrada') {
          showRetryDialog(context); // Exibe o diálogo para tentar novamente
        } else {
          print("Caiu no else do isValidPlate: $placa");
          //text = placa!; // Normaliza ou converte a placa para o formato desejado
          showConfirmationDialog(
              context, placa); // Exibe o diálogo de confirmação
        }
      } else {
        print("Caiu no else isValidPlate.");
        showRetryDialog(context); // Exibe o diálogo para tentar novamente
      }
    }
  }

  void showRetryDialog(BuildContext context) {
    String placa = '';
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          //backgroundColor: Colors.white, // Cor de fundo do diálogo
          title: Text(
            'Erro de Formato de Placa',
            style: TextStyle(color: titleColor), // Usa a cor do título
          ),
          content: Text(
            'Formato de placa inválido. Deseja tentar novamente?',
            style: TextStyle(color: contentTextColor), // Usa a cor do conteúdo
          ),
          actions: [
            // Botão "Sim"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                pickImage(); // Ação para tentar novamente
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto do botão
                backgroundColor: buttonBackgroundColor, // Cor de fundo do botão
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: buttonIconColor),
                  // Usa a cor do ícone do botão
                  SizedBox(width: 8),
                  Text('Sim'),
                  // Texto do botão
                ],
              ),
            ),
            // Botão "Não"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showEditOptionDialog(
                    context, placa); // Abre diálogo para editar ou nova captura
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto do botão
                backgroundColor: buttonBackgroundColor, // Cor de fundo do botão
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: buttonIconColor),
                  // Usa a cor do ícone do botão
                  SizedBox(width: 8),
                  Text('Não'),
                  // Texto do botão
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void showConfirmationDialog(BuildContext context, String placa) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          //backgroundColor: Colors.white, // Cor de fundo do diálogo
          title: Text(
            'Placa Capturada',
            style: TextStyle(color: titleColor,
                fontWeight: FontWeight.bold), // Usa a cor do título
          ),
          content: Text(
            'A placa reconhecida é: $placa. Está correta?',
            style: TextStyle(color: contentTextColor), // Usa a cor do conteúdo
          ),
          actions: [
            // Botão "Sim"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                processarPlaca(placa); // Processa a placa se estiver correta
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto do botão
                backgroundColor: buttonBackgroundColor, // Cor de fundo do botão
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: buttonIconColor),
                  // Usa a cor do ícone do botão
                  SizedBox(width: 8),
                  Text('Sim'),
                  // Texto do botão
                ],
              ),
            ),
            // Botão "Não"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showEditOptionDialog(
                    context, placa); // Abre diálogo para editar ou nova captura
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto do botão
                backgroundColor: buttonBackgroundColor, // Cor de fundo do botão
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: buttonIconColor),
                  // Usa a cor do ícone do botão
                  SizedBox(width: 8),
                  Text('Não'),
                  // Texto do botão
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void processarPlaca(String placa) async {
    try {
      // Obtém os dados do veículo a partir da placa
      final vehicleData = await DatabaseHelper().getVehicleData(placa);

      // Verifica se os dados do veículo foram encontrados
      if (vehicleData != null) {
        showVehicleDetails(vehicleData); // Mostra os detalhes do veículo
      } else {
        showRegistrationForm(placa); // Mostra o formulário de registro
      }
    } catch (e) {
      // Trata erros que podem ocorrer durante a execução
      print('Erro ao processar a placa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocorreu um erro ao processar a placa.')),
      );
    }
  }

  void showEditOptionDialog(BuildContext context, String placa) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Deseja digitar a placa?',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Escolha se deseja digitar a placa manualmente ou fazer uma nova captura.',
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  editPlateDialog(context, placa);
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16), // Ajuste de padding
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  // Ícone e texto alinhados à esquerda
                  children: [
                    Icon(Icons.edit, color: accentColor),
                    SizedBox(width: 8),
                    // Espaçamento maior entre o ícone e o texto
                    Text('Digitar Placa'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage();
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16), // Ajuste de padding
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  // Ícone e texto alinhados à esquerda
                  children: [
                    Icon(Icons.camera_alt, color: accentColor),
                    SizedBox(width: 8),
                    // Espaçamento maior entre o ícone e o texto
                    Text('Nova Captura'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16), // Ajuste de padding
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  // Ícone e texto alinhados à esquerda
                  children: [
                    Icon(Icons.cancel, color: accentColor),
                    SizedBox(width: 8),
                    // Espaçamento maior entre o ícone e o texto
                    Text('Cancelar'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void editPlateDialog(BuildContext context, String placa) {
    TextEditingController plateController = TextEditingController(
        text: transform(placa));
    bool isButtonEnabled = placa.length == 7;

    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Digitar Placa',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                // Defina uma largura e altura máxima para o conteúdo
                width: 300,
                constraints: BoxConstraints(
                  maxHeight: 200, // Limita a altura máxima do conteúdo
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: plateController,
                        maxLength: 7,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Insira a placa correta',
                          labelStyle: TextStyle(color: primaryColor),
                          counterText: "",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            plateController.value =
                                plateController.value.copyWith(
                                  text: transform(value),
                                  selection: TextSelection.collapsed(
                                      offset: value.length),
                                );
                            isButtonEnabled =
                                value.length == 7 && validFormatPlate(value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Posiciona os botões nas extremidades
                  children: [
                    // Botão Cancelar
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: accentColor),
                          SizedBox(width: 8),
                          Text('Cancelar'),
                        ],
                      ),
                    ),
                    // Botão Verificar
                    TextButton(
                      onPressed: isButtonEnabled
                          ? () {
                        //String updatedPlaca = plateController.text;
                        String? updatedPlaca = buscaValorPlaca(plateController
                            .text);
                        Navigator.of(context).pop();
                        showConfirmationDialog(context, updatedPlaca!);
                      }
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: accentColor),
                          SizedBox(width: 8),
                          Text('Verificar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showVehicleDetails(Map<String, dynamic> vehicleData) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Detalhes do Veículo',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView( // Adiciona rolagem se necessário
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Placa:', style: TextStyle(color: primaryColor)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        vehicleData['placa'] ?? '',
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Proprietário:', style: TextStyle(color: primaryColor)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        vehicleData['nome'] ?? '',
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Celular:', style: TextStyle(color: primaryColor)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        vehicleData['telefone'] ?? '',
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WhatsApp:', style: TextStyle(color: primaryColor)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        vehicleData['whatsapp'] ?? '',
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (vehicleData['telefone'] != null &&
                            vehicleData['telefone'].isNotEmpty) {
                          makeCall(vehicleData['telefone'], context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                                'Número de celular não disponível.')),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.phone, color: accentColor),
                          SizedBox(width: 8),
                          Text('Ligar'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10), // Espaçamento entre os botões
                    TextButton(
                      onPressed: () {
                        if (vehicleData['whatsapp'] != null &&
                            vehicleData['whatsapp'].isNotEmpty) {
                          openWhatsApp(vehicleData['whatsapp'], context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                                'Número do WhatsApp não disponível.')),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          FaIcon(FontAwesomeIcons.whatsapp, color: accentColor),
                          SizedBox(width: 8),
                          Text('WhatsApp'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10), // Espaçamento entre os botões
                    TextButton(
                      onPressed: () async {
                        // Captura a nova placa editada
                        String? updatedPlaca = await showEditForm(vehicleData);

                        if (updatedPlaca != null && updatedPlaca.isNotEmpty) {
                          // Fecha o diálogo de detalhes
                          Navigator.of(context).pop();

                          // Atualiza os detalhes com a nova placa
                          refreshVehicleDetails(
                              updatedPlaca); // Passa a nova placa para a função de atualização
                        } else {
                          // Mostra uma mensagem de erro se a placa for inválida
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('A placa não pode estar vazia.')),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.edit, color: accentColor),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10), // Espaçamento entre os botões
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fecha o diálogo
                        showDeleteConfirmationDialog(vehicleData['placa']);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.delete, color: accentColor),
                          SizedBox(width: 8),
                          Text('Remover'),
                        ],
                      ),
                    ),
                    SizedBox(height: 20), // Espaçamento antes do botão fechar
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fecha o diálogo
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: closeButtonTextColor,
                        // Cor do texto
                        backgroundColor: closeButtonColor,
                        // Cor do fundo do botão
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12, // Ajustando o espaçamento do botão
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: closeButtonIconColor),
                          // Ícone de fechar
                          SizedBox(width: 8),
                          // Espaçamento entre o ícone e o texto
                          Text('Fechar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showRegistrationForm(String placa) {
    String nome = '';
    var telefoneController = MaskedTextController(mask: '+55 (00) 00000-0000');
    var whatsappController = MaskedTextController(mask: '+55 (00) 00000-0000');
    bool isButtonEnabled = false;

    void validateFields() {
      setState(() {
        isButtonEnabled = validarCampos(nome, telefoneController, whatsappController);
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Cadastrar Veículo',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Apenas o conteúdo do formulário fica rolável
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Placa: $placa',
                                  style: TextStyle(color: primaryColor),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      nome = value.trim().isEmpty
                                          ? ''
                                          : transformPrimeiraLetraNome(value)
                                          .trim();
                                      validateFields();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Proprietário',
                                    labelStyle: TextStyle(color: primaryColor),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: primaryColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: accentColor),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: telefoneController,
                                  onChanged: (value) {
                                    setState(() {
                                      validateFields();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Celular',
                                    labelStyle: TextStyle(color: primaryColor),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: primaryColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: accentColor),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: whatsappController,
                                  onChanged: (value) {
                                    setState(() {
                                      validateFields();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'WhatsApp',
                                    labelStyle: TextStyle(color: primaryColor),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: primaryColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: accentColor),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, color: accentColor),
                      SizedBox(width: 8),
                      Text('Cancelar'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: isButtonEnabled
                      ? () async {
                    try {
                      await DatabaseHelper().insertVehicle(
                        placa,
                        nome,
                        telefoneController.text,
                        whatsappController.text,
                      );
                      Navigator.of(context).pop();
                      showSuccessDialog(
                          context, 'Os dados foram cadastrados com sucesso.');
                    } catch (e) {
                      showErrorDialog(context, 'Erro ao cadastrar veículo: $e');
                    }
                  }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, color: accentColor),
                      SizedBox(width: 8),
                      Text('Salvar'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showSuccessDialog(BuildContext context, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: buttonIconColor, size: 30),
              SizedBox(width: 10),
              Text(
                'Sucesso!',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(message,
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: primaryColor, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: buttonIconColor, size: 30),
              SizedBox(width: 10),
              Text(
                'Erro!',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(message,
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: primaryColor, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> showEditForm(Map<String, dynamic> vehicleData) async {
    String placa = vehicleData['placa'];

    TextEditingController placaController = TextEditingController(
        text: vehicleData['placa']);
    TextEditingController nomeController = TextEditingController(
        text: vehicleData['nome']);
    MaskedTextController telefoneController = MaskedTextController(
        mask: '+55 (00) 00000-0000', text: vehicleData['telefone']);
    MaskedTextController whatsappController = MaskedTextController(
        mask: '+55 (00) 00000-0000', text: vehicleData['whatsapp']);

    bool isButtonEnabled = false;

    // Função para validar se o botão pode ser habilitado
    void validateFields(StateSetter setState) {
      setState(() {
        String nome = nomeController.text;
        bool placaValida = placaController.text.length == 7 &&
            validFormatPlate(placaController.text);
        bool camposValidos = validarCampos(
            nome, telefoneController, whatsappController);
        isButtonEnabled = placaValida && camposValidos;
      });
    }

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Editar Veículo',
                style: TextStyle(
                    color: primaryColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: placaController,
                        decoration: InputDecoration(
                          labelText: 'Placa',
                          labelStyle: TextStyle(color: primaryColor),
                          counterText: "",
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 7,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        onChanged: (value) {
                          setState(() {
                            validateFields(setState);
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nomeController,
                        decoration: InputDecoration(
                          labelText: 'Proprietário',
                          labelStyle: TextStyle(color: primaryColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            nomeController.value =
                                nomeController.value.copyWith(
                                  text: transformPrimeiraLetraNome(value),
                                  selection: TextSelection.collapsed(
                                      offset: value.length),
                                );
                            validateFields(setState);
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: telefoneController,
                        onChanged: (value) {
                          validateFields(setState);
                        },
                        decoration: InputDecoration(
                          labelText: 'Celular',
                          labelStyle: TextStyle(color: primaryColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: whatsappController,
                        onChanged: (value) {
                          validateFields(setState);
                        },
                        decoration: InputDecoration(
                          labelText: 'WhatsApp',
                          labelStyle: TextStyle(color: primaryColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fechar o diálogo
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, color: accentColor),
                      SizedBox(width: 8),
                      Text('Cancelar'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: isButtonEnabled
                      ? () async {
                    try {
                      // Atualiza os valores no banco de dados
                      await DatabaseHelper().updateVehicle(
                        placa,
                        placaController.text,
                        nomeController.text,
                        telefoneController.text,
                        whatsappController.text,
                      );
                      Navigator.of(context).pop(
                          placaController.text); // Retorna a nova placa
                    } catch (e) {
                      print('Erro: $e');
                      showErrorDialog(context, 'Erro ao atualizar veículo: $e');
                    }
                  }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, color: accentColor),
                      SizedBox(width: 8),
                      Text('Salvar'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void refreshVehicleDetails(String placa) async {
    // Obtém os dados atualizados do veículo com base na placa
    final updatedVehicleData = await DatabaseHelper().getVehicleByPlaca(placa);

    // Verifica se os dados do veículo foram encontrados
    if (updatedVehicleData != null) {
      showVehicleDetails(updatedVehicleData); // Exibe os detalhes do veículo
    } else {
      // Exibe uma mensagem de erro se o veículo não for encontrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veículo não encontrado.',
            style: TextStyle(
                color: primaryColor), // Usando constante para cor do texto
          ),
          backgroundColor: secondaryColor, // Usando constante para cor de fundo
        ),
      );
    }
  }

  Future<void> verificarPlacasCadastradas() async {
    final List<Map<String, dynamic>> placas = await DatabaseHelper()
        .getAllVehicles();

    // Função para construir o botão de fechar na parte inferior
    Widget buildCloseButton(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: secondaryColor,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 4,
            // Elevação para sombreamento do botão
            shadowColor: Colors.black.withOpacity(
                0.4), // Cor da sombra do botão
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close, color: buttonIconColor), // Ícone
              SizedBox(width: 8),
              Text('Fechar', style: TextStyle(color: buttonTextColor)), // Texto
            ],
          ),
        ),
      );
    }

    // Função para construir o conteúdo do modal
    Widget buildModalContent(BuildContext context) {
      if (placas.isEmpty) {
        return Center(
          child: Text('Nenhuma placa cadastrada.',
              style: TextStyle(color: contentTextColor)),
        );
      } else {
        return ListView.builder(
          padding: EdgeInsets.only(top: 16),
          itemCount: placas.length,
          itemBuilder: (context, index) {
            final vehicle = placas[index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: secondaryColor, // Mesma cor do botão "Fechar"
                borderRadius: BorderRadius.circular(6),
                boxShadow: [ // Sombra suave para os itens da lista
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(2, 4), // Posição da sombra
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  vehicle['placa'] ?? 'Placa não disponível',
                  style: TextStyle(color: plateTextColor),
                ),
                subtitle: Text(
                  vehicle['nome'] ?? 'Nome não disponível',
                  style: TextStyle(color: nameTextColor),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showVehicleDetails(vehicle);
                },
              ),
            );
          },
        );
      }
    }

    // Exibir o modal em tela cheia
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Remove a cor de fundo padrão
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFF2E8), // A cor de fundo do modal
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Scaffold(
            // Fundo transparente para o Scaffold
            body: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Text(
                    'Placas Cadastradas',
                    style: TextStyle(color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Expanded(child: buildModalContent(context)),
                  // Lista de placas
                ],
              ),
            ),
            bottomNavigationBar: buildCloseButton(context), // Botão fechar
          ),
        );
      },
    );
  }

  void showDeleteConfirmationDialog(String placa) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora do diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          //backgroundColor: Colors.white, // Cor de fundo do dialog
          title: Text(
            'Confirmação de Exclusão',
            style: TextStyle(color: titleColor,
              fontWeight: FontWeight.bold,
            ), // Cor do texto do título
          ),
          content: Text(
            'Você tem certeza que deseja remover o registro da placa: $placa?',
            style: TextStyle(
                color: contentTextColor), // Cor do texto do conteúdo
          ),
          actions: [
            // Botão "Sim"
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteVehicle(placa);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                      'Registro da placa $placa removido com sucesso.')),
                );
                Navigator.of(context).pop(); // Fecha o diálogo
                verificarPlacasCadastradas(); // Atualiza a lista de placas cadastradas
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto
                backgroundColor: buttonBackgroundColor, // Cor de fundo
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: buttonIconColor),
                  // Ícone de confirmação
                  SizedBox(width: 8),
                  Text('Sim'),
                  // Texto do botão
                ],
              ),
            ),
            // Botão "Não"
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              style: TextButton.styleFrom(
                foregroundColor: buttonTextColor, // Cor do texto
                backgroundColor: buttonBackgroundColor, // Cor de fundo
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, color: buttonIconColor),
                  // Ícone de cancelamento
                  SizedBox(width: 8),
                  Text('Não'),
                  // Texto do botão
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String plate = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Estacionamento',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset: true,
      // Ajusta o layout quando o teclado aparece
      body: SingleChildScrollView( // Permite rolar o conteúdo quando necessário
        padding: EdgeInsets.only(bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom), // Ajusta o conteúdo ao teclado
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo do estacionamento
              Icon(
                Icons.local_parking, // Ou use Image.asset('path/to/logo.png')
                color: primaryColor,
                size: 100, // Ajuste o tamanho do ícone
              ),
              SizedBox(height: 16), // Espaçamento entre o ícone e o título

              // Texto Estacionamento
              Text(
                'Estacionamento',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 40), // Espaçamento entre o título e os botões

              // Botão para Capturar Placa
              Container(
                width: 200, // Largura fixa para uniformidade
                child: ElevatedButton(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonBackgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          30), // Bordas arredondadas
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: buttonIconColor),
                      SizedBox(width: 8),
                      Text('Capturar Placa', style: buttonTextStyle),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Botão para Cadastrar Placas
              Container(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    editPlateDialog(context, plate);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonBackgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: buttonIconColor),
                      SizedBox(width: 8),
                      Text('Cadastrar Placas', style: buttonTextStyle),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Botão para Placas Cadastradas
              Container(
                width: 200,
                child: ElevatedButton(
                  onPressed: verificarPlacasCadastradas,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonBackgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list, color: buttonIconColor),
                      SizedBox(width: 8),
                      Text('Placas Cadastradas', style: buttonTextStyle),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Texto de reconhecimento
              Text(recognizedText, style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}