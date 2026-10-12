import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_app/theme/color.dart';

class AdminAdoptionScreen extends StatelessWidget {
  const AdminAdoptionScreen({super.key});

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return 'Date unavailable';

    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateRequest({
    required BuildContext context,
    required String requestId,
    required Map<String, dynamic> request,
    required bool accept,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final requestRef =
        firestore.collection('adoption_requests').doc(requestId);

    final petId = (request['petId'] ?? '').toString();

    if (petId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has no pet ID.')),
      );
      return;
    }

    final petRef = firestore.collection('pets').doc(petId);

    try {
      await firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('This adoption request no longer exists.');
        }

        final currentRequest = requestSnapshot.data()!;
        final currentStatus =
            (currentRequest['status'] ?? 'pending')
                .toString()
                .toLowerCase();

        if (currentStatus != 'pending') {
          throw Exception('This request has already been reviewed.');
        }

        final petSnapshot = await transaction.get(petRef);

        if (!petSnapshot.exists) {
          throw Exception('The pet could not be found.');
        }

        final petData = petSnapshot.data()!;

        if (accept &&
            (petData['is_adopted'] == true ||
                petData['adopted'] == true)) {
          throw Exception('This pet has already been adopted.');
        }

        transaction.update(requestRef, {
          'status': accept ? 'accepted' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        });

        if (accept) {
          transaction.update(petRef, {
            'is_adopted': true,
          });
        }
      });

      // Once a pet is accepted, close its other pending requests.
      if (accept) {
        final otherRequests = await firestore
            .collection('adoption_requests')
            .where('petId', isEqualTo: petId)
            .where('status', isEqualTo: 'pending')
            .get();

        final batch = firestore.batch();

        for (final document in otherRequests.docs) {
          if (document.id != requestId) {
            batch.update(document.reference, {
              'status': 'rejected',
              'reviewedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        if (otherRequests.docs.isNotEmpty) {
          await batch.commit();
        }
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Adoption request accepted!'
                : 'Adoption request rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update the request: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      appBar: AppBar(
        title: const Text('Adoption Management'),
        backgroundColor: AppColor.appBgColor,
        foregroundColor: AppColor.textColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('adoption_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load adoption requests.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = [...snapshot.data!.docs];

          requests.sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];

            final aTime =
                aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
            final bTime =
                bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;

            return bTime.compareTo(aTime);
          });

          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets, size: 55, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No adoption requests yet.',
                      style: TextStyle(fontSize: 17),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'New requests will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final document = requests[index];
              final data = document.data();

              final petName =
                  (data['petName'] ?? 'Unknown pet').toString();
              final email =
                  (data['userEmail'] ?? 'Email unavailable').toString();
              final status =
                  (data['status'] ?? 'pending').toString();
              final pending = status.toLowerCase() == 'pending';

              return Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColor.primary.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.pets,
                              color: AppColor.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  petName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Requested: ${_formatDate(data['createdAt'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColor.labelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (pending) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateRequest(
                                  context: context,
                                  requestId: document.id,
                                  request: data,
                                  accept: false,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateRequest(
                                  context: context,
                                  requestId: document.id,
                                  request: data,
                                  accept: true,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}