import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:sttbasicui/database/memo.dart';
import 'package:sttbasicui/database/db.dart';
import 'package:sttbasicui/screens/view.dart';
import 'package:crypto/crypto.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'edit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';


//로그안 페이지에서 구글 계정을 넘겨받음
class MyHomePage extends StatefulWidget {
  final FirebaseUser user;
  final LocalFileSystem localFileSystem;

  MyHomePage(this.user, {localFileSystem, this.title})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //flutter channel 설정
  static const platform = const MethodChannel("com.example.sttbasicui");

  String deleteId = '';
  String deletePath = '';
  String title = '';
  String path = '';
  String text = '';
  String id = '';

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  ProgressDialog pr;
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  List filez = new List();

  //상태 초기화
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech-To-Text', style: GoogleFonts.pacifico()),
      ),
      //drawer에 계정 정보, 로그아웃 버튼 생성
      drawer: Drawer(
        child: Center(
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(30)),
              new UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.white),
                accountName: new Text(widget.user.displayName),
                accountEmail: new Text(widget.user.email),
                currentAccountPicture: new CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF778899),
                  backgroundImage: NetworkImage(widget.user.photoUrl),
                ),
              ),
              Container(
                  width: 100,
                  height: 30,
                  child: RaisedButton(
                    child: Text("Logout"),
                    onPressed: () {
                      //로그아웃
                      FirebaseAuth.instance.signOut();
                      _googleSignIn.signOut();
                    },
                    color: Colors.red,
                    textColor: Colors.white,
                    splashColor: Colors.grey,
                  ))
            ],
          ),
        ),
      ),

      //mainbody -> memoBuilder로 이동
      body: Column(
        children: <Widget>[Expanded(child: memoBuilder(context))],
      ),
      //녹음 플로팅 버튼 생성
      floatingActionButton: _currentStatus == RecordingStatus.Initialized
          //녹음 비활성화일때
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              child: Icon(Icons.keyboard_voice),
              onPressed: () {
                _start();
              },
            )
          //녹음 활성화일때
          : FloatingActionButton.extended(
              backgroundColor: Colors.red,
              label: Text('${_current?.duration.toString()}'),
              icon: Icon(Icons.stop),
              onPressed: () {
                _stop();
              },
            ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  //메모 데이터 불러오는 함수
  Future<List<Memo>> loadMemo() async {
    DBHelper sd = DBHelper();
    return await sd.memos();
  }

  //메모 정보 삭제 함수
  Future<void> deleteMemo(String id) async {
    DBHelper sd = DBHelper();
    sd.deleteMemo(id);
  }

  //삭제 경고 메세지 출력
  void showAlertDialog(BuildContext context) async {
    await showDialog(
      context: context,
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
                setState(() {
                  //음성 파일 삭제
                  File file = widget.localFileSystem.file(deletePath);
                  file.delete();
                  //메모 data 삭제
                  deleteMemo(deleteId);
                });
                deleteId = '';
                deletePath = '';
              },
            ),
            FlatButton(
              child: Text('취소'),
              onPressed: () {
                deleteId = '';
                deletePath = '';
                Navigator.pop(context, "취소");
              },
            ),
          ],
        );
      },
    );
  }

  //main body 부분
  Widget memoBuilder(BuildContext parentContext) {
    return FutureBuilder<List<Memo>>(
      builder: (context, snap) {
        //data가 있는지 확인
        if (snap.data == null || snap.data.isEmpty) {
          return Container(
            alignment: Alignment.center,
            //없으면 문구 출력
            child: Text(
              '지금 바로 마이크 버튼을 눌러\n새로운 파일을 생성해보세요!\n\n\n\n\n\n\n\n\n',
              style: TextStyle(fontSize: 15, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
          );
        }
        //있으면 메모 리스트 출력
        return ListView.builder(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          itemCount: snap.data.length,
          itemBuilder: (context, index) {
            Memo memo = snap.data[index];
            return InkWell(
              //메모를 누르면 디테일 뷰 페이지로 이동
              onTap: () {
                Navigator.push(
                    parentContext,
                    CupertinoPageRoute(
                        builder: (context) =>
                            ViewPage(id: memo.id, path: memo.editTime)));
              },
              //오랫동안 누르면 삭제
              onLongPress: () {
                deleteId = memo.id;
                deletePath = memo.editTime;
                showAlertDialog(parentContext);
              },
              //메모 리스트 내부의 내용 출력
              child: Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.all(20),
                  alignment: Alignment.center,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            memo.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            //내용이 길때 뒷부분 ...으로 표시
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(padding: EdgeInsets.all(5)),
                          Text(
                            memo.text,
                            style: TextStyle(fontSize: 15),
                            //내용이 길때 뒷부분 ...으로 표시
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                      ),

                    ],
                  ),
                  //리스트 컨테이너 디자인 설정
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    border: Border.all(
                      color: Colors.blue,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.lightBlue, blurRadius: 1)
                    ],
                    borderRadius: BorderRadius.circular(7),
                  )
              ),
            );
          },
        );
      },
      future: loadMemo(),
    );
  }

  //음성 파일 저장 함수
  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }
        print(appDocDirectory);
        //저장 경로 설정
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        //파일 이름, 확장자 설정
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      }
      //permission 없을 때 출력
      else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

 //녹음 시작 함수
  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }

  }

  //녹음 중지 함
  _stop() async {
    var result = await _recorder.stop();
    var current = await _recorder.current(channel: 0);
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration.toString()}");
    File file = widget.localFileSystem.file(result.path);
    print("File length: ${await file.length()}");
    setState(() {
      _current = current;
      _currentStatus = _current.status;
    });
    String directory = (await getExternalStorageDirectory()).path;

    setState(() {
      filez = io.Directory("$directory/")
          .listSync(); //use your folder name insted of resume.수
    });
    //파일 저장 함수로 이동
    _init();
    this.path = result.path;
    //녹음 완료되면 변환 경고 메시지로 이동
    sttAlertDialog(context);
  }

  //변환 경고 메시지
  void sttAlertDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('녹음 완료'),
          content: Text("STT 변환 하시겠습니까?\n취소하시면 녹음파일 또한 사라집니다.",
              textAlign: TextAlign.center),
          actions: <Widget>[
            FlatButton(
              child: Text('변환'),
              onPressed: () {
                Navigator.pop(context);
                stt();
              },
            ),
            FlatButton(
              child: Text('취소'),
              onPressed: () {
                //음성 파일 삭제
                File file = widget.localFileSystem.file(this.path);
                file.delete();
                this.path = '';
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  //stt 함수
  void stt() async {
    String value;

    //토스트메시지 출력
    Fluttertoast.showToast(
      msg: "STT 변환중입니다. 잠시만 기다려 주세요.",
    );

    //stt 시작하면 화면이 멈추기 때문에 dalay 설정하여 변환 경고 메시지 창을 닫고 토스트 메시지 출력
    sttstart() => Future.delayed(
        Duration(milliseconds: 200),
        () =>
            "---------- STT START : " +
            DateTime.now().toString() +
            "---------");

    //200ms뒤에 stt 시작
    Future start() async {
      var test = await sttstart();
      print(test);
      try {
        value = await platform
            .invokeMethod("stt", <String, dynamic>{'song': this.path});
      } catch (e) {
        print(e);
      }

      //stt 완료되면 출력
      print("---------- STT END : " +
          DateTime.now().toString() +
          " ---------- \nSTT: " +
          value);
      //stt 텍스트를 메모 data에 저장
      this.text = value;
      //메모 저장 함수로 이동
      saveDB();

      //텍스트 수정 페이지로 이동
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditPage(id: this.id, path: this.path)));
    }

    start();
  }

  //메모 저장 함수
  Future<void> saveDB() async {
    DBHelper sd = DBHelper();

    var fido = Memo(
      id: str2Sha512(DateTime.now().toString()),
      // String
      title: this.title,
      text: this.text,
      createTime: DateTime.now().toString(),
      editTime: this.path,
    );

    await sd.insertMemo(fido);

    print(await sd.memos());
  }

  //메모 id 생성
  String str2Sha512(String text) {
    var bytes = utf8.encode(text); // data being hashed
    var digest = sha512.convert(bytes);
    this.id = digest.toString();
    return digest.toString();
  }
}
