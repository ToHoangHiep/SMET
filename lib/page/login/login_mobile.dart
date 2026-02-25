import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginMobile extends StatefulWidget {
  const LoginMobile({super.key});

  @override
  State<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends State<LoginMobile> {

  void login() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Login'),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                   
                  },
                  child: Text('Login'),
                ),
              ],
            ),
          );
  }
}