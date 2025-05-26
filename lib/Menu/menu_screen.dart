import 'package:flutter/material.dart';
import '../Home/camera_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Klases/class_page.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = 230;

    return Scaffold(
      backgroundColor: const Color(0xFFFFA500),
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: const Color(0xFFFFA500),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout)
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: Container(
                color: Colors.transparent,
                child: //logo
                const Center(
                  child: Icon(
                    Icons.lock,
                    size: 150,
                  ),
                ),
              )
          ),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width - 60,
                  child: Container(

                    decoration: const BoxDecoration(

                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20)
                      ),

                      color:  Color(0xFFADD8E6),
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        //mygtukas skanuoti uždavinį
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CameraOCR()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10)
                                ),
                              ),
                            ),
                            child: const Text(
                              'Skanuoti uždavinį',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // Add spacing between buttons

                        //mygtukas klasės
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ClassPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA500),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10)
                                ),
                              ),
                            ),
                            child: const Text(
                              'Klasės',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),



                      ],
                    ),
                  ),
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }
}
