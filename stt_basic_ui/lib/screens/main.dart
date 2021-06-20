import 'package:flutter/material.dart';

import 'package:sttbasicui/screens/root_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('MyApp created');
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.white,
        accentColor: Colors.black,
      ),
      home: RootPage(),   //루트 페이지로 이동
    );
  }
}
