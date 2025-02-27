import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Leaderboard extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData = [
    {'name': 'Alice', 'score': 1200, 'rank': 1},
    {'name': 'Bob', 'score': 1100, 'rank': 2},
    {'name': 'Charlie', 'score': 1050, 'rank': 3},
    {'name': 'Diana', 'score': 1000, 'rank': 4},
    {'name': 'Eve', 'score': 950, 'rank': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade900, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Top Players',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: leaderboardData.length,
                itemBuilder: (context, index) {
                  final player = leaderboardData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 100,
                        child: Row(
                          children: [
                            Text(
                              player['rank'].toString(),
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 15
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.teal.shade300,
                              backgroundImage: AssetImage('assets/profile_placeholder.png'), // Replace with actual image path
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        player['name'],
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black
                        ),

                      ),
                      trailing: Text(
                        '${player['score']} pts',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: Leaderboard(),
  debugShowCheckedModeBanner: false,
));
