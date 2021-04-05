import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentCouncil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFFEA5757),
            title: Text('Student Council', // header
                style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                )),
            centerTitle: true,
            bottom: TabBar(
              tabs: [
                Tab(
                  text: "Profiles",
                ),
                Tab(
                  text: "Office Hours",
                ),
                Tab(
                  text: "Docs",
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ListView(
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/default-avatar.png"),
                        backgroundColor: Colors.grey,
                        radius: 30,
                      ),
                      title: Text('Jane Doe'),
                      subtitle: Text('Here is a second line'),
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(builder: (context) {
                      //       return ChangePassword(); // Use Reset password screen?
                      //     }),
                      //   );
                      // },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/default-avatar.png"),
                        backgroundColor: Colors.grey,
                        radius: 30,
                      ),
                      title: Text('John Doe'),
                      subtitle: Text('Here is a second line'),
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(builder: (context) {
                      //       return ChangePassword(); // Use Reset password screen?
                      //     }),
                      //   );
                      // },
                    ),
                  ),
                ],
              ),
              Text("TODO: Office Hours screen"),
              ListView(
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Academic Policy'),
                      trailing: Icon(Icons.file_download),
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(builder: (context) {
                      //       return ChangePassword(); // Use Reset password screen?
                      //     }),
                      //   );
                      // },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Harassment Policy'),
                      trailing: Icon(Icons.file_download),
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(builder: (context) {
                      //       return ChangePassword(); // Use Reset password screen?
                      //     }),
                      //   );
                      // },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}