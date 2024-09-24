import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reservateco/widgets/calendar_bar.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/reservation_dialog.dart';
import 'package:reservateco/widgets/reservation_list.dart'; // Importa el nuevo widget
import 'package:google_sign_in/google_sign_in.dart'; // Importa GoogleSignIn

class PrepararReservaScreen extends StatefulWidget {
  final String userName; // Añadir el parámetro userName
  final GoogleSignInAccount user; // Añadir el parámetro user

  const PrepararReservaScreen({Key? key, required this.userName, required this.user}) : super(key: key);

  @override
  _PrepararReservaScreenState createState() => _PrepararReservaScreenState();
}

class _PrepararReservaScreenState extends State<PrepararReservaScreen> {
  Set<String> selectedFeatures = {};
  DateTime selectedDate = DateTime.now();
  String selectedTime = '12:00';
  int selectedIndex = 0;
  final List<String> imageNames = ['pecera.jpg', 'salonclases.jpg', 'scrum1.jpg', 'scrum2.jpg', 'special.jpg'];
  late PageController _pageController;
  List<String> reservations = []; // Lista para almacenar reservas

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: selectedIndex,
    );
    initializeDateFormatting('es', null);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void updateSelectedDateTime(DateTime date, String time) {
    setState(() {
      selectedDate = date;
      selectedTime = time;
    });
  }

  String get selectedRoomName {
    final imageName = imageNames[selectedIndex].split('.').first;
    switch (imageName) {
      case 'pecera':
        return 'SALA PECERA';
      case 'salonclases':
        return 'SALÓN DE CLASES';
      case 'scrum1':
        return 'SALA SCRUM 1';
      case 'scrum2':
        return 'SALA SCRUM 2';
      case 'special':
        return 'SALA ESPECIAL';
      default:
        return 'BIG ROOM';
    }
  }

  String get roomDescription {
    switch (imageNames[selectedIndex].split('.').first) {
      case 'pecera':
        return 'Ideal para reuniones pequeñas y creativas, con capacidad para 8 personas.';
      case 'salonclases':
        return 'Perfecto para clases y capacitaciones, con capacidad para 20 personas.';
      case 'scrum1':
        return 'Diseñada para trabajo en equipo, con capacidad para 10 personas.';
      case 'scrum2':
        return 'Otra sala ideal para trabajo colaborativo, con capacidad para 10 personas.';
      case 'special':
        return 'Sala especial para eventos únicos, con capacidad para 10 personas.';
      default:
        return 'Descripción no disponible.';
    }
  }

  int get numberOfPeople {
    switch (imageNames[selectedIndex].split('.').first) {
      case 'pecera':
        return 8;
      case 'salonclases':
        return 20;
      case 'scrum1':
      case 'scrum2':
      case 'special':
        return 10;
      default:
        return 0; // Valor por defecto si no se encuentra la sala
    }
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

  void selectImage(int index) {
    setState(() {
      selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showReservationDialog(BuildContext context) {
    if (selectedDate == null || selectedTime.isEmpty) {
      // Mostrar un mensaje de error si falta seleccionar fecha u hora
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedDate == null
                  ? 'Por favor, selecciona una fecha'
                  : 'Por favor, selecciona una hora de inicio',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Si se ha seleccionado fecha y hora, mostrar el diálogo de reserva
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return ReservationDialog(
            roomName: selectedRoomName,
            imageName: imageNames[selectedIndex],
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            selectedFeatures: selectedFeatures,
            userName: widget.userName, // Pasar el nombre del usuario
          );
        },
      ).then((bool? confirmed) {
        if (confirmed == true) {
          // Lógica para confirmar la reserva
          print('Reserva confirmada');
        } else {
          // Lógica para cancelar la reserva o no hacer nada
          print('Reserva cancelada o cerrada');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseHeight = screenWidth * 0.6375;
    final selectedHeight = baseHeight * 1.3; // 30% más grande

    return Scaffold(
      backgroundColor: Colors.white, // Cambiamos el color de fondo a blanco
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Abre el Drawer desde la derecha
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRoomName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'T-ecogroup Sol',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      _showReservationDialog(context);
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Colors.deepOrange,
                    mini: true,
                  ),
                ],
              ),
            ),
            Expanded( // Usar Expanded aquí
              child: Container(
                height: selectedHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imageNames.length,
                  onPageChanged: selectImage,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedIndex;
                    return RoomImageCard(
                      imageName: imageNames[index],
                      isSelected: isSelected,
                      onTap: () => selectImage(index),
                      baseHeight: baseHeight,
                      selectedHeight: selectedHeight,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        numberOfPeople.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CAPACIDAD DE PERSONAS',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: Text(
                      roomDescription,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seleccionar equipos necesarios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeatureChip(
                        label: 'Oculus',
                        isSelected: selectedFeatures.contains('Oculus'),
                        onTap: () => toggleFeature('Oculus'),
                      ),
                      FeatureChip(
                        label: 'Laptop',
                        isSelected: selectedFeatures.contains('Laptop'),
                        onTap: () => toggleFeature('Laptop'),
                      ),
                      FeatureChip(
                        label: 'Mac',
                        isSelected: selectedFeatures.contains('Mac'),
                        onTap: () => toggleFeature('Mac'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeatureChip(
                        label: 'Movil',
                        isSelected: selectedFeatures.contains('Movil'),
                        onTap: () => toggleFeature('Movil'),
                      ),
                      FeatureChip(
                        label: 'Simulador',
                        isSelected: selectedFeatures.contains('Simulador'),
                        onTap: () => toggleFeature('Simulador'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), // Aumenta el espacio entre el contenido y el footer
            CalendarBar(
              onDateTimeSelected: updateSelectedDateTime,
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ReservationList(user: widget.user), // Pasa el usuario autenticado
      ),
    );
  }
}

class RoomImageCard extends StatelessWidget {
  final String imageName;
  final bool isSelected;
  final VoidCallback onTap;
  final double baseHeight;
  final double selectedHeight;

  const RoomImageCard({
    Key? key,
    required this.imageName,
    required this.isSelected,
    required this.onTap,
    required this.baseHeight,
    required this.selectedHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = isSelected ? selectedHeight : baseHeight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: (selectedHeight - height) / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/$imageName',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              if (!isSelected)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FeatureChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[400] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

