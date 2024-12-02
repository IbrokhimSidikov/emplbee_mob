import 'package:flutter/material.dart';
import '../widget/widget_support.dart';
import 'package:emplbee_mob/pages/home_page.dart';
import 'package:emplbee_mob/pages/signin_page.dart';


class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
              ),
              
              Container(
                margin: EdgeInsets.only(top: 70.0, left: 20.0, right: 20.0),
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        "images/emplbeeSignup.png",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.only(left: 20.0, right: 20.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 30.0,
                            ),
                            Text(
                              "Sign In",
                              style: AppWidget.HeadlineTextFieldStyle(),
                            ),
                            SizedBox(
                              height: 30.0,
                            ),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: AppWidget.semiboldTextFieldStylehint(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            SizedBox(
                              height: 30.0,
                            ),
                            TextField(
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: AppWidget.semiboldTextFieldStylehint(),
                                prefixIcon: Icon(Icons.password_outlined),
                              ),
                            ),
                            SizedBox(
                              height: 60.0,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/homepage');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 100.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5.0,
                              ),
                              child: Text(
                                "LOGIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
