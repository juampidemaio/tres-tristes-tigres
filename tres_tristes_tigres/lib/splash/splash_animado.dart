import 'package:flutter/material.dart';
import 'dart:async';
import '../login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 300), () {
      setState(() {
        _startAnimation = true;
      });
    });

    Timer(Duration(milliseconds: 2500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    Timer(Duration(seconds: 5), () {
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFFF9100),
      body: Stack(
        children: [
          Positioned(
            left: screenWidth * 0.10,
            top: screenHeight * 0.1,
            child: Text(
              "A-141",
              style: TextStyle(fontFamily: '5thAvenue', fontSize: 122, color: Color(0xFF00315C)),
            ),
          ),
          Center(
            child: Transform.scale(
              scale: 0.9,
              child: Image.asset('assets/splash/tigre_bandeja_vacia.png'),
            ),
          ),
          Positioned(
            left: screenWidth * -0.05,
            top: screenHeight * 0.28,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 2),

              child: Transform.scale(
                scale: 0.5,
                child: Image.asset('assets/splash/brillos.png'),
              ),
            ),
          ),
          AnimatedAlign(
            alignment:
                _startAnimation ? Alignment(-1.8, 0.14) : Alignment(-1.5, -1.2),
            duration: Duration(seconds: 3),
            curve: Curves.bounceOut,
            child: Transform.scale(
              scale: 0.5,
              child: Image.asset('assets/splash/hamburguesa.png'),
            ),
          ),
          Positioned(
            left: screenWidth * 0.11,
            bottom: screenHeight * 0.05,
            child: Text(
              "Juan Pablo De Maio\nLeón Sokolowski\nClara Cuenca",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, color: Color(0xFF00315C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
