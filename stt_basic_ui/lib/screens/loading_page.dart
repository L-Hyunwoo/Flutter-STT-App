import 'package:flutter/material.dart';

//로딩 페이지 생성
class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
