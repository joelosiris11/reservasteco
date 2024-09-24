import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarBar extends StatefulWidget {
  final Function(DateTime, String) onDateTimeSelected;

  const CalendarBar({Key? key, required this.onDateTimeSelected}) : super(key: key);

  @override
  _CalendarBarState createState() => _CalendarBarState();
}

class _CalendarBarState extends State<CalendarBar> {
  late ScrollController _scrollController;
  late ScrollController _hourScrollController;
  late DateTime _currentDate;
  late int _currentYear;
  int? _selectedDay;
  String? _selectedHour;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _currentYear = _currentDate.year;
    _scrollController = ScrollController(
      initialScrollOffset: (_getDayOfYear(_currentDate) - 1) * 40.0,
    );
    _hourScrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _capitalizeFirstLetter(DateFormat('MMMM', 'es').format(DateTime(_currentYear, _getCurrentMonth()))),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: 365,
                    itemBuilder: (context, index) {
                      final dayOfYear = index + 1;
                      final date = DateTime(_currentYear, 1, 1).add(Duration(days: dayOfYear - 1));
                      final isSelected = dayOfYear == _selectedDay;
                      return GestureDetector(
                        onTap: () => _onDaySelected(dayOfYear, date),
                        child: Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSelected ? 36 : 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              child: Text(
                                date.day.toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 30,
            child: ListView.builder(
              controller: _hourScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 13,
              itemBuilder: (context, index) {
                final hour = '${index + 8}:00';
                final isSelected = hour == _selectedHour;
                return GestureDetector(
                  onTap: () => _onHourSelected(hour),
                  child: Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSelected ? 24 : 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      child: Text(hour),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 2,
            color: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  void _onDaySelected(int dayOfYear, DateTime date) {
    setState(() {
      _selectedDay = dayOfYear;
    });
    // Aquí es donde necesitamos crear un DateTime correcto
    DateTime selectedDate = DateTime(_currentYear, 1, 1).add(Duration(days: dayOfYear - 1));
    widget.onDateTimeSelected(selectedDate, _selectedHour ?? '12:00');
  }

  void _onHourSelected(String hour) {
    setState(() {
      _selectedHour = hour;
    });
    // Asumimos que _selectedDay es el día del año seleccionado
    DateTime selectedDate = _selectedDay != null
        ? DateTime(_currentYear, 1, 1).add(Duration(days: _selectedDay! - 1))
        : DateTime.now();
    widget.onDateTimeSelected(selectedDate, hour);
  }

  int _getDayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  int _getCurrentMonth() {
    if (!_scrollController.hasClients) return _currentDate.month;
    final dayOfYear = (_scrollController.offset / 40).round() + 1;
    return DateTime(_currentYear, 1, 1).add(Duration(days: dayOfYear - 1)).month;
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _hourScrollController.dispose();
    super.dispose();
  }
}