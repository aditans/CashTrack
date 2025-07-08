import 'package:cashtrack/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cashtrack/screens/profile_page.dart';
import 'package:cashtrack/screens/groups_page.dart';
import 'friends_page.dart';
import 'Skillup_page.dart';
import 'transactions_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_model.dart';
import '../models/split_model.dart';
import 'individual_chat.dart';

void main() {
  runApp(const myapp());
}

class myapp extends StatelessWidget {
  const myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GroupsSplitsFriendsPage(),
    );
  }
}

class GroupsSplitsFriendsPage extends StatefulWidget {
  const GroupsSplitsFriendsPage({super.key});

  @override
  State<GroupsSplitsFriendsPage> createState() => _GroupsSplitsFriendsPageState();
}

class _GroupsSplitsFriendsPageState extends State<GroupsSplitsFriendsPage> {
  int selectedTabIndex = 0;
  int selectedBottomNavIndex = 3;

  final List<String> tabLabels = ['Groups', 'Splits', 'Friends'];

  void _onBottomNavTapped(int index) {
    setState(() {
      selectedBottomNavIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SkillupPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionsPage()),
      );
    // } else if (index == 0) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (_) => const HomeScreen()),
    //   );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black,
        backgroundColor: const Color(0xFF00CCCC),
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Image.asset(
            'assets/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Transform.translate(
          offset: const Offset(-25, -5),
          child: const Text(
            'Groups & Splits',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 30,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFCCF2FF)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Moving blue underline
                AnimatedAlign(
                  alignment: selectedTabIndex == 0
                      ? Alignment.centerLeft
                      : selectedTabIndex == 1
                      ? Alignment.center
                      : Alignment.centerRight,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width / 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFFF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BFFF).withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab labels
                Row(
                  children: List.generate(tabLabels.length, (index) {
                    final isSelected = selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTabIndex = index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    index == 0
                                        ? Icons.group
                                        : index == 1
                                        ? Icons.swap_horiz
                                        : Icons.person,
                                    color: isSelected
                                        ? Colors.teal[800]
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tabLabels[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Body content
            Expanded(
              child: IndexedStack(
                index: selectedTabIndex,
                children: const [
                  GroupsContent(),
                  SplitsContent(),
                  FriendsContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF00CCE7),
        unselectedItemColor: Color(0xFF949FA5),
        currentIndex: selectedBottomNavIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'SkillUp'),
          BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Splits'),
        ],
      ),
    );
  }
}


class SplitsBody extends StatefulWidget {
  const SplitsBody({super.key});

  @override
  State<SplitsBody> createState() => _SplitsBodyState();
}

class _SplitsBodyState extends State<SplitsBody> {
  int selectedTabIndex = 0;
  int selectedBottomNavIndex = 3;

  final List<String> tabLabels = ['Groups', 'Splits', 'Friends'];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFCCF2FF)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          _TabSelector(
            tabLabels: tabLabels,
            selectedTabIndex: selectedTabIndex,
            onTabTapped: (idx) => setState(() => selectedTabIndex = idx),
          ),
          const SizedBox(height: 30),
          // Body
          Expanded(
            child: IndexedStack(
              index: selectedTabIndex,
              children: const [
                GroupsContent(), // Replace with your actual widget
                SplitsContent(),
                FriendsContent(), // Replace with your actual widget
              ],
            ),
          ),
        ],
      ),

    );
  }
}






// Enhanced SplitsContent with full expense splitting functionality
class SplitsContent extends StatefulWidget {
  const SplitsContent({super.key});

  @override
  State<SplitsContent> createState() => _SplitsContentState();
}

