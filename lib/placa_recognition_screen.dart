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
  _PlacaRecognitionScreenState createState() => _PlacaRecognitionScreenState();
}

class _PlacaRecognitionScreenState extends State<PlacaRecognitionScreen> {
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
  //static const Color textColorDark = Color(0xFF555555);
  //static const Color textColorLight = Color(0xFF333333);
  static const Color accentColor = Color(0xFFE47724);

  void makeCall(String phone, BuildContext context) async {
    final Uri url = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showCallErrorSnackbar(context, phone);
      }
    } catch (e) {
      _showCallErrorSnackbar(context, phone);
    }
  }

  void _showCallErrorSnackbar(BuildContext context, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Não foi possível ligar para $phone'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
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
        _showErrorSnackbar(context, whatsapp);
      }
    } catch (e) {
      _showErrorSnackbar(context, whatsapp);
    }
  }

  void _showErrorSnackbar(BuildContext context, String whatsapp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Não foi possível abrir o WhatsApp para $whatsapp'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
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

  void showMessage(String message) {
    setState(() {
      recognizedText = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (recognizedText == message) {
        setState(() {
          recognizedText = '';
        });
      }
    });
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
        text = buscaValorPlaca(
            text); // Normaliza ou converte a placa para o formato desejado
        showConfirmationDialog(context, text); // Exibe o diálogo de confirmação
        showMessage('Placa reconhecida: $text'); // Mensagem para o usuário
      } else {
        showMessage(
            'Formato de placa inválido. Tente novamente.'); // Notificação de erro
        showRetryDialog(context); // Exibe o diálogo para tentar novamente
      }
    }
  }

  void showRetryDialog(BuildContext context) {
    String placa = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Cor de fundo do diálogo
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
      builder: (BuildContext context) {
        return AlertDialog(
          //backgroundColor: Colors.white, // Cor de fundo do diálogo
          title: Text(
            'Placa Capturada',
            style: TextStyle(color: titleColor, fontWeight: FontWeight.bold), // Usa a cor do título
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
              padding: const EdgeInsets.symmetric(vertical: 4.0), // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  editPlateDialog(context, placa);
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, color: accentColor),
                    SizedBox(width: 8), // Espaçamento entre o ícone e o texto
                    Text('Digitar Placa'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0), // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage();
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: accentColor),
                    SizedBox(width: 8), // Espaçamento entre o ícone e o texto
                    Text('Nova Captura'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0), // Espaço entre botões
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: accentColor),
                    SizedBox(width: 8), // Espaçamento entre o ícone e o texto
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
    //TextEditingController plateController = TextEditingController(text: placa.toUpperCase());
    TextEditingController plateController = TextEditingController(text: transform(placa));
    bool isButtonEnabled = placa.length == 7;

    showDialog(
      context: context,
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
              content: TextField(
                controller: plateController,
                maxLength: 7, // Limita a entrada a 7 caracteres
                textCapitalization: TextCapitalization.characters, // Converte automaticamente para maiúsculas
                decoration: InputDecoration(
                  labelText: 'Insira a placa correta',
                  labelStyle: TextStyle(color: primaryColor),
                  counterText: "", // Remove o contador de caracteres exibido abaixo do campo
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Permite apenas letras e números
                ],
                onChanged: (value) {
                  setState(() {
                    // Converte para maiúsculas e atualiza o valor do controlador
                    plateController.value = plateController.value.copyWith(
                      text: transform(value), // Usando a classe PlateTransformer
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                    isButtonEnabled = value.length == 7; // Verifica se a quantidade de caracteres é igual a 7
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: isButtonEnabled
                      ? () {
                    String updatedPlaca = plateController.text;
                    Navigator.of(context).pop();
                    showConfirmationDialog(context, updatedPlaca);
                  }
                      : null, // Desabilita o botão se o campo não tiver exatamente 7 caracteres
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
            );
          },
        );
      },
    );
  }

  void showVehicleDetails(Map<String, dynamic> vehicleData) {
    showDialog(
      context: context,
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
                    Text('Proprietário:', style: TextStyle(color: primaryColor)),
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
                    Text('Telefone:', style: TextStyle(color: primaryColor)),
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
                            SnackBar(content: Text('Número de telefone não disponível.')),
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
                            SnackBar(content: Text('Número do WhatsApp não disponível.')),
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
                        await showEditForm(vehicleData);
                        Navigator.of(context).pop();
                        refreshVehicleDetails(vehicleData['placa']);
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
                        foregroundColor: closeButtonTextColor, // Cor do texto
                        backgroundColor: closeButtonColor, // Cor do fundo do botão
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12, // Ajustando o espaçamento do botão
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: closeButtonIconColor), // Ícone de fechar
                          SizedBox(width: 8), // Espaçamento entre o ícone e o texto
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

    // Função para verificar se o botão "Salvar" pode ser habilitado
    void validateFields() {
      setState(() {
        isButtonEnabled = validarCampos(nome, telefoneController, whatsappController);
      });
    }

    showDialog(
      context: context,
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Placa: $placa',
                      style: TextStyle(color: primaryColor),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          // Verifica se o campo está vazio
                          if (value.trim().isEmpty) {
                            nome = ''; // Atualiza a variável nome para uma string vazia
                          } else {
                            nome = transformPrimeiraLetraNome(value).trim(); // Transforma e remove espaços
                          }
                          validateFields(); // Chama a função para validar os campos
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Nome do Proprietário',
                        labelStyle: TextStyle(color: primaryColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
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
                        labelText: 'Telefone',
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
                        setState(() {
                          validateFields();
                        });
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
              actions: [
                TextButton(
                  onPressed: isButtonEnabled
                      ? () {
                    Navigator.of(context).pop();
                    DatabaseHelper().insertVehicle(
                      placa,
                      nome,
                      telefoneController.text,
                      whatsappController.text,
                    );
                    showMessage('Dados salvos com sucesso!');
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
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showEditForm(Map<String, dynamic> vehicleData) async {
    String placa = vehicleData['placa'];
    var placaController = TextEditingController(text: vehicleData['placa']);
    var nomeController = TextEditingController(text: vehicleData['nome']);
    var telefoneController = MaskedTextController(
      mask: '+55 (00) 00000-0000',
      text: vehicleData['telefone'],
    );
    var whatsappController = MaskedTextController(
      mask: '+55 (00) 00000-0000',
      text: vehicleData['whatsapp'],
    );

    bool isButtonEnabled = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void validateButton() {
              setState(() {
                isButtonEnabled = placaController.text.length == 7 &&
                    validarCampos(nomeController.text, telefoneController.text, whatsappController.text);
              });
              print('Placa: ${placaController.text}, Nome: ${nomeController.text}, Telefone: ${telefoneController.text}, Whatsapp: ${whatsappController.text}');
              print('isButtonEnabled >>>>>>>>>>>>> : $isButtonEnabled');
            }

            return AlertDialog(
              title: Text(
                'Editar Veículo',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Placa',
                        labelStyle: TextStyle(color: primaryColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      controller: placaController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 7,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(7), // Limita a 7 caracteres
                      ],
                      onChanged: (value) {
                        placaController.value = placaController.value.copyWith(
                          text: transform(value),
                          selection: TextSelection.collapsed(offset: value.length),
                        );
                        validateButton();
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        labelStyle: TextStyle(color: primaryColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      controller: nomeController,
                      onChanged: (value) {
                        nomeController.value = nomeController.value.copyWith(
                          text: transformPrimeiraLetraNome(value),
                          selection: TextSelection.collapsed(offset: value.length),
                        );
                        validateButton();
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: telefoneController,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        labelStyle: TextStyle(color: primaryColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => validateButton(),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: whatsappController,
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
                      onChanged: (_) => validateButton(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      await DatabaseHelper().updateVehicle(
                        placa,
                        placaController.text,
                        nomeController.text,
                        telefoneController.text,
                        whatsappController.text,
                      );
                      vehicleData['placa'] = placaController.text;
                      vehicleData['nome'] = nomeController.text;
                      vehicleData['telefone'] = telefoneController.text;
                      vehicleData['whatsapp'] = whatsappController.text;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veículo atualizado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao atualizar veículo: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: secondaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

    // Função para construir o botão de fechar
    Widget buildCloseButton(BuildContext context) {
      return TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          foregroundColor: closeButtonTextColor, // Cor do texto
          backgroundColor: closeButtonColor, // Cor do fundo do botão
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Ajustando o espaçamento do botão
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: closeButtonIconColor), // Ícone de fechar
            SizedBox(width: 8), // Espaçamento entre o ícone e o texto
            Text('Fechar'),
          ],
        ),
      );
    }

    // Função para construir o conteúdo do diálogo
    Widget buildDialogContent(BuildContext context) {
      if (placas.isEmpty) {
        return Text('Nenhuma placa cadastrada.',
            style: TextStyle(color: contentTextColor)); // Texto do conteúdo
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: placas.map((vehicle) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 8), // Espaçamento entre os registros
              decoration: BoxDecoration(
                color: Colors.white, // Cor de fundo do item
                border: Border.all(color: primaryColor, width: 1), // Borda
                borderRadius: BorderRadius.circular(8), // Bordas arredondadas
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2), // Cor da sombra
                    spreadRadius: 1, // Raio de espalhamento da sombra
                    blurRadius: 5, // Desfoque da sombra
                    offset: Offset(0, 3), // Deslocamento da sombra
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  vehicle['placa'],
                  style: TextStyle(color: plateTextColor),
                ), // Cor do texto da placa
                subtitle: Text(
                  vehicle['nome'],
                  style: TextStyle(color: nameTextColor),
                ), // Cor do texto do nome
                onTap: () {
                  Navigator.of(context).pop();
                  showVehicleDetails(vehicle);
                },
              ),
            );
          }).toList(),
        );
      }
    }

    // Construindo o diálogo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //backgroundColor: Colors.white,
          // Cor de fundo do dialog
          title: Text(
              'Placas Cadastradas', style: TextStyle(color: titleColor)),
          // Cor do texto do título
          content: buildDialogContent(context),
          // Usando a função para construir o conteúdo
          actions: [
            buildCloseButton(context), // Usando a função para criar o botão
          ],
        );
      },
    );
  }

  void showDeleteConfirmationDialog(String placa) {
    showDialog(
      context: context,
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
      body: Center(
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
    );
  }
}