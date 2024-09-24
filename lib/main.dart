import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore
import 'preparar_reserva.dart'; // Importa la pantalla de preparación de reserva
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendario Google',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.light),
      darkTheme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: SpinKitRipple(
              color: Colors.blue.withOpacity(0.5),
              size: 200.0,
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: SpinKitRipple(
              color: Colors.blue.withOpacity(0.5),
              size: 200.0,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(), // Espacio flexible en la parte superior
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SpinKitSpinningLines(
                      color: Colors.blue.withOpacity(0.5),
                      size: 150.0,
                    ),
                    SpinKitSpinningLines(
                      color: Colors.green.withOpacity(0.5),
                      size: 150.0,
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset('assets/images/teco.png', height: 120),
                      ),
                    ),
                  ],
                ),
                Spacer(flex: 2), // Espacio flexible en el medio
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0), // Ajusta el valor según sea necesario
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Fondo blanco
                      foregroundColor: Colors.black54, // Texto semi negro
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // Botón más redondeado
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                    onPressed: () => _handleSignIn(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/g.png', height: 24),
                        SizedBox(width: 8),
                        Text('Iniciar sesión con Google'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        // Inicializa Firebase después de la autenticación
        await Firebase.initializeApp();

        // Autenticar con Firebase
        final GoogleSignInAuthentication googleAuth = await account.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Verificar si el usuario está autenticado
        if (FirebaseAuth.instance.currentUser != null) {
          // Guardar el correo en Firestore
          await FirebaseFirestore.instance.collection('users').doc(account.email).set({
            'email': account.email,
            'displayName': account.displayName,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sesión iniciada como ${account.email}')),
          );
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PrepararReservaScreen(
              userName: account.displayName ?? 'Usuario Anónimo',
              user: account,
            ),
          ));
        } else {
          print('Error: Usuario no autenticado en Firebase');
        }
      }
    } catch (error) {
      print('Error al iniciar sesión: $error');
    }
  }
}

class EventScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn;

  EventScreen(this._googleSignIn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Evento')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.event),
          label: Text('Crear evento'),
          onPressed: () => _createEvent(context),
        ),
      ),
    );
  }

  Future<void> _createEvent(BuildContext context) async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, inicia sesión primero')),
        );
        return;
      }

      final auth = await account.authentication;
      final client = http.Client();
      final credentials = AccessCredentials(
        AccessToken('Bearer', auth.accessToken!, DateTime.now().toUtc().add(Duration(seconds: 3600))),
        null,
        ['https://www.googleapis.com/auth/calendar'],
      );

      final authedClient = authenticatedClient(client, credentials);
      final calendarApi = calendar.CalendarApi(authedClient);

      final event = calendar.Event()
        ..summary = 'Nuevo evento'
        ..description = 'Evento creado desde la app Flutter'
        ..start = calendar.EventDateTime(dateTime: DateTime.now().add(Duration(days: 1)))
        ..end = calendar.EventDateTime(dateTime: DateTime.now().add(Duration(days: 1, hours: 1)));

      await calendarApi.events.insert(event, 'primary');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evento creado exitosamente')),
      );
    } catch (error) {
      print('Error al crear evento: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear evento')),
      );
    }
  }
}
