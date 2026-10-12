import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_app/screens/adoption_requests_screen.dart';
import 'package:pet_app/theme/color.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  String selectedCategory = 'All';

  final CollectionReference<Map<String, dynamic>> petsCollection =
      FirebaseFirestore.instance.collection('pets');

  final List<String> categories = [
    'All',
    'Dog',
    'Cat',
    'Parrot',
    'Rabbit',
    'Fish',
    'Turtle',
  ];

  String normalizeCategory(dynamic value) {
    if (value == null) return '';

    final category = value.toString().trim().toLowerCase();

    switch (category) {
      case 'dogs':
      case 'puppy':
      case 'puppies':
        return 'dog';

      case 'cats':
      case 'kitten':
      case 'kittens':
        return 'cat';

      case 'bird':
      case 'birds':
      case 'parrots':
        return 'parrot';

      case 'rabbits':
      case 'bunny':
      case 'bunnies':
        return 'rabbit';

      case 'fishes':
        return 'fish';

      case 'turtles':
      case 'tortoise':
      case 'tortoises':
        return 'turtle';

      default:
        return category;
    }
  }

  String getCategory(Map<String, dynamic> pet) {
    final value = pet['category'] ?? pet['type'] ?? pet['species'];
    return normalizeCategory(value);
  }

  bool isAdopted(Map<String, dynamic> pet) {
    final status = (pet['status'] ?? '').toString().toLowerCase();

    return pet['is_adopted'] == true ||
        pet['adopted'] == true ||
        status == 'adopted';
  }

  Future<void> toggleFavourite(
    String petId,
    bool currentValue,
  ) async {
    try {
      await petsCollection.doc(petId).update({
        'is_favorited': !currentValue,
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favourite. Please try again.'),
        ),
      );
    }
  }

  void openMyRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdoptionRequestsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find your friend',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textColor,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: openMyRequests,
                    icon: Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: AppColor.primary,
                    ),
                    label: Text(
                      'My Requests',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 10,
                      ),
                      side: BorderSide(color: AppColor.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Meet pets waiting for a loving home.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.labelColor,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: AppColor.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColor.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColor.primary
                          : Colors.grey.shade300,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: petsCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Could not load pets. Check your connection.',
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final allDocuments = snapshot.data?.docs ?? [];

                  final filteredDocuments = allDocuments.where((doc) {
                    if (selectedCategory == 'All') return true;

                    return getCategory(doc.data()) ==
                        normalizeCategory(selectedCategory);
                  }).toList();

                  if (filteredDocuments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          selectedCategory == 'All'
                              ? 'No pets available yet.'
                              : 'No ${selectedCategory.toLowerCase()} records found yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColor.labelColor,
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: filteredDocuments.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final document = filteredDocuments[index];
                      final pet = document.data();
                      final petId = document.id;
                      final name = (pet['name'] ?? 'Pet').toString();
                      final image = (pet['image'] ?? '').toString();
                      final location =
                          (pet['location'] ?? 'Location unavailable')
                              .toString();
                      final age = (pet['age'] ?? '').toString();
                      final isFavourite = pet['is_favorited'] == true;
                      final adopted = isAdopted(pet);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PetDetailsScreen(
                                  pet: pet,
                                  petId: petId,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    image.isEmpty
                                        ? Container(
                                            color: Colors.grey.shade100,
                                            child: const Icon(
                                              Icons.pets,
                                              size: 45,
                                            ),
                                          )
                                        : Image.network(
                                            image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.pets,
                                                size: 45,
                                              ),
                                            ),
                                          ),
                                    if (adopted)
                                      Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'ADOPTED',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Material(
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            isFavourite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFavourite
                                                ? Colors.red
                                                : AppColor.textColor,
                                            size: 20,
                                          ),
                                          onPressed: () => toggleFavourite(
                                            petId,
                                            isFavourite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  9,
                                  10,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColor.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: AppColor.labelColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColor.labelColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (age.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        age,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColor.labelColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PetDetailsScreen extends StatelessWidget {
  const PetDetailsScreen({
    super.key,
    required this.pet,
    required this.petId,
  });

  final Map<String, dynamic> pet;
  final String petId;

  bool get initiallyAdopted {
    final status = (pet['status'] ?? '').toString().toLowerCase();

    return pet['is_adopted'] == true ||
        pet['adopted'] == true ||
        status == 'adopted';
  }

  Future<void> _submitAdoptionRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before requesting adoption.'),
        ),
      );
      return;
    }

    final name = (pet['name'] ?? 'Pet').toString();
    final firestore = FirebaseFirestore.instance;
    final requestId = '${user.uid}_$petId';

    final requestRef =
        firestore.collection('adoption_requests').doc(requestId);
    final petRef = firestore.collection('pets').doc(petId);

    try {
      await firestore.runTransaction((transaction) async {
        final petSnapshot = await transaction.get(petRef);
        final existingRequest = await transaction.get(requestRef);

        if (!petSnapshot.exists) {
          throw Exception('This pet is no longer available.');
        }

        final latestPet = petSnapshot.data()!;
        final latestStatus =
            (latestPet['status'] ?? '').toString().toLowerCase();

        if (latestPet['is_adopted'] == true ||
            latestPet['adopted'] == true ||
            latestStatus == 'adopted') {
          throw Exception('This pet has already been adopted.');
        }

        if (existingRequest.exists) {
          throw AdoptionRequestAlreadyExists();
        }

        transaction.set(requestRef, {
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'petId': petId,
          'petName': name,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adoption request for $name submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on AdoptionRequestAlreadyExists {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already requested to adopt this pet.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.contains('already been adopted') ||
                    message.contains('no longer available')
                ? message
                : 'Could not submit your request. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (pet['name'] ?? 'Pet').toString();
    final image = (pet['image'] ?? '').toString();
    final description =
        (pet['description'] ?? 'No description available.').toString();
    final isFavourite = pet['is_favorited'] == true;
    final album =
        pet['album'] is List ? pet['album'] as List : <dynamic>[];

    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColor.appBgColor,
        foregroundColor: AppColor.textColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('pets')
                    .doc(petId)
                    .update({
                  'is_favorited': !isFavourite,
                });
              } catch (_) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not update favourite.'),
                  ),
                );
              }
            },
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: isFavourite ? Colors.red : AppColor.textColor,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .doc(petId)
            .snapshots(),
        builder: (context, snapshot) {
          final latestPet = snapshot.data?.data() ?? pet;
          final status =
              (latestPet['status'] ?? '').toString().toLowerCase();
          final adopted = latestPet['is_adopted'] == true ||
              latestPet['adopted'] == true ||
              status == 'adopted';

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: image.isEmpty
                      ? const Center(child: Icon(Icons.pets, size: 60))
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.pets, size: 60)),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (latestPet['location'] ?? 'Location unavailable').toString(),
                style: TextStyle(color: AppColor.labelColor),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _detailTag('Age', latestPet['age']),
                  _detailTag('Sex', latestPet['sex']),
                  _detailTag('Color', latestPet['color']),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'About $name',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColor.labelColor,
                ),
              ),
              if (album.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'More photos',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 105,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: album.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          album[index].toString(),
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.pets),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (adopted)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'This pet has already been adopted. Thank you for caring!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitAdoptionRequest(context),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Adopt Me'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailTag(String label, dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $text',
        style: TextStyle(color: AppColor.textColor),
      ),
    );
  }
}

class AdoptionRequestAlreadyExists implements Exception {}
