import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;

  // Getter para o banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Se o banco não existir, crie-o
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'vehicle_database.db');

    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE vehicles(placa TEXT PRIMARY KEY, nome TEXT, telefone TEXT, whatsapp TEXT)",
        );
      },
      version: 1,
    );
  }

  // Método para inserir dados
  Future<void> insertVehicle(String placa, String nome, String telefone, String whatsapp) async {
    final db = await database;
    await db.insert(
      'vehicles',
      {'placa': placa, 'nome': nome, 'telefone': telefone, 'whatsapp': whatsapp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para buscar dados
  Future<Map<String, dynamic>?> getVehicleData(String placa) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'placa = ?',
      whereArgs: [placa],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<void> deleteVehicle(String placa) async {
    final db = await database; // Obtenha a instância do banco de dados

    await db.delete(
      'vehicles', // Nome da tabela
      where: 'placa = ?', // Condição para a exclusão
      whereArgs: [placa], // Argumentos da condição
    );
  }

  Future<Map<String, dynamic>?> getVehicleByPlaca(String placa) async {
    final db = await database; // Assumindo que você já tenha uma função que retorna o banco de dados
    List<Map<String, dynamic>> results = await db.query(
      'vehicles', // substitua pelo nome da sua tabela
      where: 'placa = ?',
      whereArgs: [placa],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<void> updateVehicle(String oldPlaca, String newPlaca, String nome, String telefone, String whatsapp) async {
    final db = await database;

    // Deletar o veículo existente
    await db.delete(
      'vehicles',
      where: 'placa = ?',
      whereArgs: [oldPlaca],
    );

    // Inserir um novo veículo com a nova placa
    await insertVehicle(newPlaca, nome, telefone, whatsapp); // Adicionando 'await' aqui

  }

  // Método para buscar todos os veículos cadastrados
  Future<List<Map<String, dynamic>>> getAllVehicles() async {
    final db = await database;
    return await db.query('vehicles');
  }
}