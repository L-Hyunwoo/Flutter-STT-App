import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sttbasicui/screens/home.dart';

import 'loading_page.dart';
import 'login_page.dart';
import 'home.dart';

//루트 페이지 생성
class RootPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('root_page created');
    return _handleCurrentScreen();
  }

  Widget _handleCurrentScreen() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      // ignore: missing_return
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        // 연결 상태가 기다리는 중이라면 로딩 페이지를 반환
        if (snapshot.connectionState == ConnectionState.waiting){
          return LoadingPage();
        }
        else {
          // 연결 되었고 데이터가 있다면
          if (snapshot.hasData) {
            return MyHomePage(snapshot.data);
          }
          return LoginPage();
        }
      },
    );
  }
}
