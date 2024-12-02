import 'package:flutter/material.dart';

class OnBoardPage extends StatefulWidget {
  const OnBoardPage({Key? key}) : super(key: key);

  @override
  State<OnBoardPage> createState() => _OnBoardPageState();
}

class _OnBoardPageState extends State<OnBoardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 18,
            top: 250,
            child: Image.asset(
              'images/emplbee_ari.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'Welcome To\n   EmplBee',
                  style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
                ),
              ),
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/signinpage');
                },
                child: Icon(
                  Icons.navigate_next_outlined,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
