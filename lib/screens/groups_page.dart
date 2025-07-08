// lib/screens/groups_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // If needed elsewhere
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_model.dart';
import '../models/group_model.dart';
import 'group_chat.dart'; // Your chat screen

class GroupsContent extends StatefulWidget {
  const GroupsContent({Key? key}) : super(key: key);

  @override
  State<GroupsContent> createState() => _GroupsContentState();
}

class _GroupsContentState extends State<GroupsContent> {
  late Box<FriendModel> _friendsBox;
  late Box<GroupModel> _groupsBox;
  late String _currentUid;
  final double _groupsBoxHeightFactor = 0.45;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _currentUid = user.uid;
    Hive.openBox<FriendModel>('friends_$_currentUid')
        .then((b) => setState(() => _friendsBox = b));
    Hive.openBox<GroupModel>('groups_$_currentUid')
        .then((b) => setState(() => _groupsBox = b));
  }

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    final searchCtrl = TextEditingController();
    final selected = <String>{};
    String filter = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final friends = filter.isEmpty
              ? _friendsBox.values.toList()
              : _friendsBox.values
              .where((f) => f.displayName
              .toLowerCase()
              .contains(filter.toLowerCase()))
              .toList();

          return AlertDialog(
            title: const Text(
              'Create Group',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      filled: true,
                      fillColor: const Color(0xFFE3F9FD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: Color(0xFF81D4FA)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setDlgState(() => filter = v),
                    decoration: InputDecoration(
                      labelText: 'Search friends',
                      hintText: 'Type name...',
                      prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF81D4FA)),
                      filled: true,
                      fillColor: const Color(0xFFE3F9FD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: Color(0xFF81D4FA)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF81D4FA)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: friends.isEmpty
                          ? const Center(
                        child: Text(
                          'No friends found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (_, i) {
                          final f = friends[i];
                          return CheckboxListTile(
                            activeColor: const Color(0xFF81D4FA),
                            title: Text(f.displayName),
                            subtitle: Text(f.code,
                                style:
                                const TextStyle(fontSize: 12)),
                            value: selected.contains(f.uid),
                            onChanged: (v) =>
                                setDlgState(() {
                                  if (v == true) {
                                    selected.add(f.uid);
                                  } else {
                                    selected.remove(f.uid);
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
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Enter name & select members')));
                    return;
                  }
                  final id = DateTime.now()
                      .millisecondsSinceEpoch
                      .toString();
                  final group = GroupModel(
                    id: id,
                    name: name,
                    memberUids: selected.toList(),
                    createdAt: DateTime.now(),
                  );
                  _groupsBox.put(id, group);
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(GroupModel g) {
    final names = g.memberUids.map((uid) {
      final f = _friendsBox.values.firstWhere(
            (f) => f.uid == uid,
        orElse: () => FriendModel(
          uid: uid,
          displayName: 'Unknown',
          code: '',
          addedAt: DateTime.now(),
        ),
      );
      return f.displayName;
    }).toList();
    final preview = names.length <= 2
        ? names.join(', ')
        : '${names.take(2).join(', ')}...';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF81D4FA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                groupId: g.id,
                groupName: g.name,
                memberNames: names,     // Pass memberNames here
                description: '',        // Optionally pass a description
              ),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.group, color: Colors.white),
        ),
        title: Text(
          g.name,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        subtitle: Text('Members: $preview',
            style: const TextStyle(color: Colors.white70)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (v) {
            if (v == 'delete') {
              _groupsBox.delete(g.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete Group'))
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_payments')
          .where('payerUid', isEqualTo: _currentUid)
          .where('isPaid', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Text(
                '⚠️ Error loading payments.\nPlease create Firestore composite index for:\n[payerUid==, isPaid==, createdAt desc]',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Expanded(child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Expanded(child: Center(child: Text('No pending payments.', style: TextStyle(color: Colors.grey))));
        }

        return Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              return _buildPendingPaymentTile(data, docId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingPaymentTile(Map<String, dynamic> splitData, String docId) {
    final note = splitData['note'] ?? '';
    final amount = (splitData['amount'] ?? 0.0).toDouble();
    final receiverUid = splitData['receiverUid'] ?? '';
    final createdAtTs = splitData['createdAt'] as Timestamp?;
    final dateStr = createdAtTs != null
        ? DateFormat('dd/MM/yyyy').format(createdAtTs.toDate())
        : 'Unknown date';

    String receiverName = 'Unknown';
    if (Hive.isBoxOpen('friends_$_currentUid')) {
      final f = _friendsBox.values.firstWhere(
            (f) => f.uid == receiverUid,
        orElse: () => FriendModel(uid: receiverUid, displayName: 'Unknown', code: '', addedAt: DateTime.now()),
      );
      receiverName = f.displayName;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.payment, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(note, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('You owe $receiverName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('Date: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: () => _showSplitDetails(splitData),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onPressed: () => _markAsPaid(docId),
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ],
      ),
    );
  }

  void _showSplitDetails(Map<String, dynamic> splitData) {
    final names = List<String>.from(splitData['involvedFriends'] ?? []).map((uid) {
      final f = _friendsBox.values.firstWhere(
            (f) => f.uid == uid,
        orElse: () => FriendModel(uid: uid, displayName: 'Unknown', code: '', addedAt: DateTime.now()),
      );
      return f.displayName;
    }).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(splitData['note'] ?? 'Details'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total: ₹${(splitData['amount'] ?? 0.0).toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Split with: ${names.join(', ')}'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _markAsPaid(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Are you sure you want to mark this as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('pending_payments').doc(docId).update({'isPaid': true});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('friends_$_currentUid') ||
        !Hive.isBoxOpen('groups_$_currentUid')) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final groupsHeight = screenHeight * _groupsBoxHeightFactor;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: groupsHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F9FD),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.group, color: Color(0xFF81D4FA)),
                        SizedBox(width: 8),
                        Text(
                          'My Groups',
                          style: TextStyle(
                              color: Color(0xFF81D4FA),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<Box<GroupModel>>(
                      valueListenable: _groupsBox.listenable(),
                      builder: (_, box, __) {
                        if (box.isEmpty) {
                          return const Center(child: Text('No groups yet.', style: TextStyle(color: Colors.grey)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: box.length,
                          itemBuilder: (_, i) => _buildGroupCard(box.getAt(i)!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                 // or any value you want

                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))
                ]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pending Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildPendingPaymentsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        backgroundColor: const Color(0xFF81D4FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
