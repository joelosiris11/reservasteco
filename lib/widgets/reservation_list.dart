import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; // Importar para el formato de fecha

class ReservationList extends StatefulWidget {
  final GoogleSignInAccount user; // Usuario autenticado

  const ReservationList({Key? key, required this.user}) : super(key: key);

  @override
  _ReservationListState createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  List<calendar.Event> events = [];
  calendar.Event? selectedEvent;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final auth = await widget.user.authentication;
      final client = http.Client();
      final credentials = AccessCredentials(
        AccessToken('Bearer', auth.accessToken!, DateTime.now().toUtc().add(Duration(seconds: 3600))),
        null,
        ['https://www.googleapis.com/auth/calendar'],
      );

      final authedClient = authenticatedClient(client, credentials);
      final calendarApi = calendar.CalendarApi(authedClient);

      final now = DateTime.now();
      final eventsResult = await calendarApi.events.list(
        'primary',
        timeMin: now,
        timeMax: now.add(Duration(days: 7)), // Obtener eventos de la próxima semana
        singleEvents: true,
        orderBy: 'startTime',
      );

      setState(() {
        events = eventsResult.items ?? [];
      });
    } catch (error) {
      print('Error al obtener eventos: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Ancho del panel
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Aumentar el espacio entre el AppBar y el título
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Lista de Reuniones',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20), // Espacio entre el título y la lista
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  child: ListTile(
                    title: Text(
                      event.summary ?? 'Sin título',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      // Formatear la fecha y hora para que se vea más amigable
                      event.start?.dateTime != null 
                          ? DateFormat('dd/MM/yyyy HH:mm').format(event.start!.dateTime!.toLocal()) 
                          : 'Sin fecha',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    onTap: () {
                      setState(() {
                        selectedEvent = event;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          if (selectedEvent != null) ...[
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedEvent!.summary ?? 'Sin título',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Descripción: ${selectedEvent!.description ?? 'Sin descripción'}'),
                  SizedBox(height: 8),
                  Text('Fecha: ${selectedEvent!.start != null ? DateFormat('dd/MM/yyyy').format(selectedEvent!.start!.dateTime!.toLocal()) : 'Sin fecha'}'),
                  SizedBox(height: 8),
                  Text('Hora de inicio: ${selectedEvent!.start != null ? DateFormat('HH:mm').format(selectedEvent!.start!.dateTime!.toLocal()) : 'Sin hora de inicio'}'),
                  SizedBox(height: 8),
                  Text('Hora de fin: ${selectedEvent!.end != null ? DateFormat('HH:mm').format(selectedEvent!.end!.dateTime!.toLocal()) : 'Sin hora de fin'}'),
                  SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: 'Título: ${selectedEvent!.summary}\n'
                            'Descripción: ${selectedEvent!.description}\n'
                            'Fecha: ${selectedEvent!.start != null ? DateFormat('dd/MM/yyyy').format(selectedEvent!.start!.dateTime!.toLocal()) : 'Sin fecha'}\n'
                            'Hora de inicio: ${selectedEvent!.start != null ? DateFormat('HH:mm').format(selectedEvent!.start!.dateTime!.toLocal()) : 'Sin hora de inicio'}\n'
                            'Hora de fin: ${selectedEvent!.end != null ? DateFormat('HH:mm').format(selectedEvent!.end!.dateTime!.toLocal()) : 'Sin hora de fin'}',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedEvent = null;
                        });
                      },
                      child: Text('Cerrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}