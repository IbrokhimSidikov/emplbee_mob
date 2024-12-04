import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
                // onTap: () async {
                //   try {
                //     final authService = AuthService();
                    
                //     await authService.logout();
                    
                //     await authService.login();
                    
                //     // Check if we got an access token
                //     final token = await authService.getAccessToken();
                //     if (token != null) {
                //       if (mounted) {  // Check if widget is still mounted
                //         Navigator.pushReplacementNamed(context, '/homepage');
                //       }
                //     } else {
                //       if (mounted) {  // Check if widget is still mounted
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           SnackBar(content: Text('Login failed. Please try again.'))
                //         );
                //       }
                //     }
                //   } catch (e) {
                //     if (mounted) {  // Check if widget is still mounted
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text('An error occurred. Please try again.'))
                //       );
                //     }
                //   }
                // },
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/homepage');
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
