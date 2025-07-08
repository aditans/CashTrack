import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_model.dart';

class FriendsContent extends StatefulWidget {
  const FriendsContent({super.key});
  @override
  State<FriendsContent> createState() => _FriendsContentState();
}

class _FriendsContentState extends State<FriendsContent> {
  final TextEditingController _searchController = TextEditingController();
  Future<QuerySnapshot>? _searchResults;
  late Box<FriendModel> _friendsBox;
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUid = user.uid;
      Hive.openBox<FriendModel>('friends_$_currentUid').then((box) {
        setState(() {
          _friendsBox = box;
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _searchResults = FirebaseFirestore.instance
          .collection('users')
          .where('extractedId', isEqualTo: code)
          .get();
    });
  }

  Future<void> _addFriend(String friendUid, String name, String code) async {
    if (_currentUid.isEmpty) return;
    // Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .collection('friends')
        .doc(friendUid)
        .set({
      'uid': friendUid,
      'displayName': name,
      'extractedId': code,
      'addedAt': FieldValue.serverTimestamp(),
    });
    // Hive
    final friend = FriendModel(
      uid: friendUid,
      displayName: name,
      code: code,
      addedAt: DateTime.now(),
    );
    await _friendsBox.put(friendUid, friend);
    _searchController.clear();
    setState(() {
      _searchResults = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name as a friend')),
    );
  }

  Future<void> _removeFriend(String friendUid) async {
    if (_currentUid.isEmpty) return;
    // Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .collection('friends')
        .doc(friendUid)
        .delete();
    // Hive
    await _friendsBox.delete(friendUid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('friends_$_currentUid')) {
      return const Center(child: CircularProgressIndicator());
    }

    // Define custom colors
    const lightSkyBlue = Color(0xFFE3F9FD);
    const skyBlue = Color(0xFF4FC3F7);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter user code',
              labelText: 'Search by user code',
              prefixIcon: const Icon(Icons.search, color: skyBlue),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: skyBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: skyBlue, width: 3),
              ),
            ),
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onSearchPressed,
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Search',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: skyBlue),
                ),
                padding: const EdgeInsets.symmetric(vertical: 7),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Firestore search results
          if (_searchResults != null)
            FutureBuilder<QuerySnapshot>(
              future: _searchResults,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('No users found with that code.');
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final uid = doc.id;
                    final name = data['displayName'] ?? 'Unknown';
                    final code = data['extractedId'] ?? '';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: skyBlue, width: 1.5),
                          ),
                          leading: const Icon(Icons.person, color: skyBlue),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Text(code, style: const TextStyle(color: Colors.black54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add, color: skyBlue),
                            onPressed: () => _addFriend(uid, name, code),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );

              },
            ),

          const SizedBox(height: 16),

          // Friends heading with underline and shadow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: skyBlue, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              'Your Friends:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Live friends list from Hive
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _friendsBox.listenable(),
              builder: (context, Box<FriendModel> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('No friends added yet.'));
                }
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final friend = box.getAt(index)!;
                    return ListTile(
                      leading: const Icon(Icons.person, color: skyBlue),
                      title: Text(friend.displayName),
                      subtitle: Text(friend.code),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: skyBlue),
                        onSelected: (value) {
                          if (value == 'remove') {
                            _removeFriend(friend.uid);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove Friend'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
