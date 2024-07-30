import 'package:flutter/material.dart';
import 'package:after_layout/after_layout.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "my_database.db";
  static final table = 'my_table';

  static final columnId = '_id';
  static final columnName = 'name';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _databaseName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await database;
    int id = row[columnId];
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}

// Clase principal del Home
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with AfterLayoutMixin<Home> {
  List<Map<String, dynamic>> _data = [];

  @override
  void afterFirstLayout(BuildContext context) async {
    await DatabaseHelper.instance.database;
    _fetchData();
  }

  Future<void> _fetchData() async {
    _data = await DatabaseHelper.instance.queryAllRows();
    setState(() {});
  }

  Future<void> _addNewItem() async {
    await _showItemDialog();
    _fetchData();
  }

  Future<void> _updateItem(int id, String currentName) async {
    await _showItemDialog(id: id, currentName: currentName);
    _fetchData();
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.delete(id);
    _fetchData();
  }

  Future<void> _showItemDialog({int? id, String? currentName}) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(id == null ? 'Add New Item' : 'Update Item'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Item Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  if (id == null) {
                    await DatabaseHelper.instance
                        .insert({'name': controller.text});
                  } else {
                    await DatabaseHelper.instance
                        .update({'_id': id, 'name': controller.text});
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite Flutter'),
      ),
      body: ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_data[index][DatabaseHelper.columnName]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _updateItem(
                      _data[index][DatabaseHelper.columnId],
                      _data[index][DatabaseHelper.columnName]),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () =>
                      _deleteItem(_data[index][DatabaseHelper.columnId]),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}
