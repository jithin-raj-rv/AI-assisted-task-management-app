
import 'package:flutter/material.dart';

class Buttonstyl extends StatelessWidget {
  const Buttonstyl({super.key,required this.savetext,required this.onPressed});
  final String savetext;
  final VoidCallback onPressed;
  

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      
      onPressed: onPressed ,child: Container(
        width: 60,
        decoration: BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(savetext,style: TextStyle(color: Colors.white),))),);
  }
}