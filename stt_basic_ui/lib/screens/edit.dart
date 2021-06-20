import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sttbasicui/database/memo.dart';
import 'package:sttbasicui/database/db.dart';

//이전 페이지에서 id, path를 넘겨받음
class EditPage extends StatefulWidget {
  EditPage({Key key, this.id, this.path}) : super(key: key);
  final String id;
  final String path;

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  //flutter channel 설정 => 안바꾸면 API 작동X
  static const platform = const MethodChannel("com.example.sttbasicui");
  BuildContext _context;

  int record = 0;
  String title = '';
  String text = '';
  String createTime = '';
  String audioFile = '';

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          actions: <Widget>[
            //오디오 재생 버튼
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                playaudio(widget.path);
              },
            ),
            //메모 저장 버튼
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: updateDB,
            ),

          ],
        ),
        body: Padding(padding: EdgeInsets.all(20), child: loadBuilder()));
  }

  //메모 불러오기 함기
  Future<List<Memo>> loadMemo(String id) async {
    DBHelper sd = DBHelper();
    return await sd.findMemo(id);
  }

  //main body 부분 함수
  loadBuilder() {
    return FutureBuilder<List<Memo>>(
      //loadmemo 함수에 id 제공
      future: loadMemo(widget.id),
      builder: (BuildContext context, AsyncSnapshot<List<Memo>> snapshot) {
        //data가 존재하는지 확인
        if (snapshot.data == null || snapshot.data == []) {
          //없으면 에러 문구 출력
          return Container(child: Text("데이터를 불러올 수 없습니다."));
        } else {
          //data 문구열을 memo에 저장
          Memo memo = snapshot.data[0];

          var tecTitle = TextEditingController();
          title = memo.title;
          tecTitle.text = title;

          var tecText = TextEditingController();
          text = memo.text;
          tecText.text = text;

          createTime = memo.createTime;
          audioFile = memo.editTime;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              //제목 입력 칸
              TextField(
                controller: tecTitle,
                maxLines: 2,
                onChanged: (String title) {
                  this.title = title;
                },
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                //obscureText: true,
                decoration: InputDecoration(
                  //border: OutlineInputBorder(),
                  hintText: '메모의 제목을 적어주세요.',
                ),
              ),
              Padding(padding: EdgeInsets.all(10)),
              //내용 입력 칸
              TextField(
                controller: tecText,
                maxLines: 8,
                onChanged: (String text) {
                  this.text = text;
                },
                //obscureText: true,
                decoration: InputDecoration(
                  //border: OutlineInputBorder(),
                  hintText: '메모의 내용을 적어주세요.',
                ),
              ),
            ],
          );
        }
      },
    );
  }

  //database 업데이트
  void updateDB() {
    DBHelper sd = DBHelper();

    //업데이트할 매모 정보 입력
    var fido = Memo(
        id: widget.id,
        // String
        title: this.title,
        text: this.text,
        createTime: this.createTime,
        editTime: this.audioFile
    );

    sd.updateMemo(fido);    //database 업데이트
    Navigator.pop(_context);  //이전 페이지로 이동
  }

  //오디오 재생 함수
  void playaudio(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    print('playaudio$path');
    await audioPlayer.play(path, isLocal: true);
    print('record : $record');
  }
}