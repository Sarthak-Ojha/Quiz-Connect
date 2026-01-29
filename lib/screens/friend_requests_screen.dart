import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view friend requests'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending friend requests'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(request['from'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final displayName = userData?['displayName'] ?? 'Unknown User';
                  final photoUrl = userData?['photoURL'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl) 
                          : null,
                      child: photoUrl == null 
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: const Text('Wants to be your friend'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleRequest(
                            request.id, 
                            request['from'], 
                            true
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleRequest(
                            request.id, 
                            request['from'], 
                            false
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
  }

  Future<void> _handleRequest(
    String requestId, 
    String friendId,
    bool accept
  ) async {
    final success = accept
        ? await _databaseService.acceptFriendRequest(requestId, friendId)
        : await _databaseService.rejectFriendRequest(requestId);

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? accept ? 'Friend added successfully!' : 'Request declined'
            : 'Failed to process request'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
