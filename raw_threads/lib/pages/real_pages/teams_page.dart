import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final _adminIdController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _teamMembers = [];

  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _teamListener;

  User? get currentUser => _auth.currentUser;

  Future<String?> _getUserRole(String uid) async {
    final snap = await _dbRef.child('users').child(uid).child('role').get();
    if (snap.exists) {
      return snap.value as String;
    }
    return null;
  }

  String? _adminCode;

  void _listenToTeamMembers() {
    final adminId = currentUser!.uid;

    _teamListener = _dbRef
        .child('users')
        .orderByChild('adminId')
        .equalTo(adminId)
        .onValue
        .listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
        final members = rawMap.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value);
          map['uid'] = e.key;
          return map;
        }).toList();

        setState(() {
          _teamMembers = members;
        });
      } else {
        setState(() {
          _teamMembers = [];
        });
      }
    });
  }
  
  Future<void> _loadTeamMembers() async {
    if (currentUser == null) return;
    setState(() => _loading = true);

    final adminId = currentUser!.uid;

    final codeSnap = await _dbRef.child('admins').child(adminId).child('code').get();
    if (codeSnap.exists) {
      _adminCode = codeSnap.value as String?;
    } else {
      _adminCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      await _dbRef.child('admins').child(adminId).set({
        'code': _adminCode,
      });
    }

    final snapshot = await _dbRef.child('users').orderByChild('adminId').equalTo(adminId).get();

    if (snapshot.exists) {
      final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> members = [];
      rawMap.forEach((key, value) {
        final map = Map<String, dynamic>.from(value);
        map['uid'] = key;
        members.add(map);
      });
      setState(() {
        _teamMembers = members;
      });
    } else {
      setState(() {
        _teamMembers = [];
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _linkUserToAdminCode(String code) async {
    if (currentUser == null) return;

    final role = await _getUserRole(currentUser!.uid);
    if (role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admins do not link to other admins')),
      );
      return;
    }

    // Find admin UID by code
    final snapshot = await _dbRef.child('admins').get();
    String? foundAdminId;
    if (snapshot.exists) {
      final admins = Map<String, dynamic>.from(snapshot.value as Map);
      admins.forEach((uid, value) {
        final data = Map<String, dynamic>.from(value);
        if (data['code'] == code) {
          foundAdminId = uid;
        }
      });
    }

    if (foundAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admin code')),
      );
      return;
    }

    await _dbRef.child('users').child(currentUser!.uid).update({
      'adminId': foundAdminId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully linked to admin')),
    );

    _adminIdController.clear();
    setState(() {});
  }


  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    _teamListener?.cancel();
    _adminIdController.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    if (currentUser == null) return;
    final role = await _getUserRole(currentUser!.uid);
    if (role == 'admin') {
      await _loadOrGenerateAdminCode();
      _listenToTeamMembers();
    }
    setState(() {});
  }

  Future<void> _loadOrGenerateAdminCode() async {
    final adminId = currentUser!.uid;

    final codeSnap = await _dbRef.child('admins').child(adminId).child('code').get();
    if (codeSnap.exists) {
      _adminCode = codeSnap.value as String?;
    } else {
      _adminCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      await _dbRef.child('admins').child(adminId).set({'code': _adminCode});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return FutureBuilder<String?>(
      future: _getUserRole(currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data;

        if (_loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (role == 'admin') {
          return Scaffold(
            appBar: AppBar(title: const Text('Teams')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ 
                  if (_adminCode != null) ...[
                    Text('Your Admin Code: $_adminCode', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                  ],
                _teamMembers.isEmpty
                    ? const Center(child: Text('No team members linked yet.'))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _teamMembers.length,
                          itemBuilder: (context, index) {
                            final user = _teamMembers[index];
                            return ListTile(
                              title: Text(user['email'] ?? 'No email'),
                              subtitle: Text('${user['username']}'),
                            );
                          },
                        ),
              ),
                ],
              ),  
            ),
          );
        } else {
          // Regular user view
          return Scaffold(
            appBar: AppBar(title: const Text('Link to Admin')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter Admin ID to link:', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adminIdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Admin UID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final input = _adminIdController.text.trim();
                      if (input.length == 6) {
                        _linkUserToAdminCode(input);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin Code must be 6 characters long')),
                        );
                      }
                    },
                    child: const Text('Link to Admin'),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<DataSnapshot>(
                    future: _dbRef.child('users').child(currentUser!.uid).child('adminId').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }
                      final linkedAdminId = snapshot.data!.value as String?;
                      if (linkedAdminId == null) return const SizedBox();
                      return Text(
                        'Currently linked to Admin ID:\n$linkedAdminId',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
