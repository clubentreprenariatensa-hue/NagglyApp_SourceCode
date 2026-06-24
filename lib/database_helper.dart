import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('naggly_afis.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table principale de l'Index Inversé Géométrique
    // signature = "L1_L2_L3" (Les longueurs quantifiées du triangle)
    // animal_id = L'ID de la vache
    await db.execute('''
      CREATE TABLE inverted_index (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        signature TEXT NOT NULL,
        animal_id TEXT NOT NULL
      )
    ''');
    
    // Création de l'index B-Tree ultra rapide sur les signatures
    await db.execute('CREATE INDEX idx_signature ON inverted_index (signature)');
  }

  /// Enregistrement d'une nouvelle vache (Insertion des signatures géométriques)
  Future<void> registerAnimal(String animalId, List<String> signatures) async {
    final db = await instance.database;
    Batch batch = db.batch();
    
    for (String sig in signatures) {
      batch.insert('inverted_index', {
        'signature': sig,
        'animal_id': animalId
      });
    }
    
    await batch.commit(noResult: true);
  }

  /// Identification (1:N) instantanée grâce à l'index B-Tree de SQLite
  Future<Map<String, int>> identify(List<String> querySignatures) async {
    final db = await instance.database;
    if (querySignatures.isEmpty) return {};
    
    // On regroupe les signatures pour faire un seul IN query optimisé
    String placeholders = List.filled(querySignatures.length, '?').join(',');
    
    // Recherche de toutes les vaches qui partagent au moins un triangle
    final result = await db.rawQuery('''
      SELECT animal_id, COUNT(*) as votes
      FROM inverted_index
      WHERE signature IN ($placeholders)
      GROUP BY animal_id
      ORDER BY votes DESC
      LIMIT 5
    ''', querySignatures);

    Map<String, int> votes = {};
    for (var row in result) {
      votes[row['animal_id'] as String] = row['votes'] as int;
    }
    return votes;
  }
}
