import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_feedback_widget.dart';
import 'user_find.dart';

class ReservationDialog extends StatefulWidget {
  final String roomName;
  final String imageName;
  final DateTime selectedDate;
  final String selectedTime;
  final Set<String> selectedFeatures;
  final String userName;

  const ReservationDialog({
    Key? key,
    required this.roomName,
    required this.imageName,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedFeatures,
    required this.userName,
  }) : super(key: key);

  @override
  _ReservationDialogState createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  late String endTime;
  late Set<String> selectedFeatures;
  String? qrData;
  List<String> addedUsers = [];

  bool isLoading = false;
  bool isSuccess = false;
  String errorMessage = '';

  final List<String> timeOptions = List.generate(24 * 4, (index) {
    final hour = index ~/ 4;
    final minute = (index % 4) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  @override
  void initState() {
    super.initState();
    selectedFeatures = widget.selectedFeatures;
    endTime = calculateEndTime(widget.selectedTime, hoursToAdd: 2);
  }

  String calculateEndTime(String startTime, {int hoursToAdd = 2}) {
    final start = TimeOfDay(
      hour: int.parse(startTime.split(':')[0]),
      minute: int.parse(startTime.split(':')[1]),
    );
    final end = TimeOfDay(
      hour: (start.hour + hoursToAdd) % 24,
      minute: start.minute,
    );
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  void toggleFeature(String feature) {
    setState(() {
      if (selectedFeatures.contains(feature)) {
        selectedFeatures.remove(feature);
      } else {
        selectedFeatures.add(feature);
      }
    });
  }

  void _addUser(String email) {
    setState(() {
      if (!addedUsers.contains(email) && email.isNotEmpty && email != '0') {
        addedUsers.add(email);
      }
    });
  }

  void _removeUser(String email) {
    setState(() {
      addedUsers.remove(email);
    });
  }

  Future<void> makeReservation() async {
    setState(() {
      isLoading = true;
      isSuccess = false;
      errorMessage = '';
    });

    try {
      bool isAvailable = await _checkAvailability(widget.roomName, widget.selectedDate, widget.selectedTime, endTime);
      if (!isAvailable) {
        throw Exception('La sala no está disponible en el horario seleccionado');
      }

      qrData = 'Sala: ${widget.roomName}\n'
               'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}\n'
               'Hora: ${widget.selectedTime} - $endTime\n'
               'Equipos solicitados: ${selectedFeatures.join(", ")}';

      String eventId = await _createEvent(context, widget.roomName, widget.selectedDate, widget.selectedTime, endTime);
      
      await _inviteUsers(eventId);

      await _registerReservation(widget.roomName, widget.selectedDate, widget.selectedTime, endTime);

      setState(() {
        isSuccess = true;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _checkAvailability(String roomName, DateTime selectedDate, String selectedTime, String endTime) async {
    final startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(selectedTime.split(':')[0]),
      int.parse(selectedTime.split(':')[1]),
    );

    final endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('roomName', isEqualTo: roomName)
        .where('selectedDate', isEqualTo: selectedDate)
        .where('userName', isEqualTo: widget.userName)
        .where('startDateTime', isLessThanOrEqualTo: endDateTime)
        .where('endDateTime', isGreaterThanOrEqualTo: startDateTime)
        .get();

    return querySnapshot.docs.isEmpty;
  }

  Future<void> _registerReservation(String roomName, DateTime selectedDate, String selectedTime, String endTime) async {
    final startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(selectedTime.split(':')[0]),
      int.parse(selectedTime.split(':')[1]),
    );

    final endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );

    await FirebaseFirestore.instance.collection('reservations').add({
      'roomName': roomName,
      'selectedDate': selectedDate,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'features': selectedFeatures.toList(),
      'userName': widget.userName,
    });
  }

  Future<String> _createEvent(BuildContext context, String roomName, DateTime selectedDate, String selectedTime, String endTime) async {
    try {
      final account = await GoogleSignIn().signInSilently();
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, inicia sesión primero')),
        );
        throw Exception('No se pudo iniciar sesión en Google');
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

      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(selectedTime.split(':')[0]),
        int.parse(selectedTime.split(':')[1]),
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(endTime.split(':')[0]),
        int.parse(endTime.split(':')[1]),
      );

      final event = calendar.Event()
        ..summary = 'Reunión en T-EcoGroup'
        ..description = 'Sala: $roomName\n'
                        'Equipos solicitados: ${selectedFeatures.join(", ")}'
        ..start = calendar.EventDateTime(dateTime: startDateTime)
        ..end = calendar.EventDateTime(dateTime: endDateTime);

      final createdEvent = await calendarApi.events.insert(event, 'primary');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evento creado exitosamente en Google Calendar')),
      );

      return createdEvent.id!;
    } catch (error) {
      print('Error al crear evento: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear evento')),
      );
      throw error;
    }
  }

  Future<void> _inviteUsers(String eventId) async {
    try {
      final account = await GoogleSignIn().signInSilently();
      if (account == null) {
        throw Exception('No se pudo iniciar sesión en Google');
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

      for (String email in addedUsers) {
        final eventAttendee = calendar.EventAttendee()..email = email;
        
        await calendarApi.events.patch(
          calendar.Event()..attendees = [eventAttendee],
          'primary',
          eventId,
          sendUpdates: 'all',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitaciones enviadas a los usuarios')),
      );
    } catch (error) {
      print('Error al invitar usuarios: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar invitaciones')),
      );
    }
  }

  Future<String?> _openUserFindDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Agregar Usuario'),
          content: Container(
            width: double.maxFinite,
            child: UserFind(
              onUserSelected: (String email) {
                Navigator.of(context).pop(email);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reserva para ${widget.userName}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: isLoading
            ? ReservationFeedbackWidget(
                isLoading: true,
                isSuccess: false,
              )
            : isSuccess
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReservationFeedbackWidget(
                        isLoading: false,
                        isSuccess: true,
                        onContinue: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      SizedBox(height: 20),
                      QrImageView(
                        data: qrData!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            'assets/images/${widget.imageName}',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.roomName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hora de inicio: ${widget.selectedTime}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext context) => Container(
                                    height: 200,
                                    color: Colors.black,
                                    child: CupertinoPicker(
                                      backgroundColor: Colors.black,
                                      itemExtent: 32,
                                      scrollController: FixedExtentScrollController(
                                        initialItem: timeOptions.indexOf(endTime),
                                      ),
                                      onSelectedItemChanged: (int selectedItem) {
                                        setState(() {
                                          endTime = timeOptions[selectedItem];
                                        });
                                      },
                                      children: timeOptions.map((String time) => Center(
                                        child: Text(
                                          time,
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Fin: $endTime',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...addedUsers.where((email) => email.isNotEmpty && email != '0').map((email) => Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _removeUser(email),
                                child: CircleAvatar(
                                  backgroundColor: Colors.pink[100],
                                  radius: 15,
                                  child: Text(
                                    email[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.pink[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                            ElevatedButton(
                              onPressed: () async {
                                final email = await _openUserFindDialog();
                                if (email != null && email.isNotEmpty && email != '0') {
                                  _addUser(email);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(12),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange,
                              ),
                              child: Icon(
                                Icons.person_add,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: makeReservation,
                              child: Text('Reservar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancelar'),
                            ),
                          ],
                        ),
                        if (errorMessage.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Equipos solicitados:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ...widget.selectedFeatures.map((feature) {
                              return FilterChip(
                                label: Text(feature),
                                selected: selectedFeatures.contains(feature),
                                onSelected: (isSelected) {
                                  toggleFeature(feature);
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}