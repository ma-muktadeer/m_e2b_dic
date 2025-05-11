import 'package:flutter/material.dart';
import 'package:m_e2b_dic/pages/DictionaryScreen.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
    ),
    title: 'Dictionary App',
    home: const DictionaryScreen(),
  ),
);

