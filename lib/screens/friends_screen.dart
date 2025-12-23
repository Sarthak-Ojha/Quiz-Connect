import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_code_screen.dart';
import 'multiplayer_quiz_screen.dart';
import '../services/database_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view friends')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: _buildCombinedView(currentUser.uid),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRCodeScreen()),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan QR Code',
      ),
    );
  }

  Widget _buildCombinedView(String currentUserId) {
    return ListView(
      children: [
        // Game Invites Section
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('game_invites')
              .where('to', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, inviteSnapshot) {
            if (!inviteSnapshot.hasData || inviteSnapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🎮 Game Challenges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...inviteSnapshot.data!.docs.map((invite) {
                  final inviteData = invite.data() as Map<String, dynamic>;
                  final fromUserId = inviteData['from'] as String;
                  final gameId = inviteData['gameId'] as String;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(fromUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      final challengerName = userData?['displayName'] ?? 'Someone';
                      final photoUrl = userData?['photoURL'];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(
                            '$challengerName challenged you!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('1v1 Quiz Battle'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final currentUser = FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      debugPrint('❌ No current user');
                                      return;
                                    }
                                    
                                    debugPrint('🎮 Accepting challenge for game: $gameId');
                                    
                                    // Capture the Navigator before any async operations
                                    final navigator = Navigator.of(context);
                                    
                                    // Join the game by updating Firestore
                                    debugPrint('🔄 Updating game $gameId with guestId: ${currentUser.uid}');
                                    await FirebaseFirestore.instance
                                        .collection('multiplayer_games')
                                        .doc(gameId)
                                        .update({
                                      'guestId': currentUser.uid,
                                      'status': 'ready',
                                      'scores.${currentUser.uid}': {
                                        'correctAnswers': 0,
                                        'totalAnswered': 0,
                                        'answers': [],
                                      },
                                    });
                                    
                                    debugPrint('✅ Game joined successfully - status set to ready');
                                    
                                    // Delete the invite
                                    await invite.reference.delete();
                                    debugPrint('✅ Invite deleted');
                                    
                                    debugPrint('🎮 Navigating guest to game screen...');
                                    
                                    // Navigate immediately using the captured navigator
                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => MultiplayerQuizScreen(
                                          gameId: gameId,
                                          isHost: false,
                                        ),
                                      ),
                                    );
                                    debugPrint('✅ Guest navigation initiated');
                                  } catch (e) {
                                    debugPrint('❌ Error accepting challenge: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error accepting challenge: $e')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  await invite.reference.delete();
                                },
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
                const Divider(height: 32),
              ],
            );
          },
        ),
        
        // Friend Requests Section
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('friend_requests')
              .where('to', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, requestSnapshot) {
            if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '👥 Friend Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...requestSnapshot.data!.docs.map((request) {
                  final requestData = request.data() as Map<String, dynamic>;
                  final fromUserId = requestData['from'] as String;
                  final fromNameFallback = requestData['fromName'] as String?;
                  final fromPhotoFallback = requestData['fromPhotoURL'] as String?;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(fromUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                      final displayName = userData?['displayName'] ?? fromNameFallback ?? 'Unknown User';
                      final photoUrl = userData?['photoURL'] ?? userData?['photoUrl'] ?? fromPhotoFallback;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(displayName),
                          subtitle: const Text('wants to be your friend'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  await _acceptFriendRequest(request.id, fromUserId, currentUserId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () async {
                                  // Update status to rejected (receiver cannot delete per rules)
                                  await request.reference.update({
                                    'status': 'rejected',
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
                const Divider(height: 32),
              ],
            );
          },
        ),
        
        // Friends List Section
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            ' My Friends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .orderBy('since', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final friends = snapshot.data?.docs ?? [];
            if (friends.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No friends yet. Add some friends!')),
              );
            }

            return Column(
              children: friends.map((friendDoc) {
                final friendId = friendDoc.id;
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                    final nameFromUserDoc = (userData?['displayName'] as String?)?.trim();
                    final displayName = (nameFromUserDoc != null && nameFromUserDoc.isNotEmpty)
                        ? nameFromUserDoc
                        : 'User ${friendId.substring(0, 6)}';
                    final photoUrl = userData?['photoURL'] ?? userData?['photoUrl'];
                    final isOnline = userData?['isOnline'] ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOnline ? Colors.green.shade300 : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onLongPress: () => _showRemoveFriendDialog(friendId, displayName, currentUserId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar with online indicator
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isOnline ? Colors.green : Colors.grey.shade400,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                      child: photoUrl == null ? const Icon(Icons.person, size: 32) : null,
                                    ),
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              
                              // Name and status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isOnline ? 'Online!' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                                        fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Challenge button
                              Container(
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.orange : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.sports_esports, color: Colors.white),
                                  tooltip: 'Challenge',
                                  onPressed: isOnline ? () => _challengeFriend(friendId, displayName) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _acceptFriendRequest(String requestId, String fromUserId, String currentUserId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Add to both users' friends collections
      final currentUserFriendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(fromUserId);

      final otherUserFriendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(currentUserId);

      batch.set(currentUserFriendRef, {'since': FieldValue.serverTimestamp()});
      batch.set(otherUserFriendRef, {'since': FieldValue.serverTimestamp()});

      // Mark request accepted (receiver can update per rules)
      final requestRef = FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId);
      batch.update(requestRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }



  Future<void> _challengeFriend(String friendId, String friendName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Challenge $friendName'),
        content: const Text('Start a 1v1 quiz battle with random questions from all categories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Challenge'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create game with random questions from all categories
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final gameId = await DatabaseService().createMultiplayerGame(
      hostId: currentUser.uid,
      category: 'Mixed', // Not used anymore, but kept for compatibility
      questionCount: 10,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create game. No questions available.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Send challenge notification to friend (via Firestore)
    await FirebaseFirestore.instance
        .collection('game_invites')
        .doc('${currentUser.uid}_$friendId')
        .set({
      'gameId': gameId,
      'from': currentUser.uid,
      'to': friendId,
      'category': 'Mixed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Navigate host to game screen to wait for opponent
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerQuizScreen(
          gameId: gameId,
          isHost: true,
        ),
      ),
    );
  }


  Future<void> _showRemoveFriendDialog(String friendId, String friendName, String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove $friendName from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove friend from current user's friends list
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendId)
            .delete();

        // Remove current user from friend's friends list
        // Firebase rules allow this since request.auth.uid == friendId in the friends subcollection rule
        await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('friends')
            .doc(currentUserId)
            .delete();

        // Clean up friend request sent by current user to this friend (if exists)
        try {
          await FirebaseFirestore.instance
              .collection('friend_requests')
              .doc('${currentUserId}_$friendId')
              .update({
            'status': 'removed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('No outgoing friend request to update: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$friendName has been removed from your friends list'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove friend: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

}
