import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sttbasicui/database/memo.dart';
import 'package:sttbasicui/database/db.dart';
import 'package:sttbasicui/screens/edit.dart';
import 'package:flutter/services.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

//이전 페이지에서 id, path를 넘겨받음
class ViewPage extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  ViewPage({localFileSystem, this.id, this.path})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  final String path;
  final String id;

  @override
  _ViewPageState createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  //flutter channel 설정
  static const platform = const MethodChannel("com.example.sttbasicui");
  BuildContext _context;
  String clipboard;
  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          //내용 클립보드 복사 버튼
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: (){
              Clipboard.setData(ClipboardData(text: clipboard));
              Fluttertoast.showToast(
                  msg: "클립보드에 복사되었습니다.",
                  timeInSecForIosWeb: 1
              );
            },
          ),
          //메모 수정 버튼
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => EditPage(id: widget.id, path: widget.path)));
            },
          ),
          //메모 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: showAlertDialog,
          ),
        ],
      ),
      //main body -> loadBuilder 함수
      body: Padding(padding: EdgeInsets.all(20), child: loadBuilder()),
      //음성 재생 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.play_arrow),
        onPressed: () {
          playaudio(widget.path);
        },
      )
    );
  }

  //메모 data 불러오는 함수
  Future<List<Memo>> loadMemo(String id) async {
    DBHelper sd = DBHelper();
    return await sd.findMemo(id);
  }

  //main body 함수
  loadBuilder() {
    return FutureBuilder<List<Memo>>(
      future: loadMemo(widget.id),
      builder: (BuildContext context, AsyncSnapshot<List<Memo>> snapshot) {
        //데이터가 있는지 확인
        if (snapshot.data == null || snapshot.data == []) {
          return Container(child: Text("데이터를 불러올 수 없습니다."));
        } else {
          Memo memo = snapshot.data[0];
          this.clipboard = memo.text;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              //제목 칸 생성
              Container(
                height: 70,
                child: SingleChildScrollView(
                  child: Text(
                    memo.title,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              //메모 생성 시간 출력 칸 생성
              Text(
                "메모 만든 시간: " + memo.createTime.split('.')[0],
                style: TextStyle(fontSize: 11),
                textAlign: TextAlign.end,
              ),
              Padding(padding: EdgeInsets.all(10)),
              //내용 칸 생성
              Expanded(
                child: SingleChildScrollView(
                  child: Text(memo.text),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  //메모 data 삭제 함수
  Future<void> deleteMemo(String id) async {
    DBHelper sd = DBHelper();
    await sd.deleteMemo(id);
  }

  //삭제 경고 메시지 출력 함수
  void showAlertDialog() async {
    await showDialog(
      context: _context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 경고'),
          content: Text("정말 삭제하시겠습니까?\n삭제된 메모는 복구되지 않습니다."),
          actions: <Widget>[
            FlatButton(
              child: Text('삭제'),
              onPressed: () {
                Navigator.pop(context, "삭제");
                //음성 파일 삭제
                File file = widget.localFileSystem.file(widget.path);
                file.delete();
                //메모 data 삭제
                deleteMemo(widget.id);
                Navigator.pop(_context);
              },
            ),
            FlatButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.pop(context, "취소");
              },
            ),
          ],
        );
      },
    );
  }

  //음성 재생 함수
  void playaudio(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    print('playaudio$path');
    await audioPlayer.play(path, isLocal: true);
  }
}
