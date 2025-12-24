import 'package:flutter/material.dart';
import 'view_menu_page.dart';
import 'package:url_launcher/url_launcher.dart';

const url = "https://www.muntele-mic.ro";

class HomePage extends StatelessWidget {
  final int tableNumber;
  const HomePage({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF324051),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /*===================================STACK LOGO + HELP ICON================================================= */
            Stack(
              children: [
                /*========================================LOGO HOTEL FELIX===============================================*/
                Container(
                  color: Color(0xFFE4E2DD),
                  child: Image.asset('images/logo_hotel_felix_cropped.png'),
                ),

                /*===========================================HELP ICON===================================================*/
                Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 20.0),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.language,
                      color: Color(0xFF324051),
                    ),
                  ),
                ),
              ],
            ),

            /*============================================IMAGE TRANZITIE BRAZI======================================== */
            Container(
              color: Color(0xFFE4E2DD),
              child: Image.asset('images/tranzitie_brazi.png'),
              margin: EdgeInsets.zero,
            ),

            SizedBox(height: 10.0),

            /*===========================================TEXT BINE ATI VENIT============================================ */
            Center(
              child: Text(
                'Bine ati venit!',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Color(0xFFE4E2DD),
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            SizedBox(height: 10.0),

            // (Optional but useful) show current table
            Center(
              child: Text(
                'Masa $tableNumber',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFFE4E2DD),
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            SizedBox(height: 20.0),

            /*=============================================BUTON COMANDA ACUM=========================================== */
            Center(
              child: SizedBox(
                width: 200.0,
                height: 45.0,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewMenuPage(tableNumber: tableNumber),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE4E2DD),
                  ),
                  child: Text(
                    'Comanda acum',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Color(0xFF324051),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 100.0),

            /*=============================================CONTACT EMAIL=============================================== */
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, color: Color(0xFFE4E2DD)),
                SizedBox(width: 20.0),
                Text(
                  'felician.ciordas@gmail.com',
                  style: TextStyle(
                    color: Color(0xFFE4E2DD),
                    letterSpacing: 2.0,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.0),

            /*==========================================CONTACT TELEFON=============================================== */
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Color(0xFFE4E2DD)),
                SizedBox(width: 10.0),
                TextButton(
                  onPressed: () async {
                    final Uri phoneUri = Uri(scheme: 'tel', path: '+40722211412');
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      throw 'Could not launch $phoneUri';
                    }
                  },
                  child: Text(
                    "+40 722 211 412",
                    style: TextStyle(
                      color: Color(0xFFE4E2DD),
                      letterSpacing: 2.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.0),

            /*============================================CONTACT WEBSITE============================================= */
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.web, color: Color(0xFFE4E2DD)),
                SizedBox(width: 20.0),
                TextButton(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://www.muntele-mic.ro');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                  child: Text(
                    "www.muntele-mic.ro",
                    style: TextStyle(
                      color: Color(0xFFE4E2DD),
                      letterSpacing: 2.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.0),

            /*================================================DIVIDER================================================ */
            Padding(
              padding: EdgeInsets.zero,
              child: Divider(
                height: 100.0,
                indent: 25.0,
                endIndent: 25.0,
                color: Color(0xFFE4E2DD),
              ),
            ),

            /*===============================================@Hotel Felix 2024======================================= */
            Padding(
              padding: EdgeInsets.zero,
              child: Center(
                child: Text('@Hotel Felix 2024', style: TextStyle(color: Color(0xFFE4E2DD))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
