import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sttbasicui/database/memo.dart';

final String tableName = 'memos';

class DBHelper {
  var _db;

  Future<Database> get database async {
    if (_db != null) return _db;
    _db = openDatabase(
      // 데이터베이스 경로를 지정
      join(await getDatabasesPath(), 'memos.db'),
      // 데이터베이스가 처음 생성될 때, dog를 저장하기 위한 테이블을 생성
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE memos(id TEXT PRIMARY KEY, title TEXT, text TEXT, createTime TEXT, editTime TEXT)",
        );
      },
      //onCreate 함수에서 수행되며 데이터베이스 업그레이드와 다운그레이드를 수행하기 위한 경로를 제공
      version: 1,
    );
    return _db;
  }

  Future<void> insertMemo(Memo memo) async {
    final db = await database;

    // Memo를 올바른 테이블에 추가
    // `conflictAlgorithm`을 명시
    // 만약 동일한 memo가 여러번 추가되면, 이전 데이터를 덮어씀
    await db.insert(
      tableName,
      memo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Memo>> memos() async {
    final db = await database;

    // 모든 Memo를 얻기 위해 테이블에 질의
    final List<Map<String, dynamic>> maps = await db.query('memos');

    // List<Map<String, dynamic>를 List<Memo>으로 변환
    return List.generate(maps.length, (i) {
      return Memo(
        id: maps[i]['id'],
        title: maps[i]['title'],
        text: maps[i]['text'],
        createTime: maps[i]['createTime'],
        editTime: maps[i]['editTime'],
      );
    });
  }

  Future<void> updateMemo(Memo memo) async {
    final db = await database;

    // 주어진 Memo를 수정
    await db.update(
      tableName,
      memo.toMap(),
      // Memo의 id가 일치하는 지 확인
      where: "id = ?",
      // Memo의 id를 whereArg로 넘겨 SQL injection을 방지
      whereArgs: [memo.id],
    );
  }

  Future<void> deleteMemo(String id) async {
    final db = await database;

    // 데이터베이스에서 Memo를 삭제
    await db.delete(
      tableName,
      // 특정 memo를 제거하기 위해 `where` 절을 사용
      where: "id = ?",
      // Memo의 id를 where의 인자로 넘겨 SQL injection을 방지
      whereArgs: [id],
    );
  }

  Future<List<Memo>> findMemo(String id) async {
    final db = await database;

    // 모든 Memo를 얻기 위해 테이블에 질의
    final List<Map<String, dynamic>> maps =
    await db.query('memos', where: 'id = ?', whereArgs: [id]);

    // List<Map<String, dynamic>를 List<Memo>으로 변환
    return List.generate(maps.length, (i) {
      return Memo(
        id: maps[i]['id'],
        title: maps[i]['title'],
        text: maps[i]['text'],
        createTime: maps[i]['createTime'],
        editTime: maps[i]['editTime'],
      );
    });
  }
}
