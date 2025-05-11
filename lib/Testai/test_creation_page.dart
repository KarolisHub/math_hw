
import 'package:flutter/material.dart';

class TestCreationPage extends StatelessWidget {
  const TestCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Kurti testą"
        ),
        backgroundColor: Color(0xFFFFA500),
      ),
      backgroundColor: Color(0xFFADD8E6),
      body: Column(

        children: [

          //Testo informacija
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Column(
              children: [

                SizedBox(height: 40),

                //Testo pavadinimas
                Text("Testo pavadinimas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFFFA500),
                    hintText: 'Įvesti...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

                  ),
                ),


              ]
            ),
          ),

          SizedBox(height: 40),

          //sekcijų atskyrimas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(thickness: 2, color: Color(0xFF292D32),)
          ),

          //klausimo sukūrimo mygtukas
          ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFA500)),
              child: Text('Pridėti uždavinį', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF292D32)),)
          )

          //klausimų atvaizdavimas


        ],
      ),
    );
  }
}
