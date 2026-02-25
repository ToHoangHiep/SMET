import 'package:flutter/material.dart';

class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});

  @override
  State<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> {
  @override
  Widget build(BuildContext context) {
    return  Row(
            children: [
              Expanded(child: Container(color: Colors.red,),),
              Expanded(child: Column(
                children: [
                  Text('Login'),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',))
                ],
              )),
            ]
          );
  }
}