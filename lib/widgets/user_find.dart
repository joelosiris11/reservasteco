import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFind extends StatefulWidget {
  final Function(String) onUserSelected;

  UserFind({required this.onUserSelected});

  @override
  _UserFindState createState() => _UserFindState();
}

class _UserFindState extends State<UserFind> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _filteredUserList = [];
  bool _showNoResults = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _userList = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _filteredUserList = List.from(_userList);
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUserList = _userList.where((user) {
        final nameLower = (user['displayName'] ?? '').toString().toLowerCase();
        final emailLower = (user['email'] ?? '').toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) || emailLower.contains(searchLower);
      }).toList();
      _showNoResults = query.isNotEmpty && _filteredUserList.isEmpty;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar usuario o ingresar correo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _filterUsers,
          ),
          SizedBox(height: 10),
          Expanded(
            child: _showNoResults
                ? _buildNoResultsWidget()
                : ListView.builder(
                    itemCount: _filteredUserList.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUserList[index];
                      final displayName = user['displayName'] as String? ?? 'Usuario';
                      final email = user['email'] as String? ?? 'No email';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(displayName.isNotEmpty ? displayName[0] : '?'),
                        ),
                        title: Text(displayName),
                        subtitle: Text(email),
                        onTap: () => widget.onUserSelected(email),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    final enteredEmail = _searchController.text;
    final isValidEmail = _isValidEmail(enteredEmail);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No se encontraron usuarios'),
          SizedBox(height: 10),
          if (isValidEmail)
            ElevatedButton(
              onPressed: () => widget.onUserSelected(enteredEmail),
              child: Text('Usar "$enteredEmail"'),
            )
          else
            Text('Ingrese un correo electrónico válido para usar'),
        ],
      ),
    );
  }
}