class _SplitsContentState extends State<SplitsContent> {
  late Box<FriendModel> _friendsBox;
  late Box<SplitModel> _splitsBox;
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) _currentUid = user.uid;

    Future.wait([
      Hive.openBox<FriendModel>('friends_$_currentUid'),
      Hive.openBox<SplitModel>('splits_$_currentUid'),
    ]).then((boxes) {
      _friendsBox = boxes[0] as Box<FriendModel>;
      _splitsBox = boxes[1] as Box<SplitModel>;
      if (mounted) setState(() {});
    });
  }

  Widget _buildSplitCard(SplitModel split) {
    final friendNames = split.involvedFriends.map((uid) {
      final friend = _friendsBox.values.firstWhere(
            (f) => f.uid == uid,
        orElse: () =>
            FriendModel(uid: uid, displayName: 'Unknown', code: '', addedAt: DateTime.now()),
      );
      return friend.displayName;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81D4FA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Color(0xFF81D4FA)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    split.note,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '₹${split.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Split among: ${friendNames.join(', ')} & You',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Amount per person: ₹${split.amountPerPerson.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${DateFormat('dd/MM/yyyy').format(split.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditSplitDialog(split),
                  icon: const Icon(Icons.edit,
                      size: 16, color: Color(0xFF81D4FA)),
                  label: const Text('Edit',
                      style: TextStyle(color: Color(0xFF81D4FA))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _settleSplit(split),
                  icon: const Icon(Icons.check,
                      size: 16, color: Colors.white),
                  label:
                  const Text('Settle', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showSplitDialog() async {
    await _showEditSplitDialog();
  }

  Future<void> _showEditSplitDialog([SplitModel? existing]) async {
    final isEditing = existing != null;

    final amountCtrl = TextEditingController(
        text: isEditing ? existing.totalAmount.toString() : '');
    final noteCtrl =
    TextEditingController(text: isEditing ? existing.note : '');
    final searchCtrl = TextEditingController();

    final selectedFriends = <String>{
      if (isEditing) ...existing!.involvedFriends
    };

    String searchQuery = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final filteredFriends = searchQuery.isEmpty
              ? _friendsBox.values.toList()
              : _friendsBox.values
              .where((f) => f.displayName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Split' : 'Split Expense',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Total Amount', prefix: '₹ '),
                  ),
                  const SizedBox(height: 16),
                  // Note
                  TextField(
                    controller: noteCtrl,
                    decoration: _inputDecoration(
                      'Note/Purpose',
                      hint: 'e.g., Dinner at restaurant',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setDlgState(() => searchQuery = v),
                    decoration: _inputDecoration(
                      'Search friends to split with',
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF81D4FA)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Friends list
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: const Color(0xFF81D4FA)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: filteredFriends.isEmpty
                          ? const Center(
                        child: Text('No friends found',
                            style: TextStyle(color: Colors.grey)),
                      )
                          : ListView.builder(
                        itemCount: filteredFriends.length,
                        itemBuilder: (_, i) {
                          final friend = filteredFriends[i];
                          return CheckboxListTile(
                            activeColor: const Color(0xFF81D4FA),
                            title: Text(friend.displayName),
                            subtitle: Text(friend.code,
                                style:
                                const TextStyle(fontSize: 12)),
                            value:
                            selectedFriends.contains(friend.uid),
                            onChanged: (val) => setDlgState(() {
                              if (val == true) {
                                selectedFriends.add(friend.uid);
                              } else {
                                selectedFriends.remove(friend.uid);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81D4FA)),
                onPressed: () async {
                  final amount =
                  double.tryParse(amountCtrl.text.trim());
                  final note = noteCtrl.text.trim();

                  if (amount == null || amount <= 0) {
                    _showSnack('Please enter a valid amount');
                    return;
                  }
                  if (selectedFriends.isEmpty) {
                    _showSnack('Please select at least one friend');
                    return;
                  }
                  if (note.isEmpty) {
                    _showSnack('Please enter a note/purpose');
                    return;
                  }

                  Navigator.pop(ctx);

                  if (isEditing) {
                    await _updateSplit(existing!.splitId, amount, note,
                        selectedFriends.toList());
                  } else {
                    await _createSplit(
                        amount, note, selectedFriends.toList());
                  }
                },
                child: Text(isEditing ? 'Update' : 'Split'),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label,
      {String? prefix, String? hint, Widget? prefixIcon}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFE3F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF81D4FA)),
        ),
      );



  Future<void> _createSplit(
      double amount, String note, List<String> friendUids) async {
    final splitId = DateTime.now().millisecondsSinceEpoch.toString();
    final totalPeople = friendUids.length + 1;
    final amountPerPerson = amount / totalPeople;

    final split = SplitModel(
      splitId: splitId,
      totalAmount: amount,
      amountPerPerson: amountPerPerson,
      note: note,
      involvedFriends: friendUids,
      createdBy: _currentUid,
      createdAt: DateTime.now(),
    );

    await _splitsBox.put(splitId, split);

    await FirebaseFirestore.instance.collection('splits').doc(splitId).set({
      'splitId': splitId,
      'totalAmount': amount,
      'amountPerPerson': amountPerPerson,
      'note': note,
      'involvedFriends': friendUids,
      'createdBy': _currentUid,
      'createdAt': FieldValue.serverTimestamp(),
      'isPaid': false,
    });

    // Create pending payment docs & notify people
    for (final friendUid in friendUids) {
      await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc('${splitId}_$friendUid')
          .set({
        'splitId': splitId,
        'payerUid': friendUid,
        'receiverUid': _currentUid,
        'amount': amountPerPerson,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'isPaid': false,
      });
      await _sendSplitMessage(
          friendUid, amount, amountPerPerson, note, totalPeople);
    }

    _showSnack(
        'Split created! ₹${amountPerPerson.toStringAsFixed(2)} per person');
  }

  Future<void> _updateSplit(String splitId, double amount, String note,
      List<String> friendUids) async {
    final totalPeople = friendUids.length + 1;
    final amountPerPerson = amount / totalPeople;

    final updated = SplitModel(
      splitId: splitId,
      totalAmount: amount,
      amountPerPerson: amountPerPerson,
      note: note,
      involvedFriends: friendUids,
      createdBy: _currentUid,
      createdAt: DateTime.now(),
    );

    await _splitsBox.put(splitId, updated);

    await FirebaseFirestore.instance.collection('splits').doc(splitId).update({
      'totalAmount': amount,
      'amountPerPerson': amountPerPerson,
      'note': note,
      'involvedFriends': friendUids,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Rebuild pending_payments
    final batch = FirebaseFirestore.instance.batch();

    final old = await FirebaseFirestore.instance
        .collection('pending_payments')
        .where('splitId', isEqualTo: splitId)
        .get();
    for (final doc in old.docs) batch.delete(doc.reference);

    for (final friendUid in friendUids) {
      final ref = FirebaseFirestore.instance
          .collection('pending_payments')
          .doc('${splitId}_$friendUid');
      batch.set(ref, {
        'splitId': splitId,
        'payerUid': friendUid,
        'receiverUid': _currentUid,
        'amount': amountPerPerson,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'isPaid': false,
      });
    }

    await batch.commit();

    _showSnack('Split updated! ₹${amountPerPerson.toStringAsFixed(2)} each');
  }

  Future<void> _settleSplit(SplitModel split) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Split'),
        content: Text(
            'Are you sure you want to settle "${split.note}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
            const Text('Settle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _splitsBox.delete(split.splitId);
    await FirebaseFirestore.instance
        .collection('splits')
        .doc(split.splitId)
        .delete();

    final pending = await FirebaseFirestore.instance
        .collection('pending_payments')
        .where('splitId', isEqualTo: split.splitId)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in pending.docs) batch.delete(doc.reference);
    await batch.commit();

    for (final friendUid in split.involvedFriends) {
      await _sendSettlementMessage(
          friendUid, split.note, split.amountPerPerson);
    }

    _showSnack('Split "${split.note}" settled ✅', bg: Colors.green);
  }


  Future<void> _sendSplitMessage(String friendUid, double totalAmount,
      double amountPerPerson, String note, int totalPeople) async {
    final chatId = _generateChatId(_currentUid, friendUid);
    final msg = '''
💰 Expense Split Request

💵 Total Amount: ₹${totalAmount.toStringAsFixed(2)}
👥 Split among: $totalPeople people
💸 Your share: ₹${amountPerPerson.toStringAsFixed(2)}
📝 Purpose: $note

Please pay ₹${amountPerPerson.toStringAsFixed(2)} for this expense.''';

    await _sendChatMessage(
        chatId, friendUid, msg, 'split_request', 'Expense split request');
  }

  String _generateChatId(String a, String b) => ([a, b]..sort()).join('_');

  Future<void> _sendSettlementMessage(
      String friendUid, String note, double amount) async {
    final chatId = _generateChatId(_currentUid, friendUid);
    final msg = '''
✅ Split Settled

💰 Expense: $note
💸 Amount: ₹${amount.toStringAsFixed(2)}

This split has been marked as settled. Thank you!''';

    await _sendChatMessage(
        chatId, friendUid, msg, 'settlement_notification', 'Split settled');
  }
  Future<void> _sendChatMessage(
      String chatId,
      String friendUid,
      String text,
      String type,
      String lastMsg,
      ) async {
    final chats = FirebaseFirestore.instance.collection('individual_chats');
    await chats.doc(chatId).collection('messages').add({
      'senderId': _currentUid,
      'receiverId': friendUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'messageType': type,
    });

    await chats.doc(chatId).set({
      'participants': [_currentUid, friendUid],
      'lastMessage': lastMsg,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': _currentUid,
    }, SetOptions(merge: true));
  }

  //String _generateChatId(String a, String b) => ([a, b]..sort()).join('_');


  void _showSnack(String txt, {Color bg = Colors.black87}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(txt),
        backgroundColor: bg,
      ));


  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('friends_$_currentUid') || !Hive.isBoxOpen('splits_$_currentUid')) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F9FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.splitscreen, color: Color(0xFF81D4FA)),
                  SizedBox(width: 8),
                  Text(
                    'My Splits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF81D4FA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Splits list
            Expanded(
              child: ValueListenableBuilder<Box<SplitModel>>(
                valueListenable: _splitsBox.listenable(),
                builder:  (_, box, __){

                  if (box.isEmpty) {
                    return const Center(
                      child: Text('No splits yet',
                          style:
                          TextStyle(fontSize: 18, color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (_, i) => _buildSplitCard(box.getAt(i)!),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSplitDialog,
        backgroundColor: const Color(0xFF81D4FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.tabLabels,
    required this.selectedTabIndex,
    required this.onTabTapped,
  });

  final List<String> tabLabels;
  final int selectedTabIndex;
  final ValueChanged<int> onTabTapped;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedAlign(
          alignment: selectedTabIndex == 0
              ? Alignment.centerLeft
              : selectedTabIndex == 1
              ? Alignment.center
              : Alignment.centerRight,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            height: 4,
            width: MediaQuery.of(context).size.width / 3,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFFF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFFF).withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: List.generate(tabLabels.length, (index) {
            final isSelected = selectedTabIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabTapped(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index == 0
                                ? Icons.group
                                : index == 1
                                ? Icons.swap_horiz
                                : Icons.person,
                            color: isSelected
                                ? Colors.teal[800]
                                : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tabLabels[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}