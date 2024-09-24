import 'package:flutter/material.dart';

class ReservationFeedbackWidget extends StatelessWidget {
  final bool isLoading;
  final bool isSuccess;
  final String errorMessage;
  final VoidCallback? onContinue; // Callback para el botón de continuar

  const ReservationFeedbackWidget({
    Key? key,
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage = '',
    this.onContinue, // Añadir el callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10.0,
              spreadRadius: 5.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 10.0),
              Text(
                'Creando reserva...',
                style: TextStyle(fontSize: 16.0),
              ),
            ] else if (isSuccess) ...[
              Icon(Icons.check_circle, color: Colors.green, size: 50.0),
              SizedBox(height: 10.0),
              Text(
                'Reserva creada con éxito',
                style: TextStyle(fontSize: 16.0, color: Colors.green),
              ),
              SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: onContinue, // Llamar al callback
                child: Text('Continuar'),
              ),
            ] else ...[
              Icon(Icons.error, color: Colors.red, size: 50.0),
              SizedBox(height: 10.0),
              Text(
                errorMessage.isNotEmpty ? errorMessage : 'Error al crear la reserva',
                style: TextStyle(fontSize: 16.0, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
