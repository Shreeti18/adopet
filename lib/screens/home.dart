
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_app/theme/color.dart';
import 'package:pet_app/utils/data.dart' as local_data;
import 'package:pet_app/widgets/category_item.dart';
import 'package:pet_app/widgets/notification_box.dart';
import 'package:pet_app/widgets/pet_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0;

  final CollectionReference<Map<String, dynamic>> _petsCollection =
      FirebaseFirestore.instance.collection('pets');

  @override
  void initState() {
    super.initState();
    _seedPetsIfNeeded();
  }

  Future<void> _seedPetsIfNeeded() async {
    try {
      final existingPets = await _petsCollection.limit(1).get();

      if (existingPets.docs.isNotEmpty) return;

      for (final pet in local_data.pets) {
        final petData = Map<String, dynamic>.from(pet as Map);
        petData.remove('id');
        await _petsCollection.add(petData);
      }

      debugPrint('Pet records uploaded to Firestore.');
    } catch (e) {
      debugPrint('Could not upload pet records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColor.appBarColor,
            pinned: true,
            snap: true,
            floating: true,
            title: _buildAppBar(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  _buildCategories(),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
                    child: Text(
                      'Adopt Me',
                      style: TextStyle(
                        color: AppColor.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  _buildPets(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    color: AppColor.labelColor,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Location',
                    style: TextStyle(
                      color: AppColor.labelColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Phnom Penh, Cambodia',
                style: TextStyle(
                  color: AppColor.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        NotificationBox(
          notifiedNumber: 1,
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 5, left: 15),
      child: Row(
        children: List.generate(
          local_data.categories.length,
          (index) => CategoryItem(
            data: local_data.categories[index],
            selected: index == _selectedCategory,
            onTap: () {
              setState(() {
                _selectedCategory = index;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPets() {
    final double width = MediaQuery.of(context).size.width * 0.8;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _petsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Unable to load pets. Please try again.'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No pets available yet.')),
          );
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: 400,
            enlargeCenterPage: true,
            disableCenter: true,
            viewportFraction: 0.8,
            enableInfiniteScroll: documents.length > 1,
            scrollDirection: Axis.horizontal,
          ),
          items: documents.map((document) {
            final petData = document.data();
            final petId = document.id;

            final cardData = <String, dynamic>{
              ...petData,
              'id': petId,
              'is_favorited': petData['is_favorited'] == true,
            };

            return PetItem(
              data: cardData,
              width: width,
              onTap: null,
              onFavoriteTap: () async {
                final newFavoriteState =
                    cardData['is_favorited'] != true;

                try {
                  await _petsCollection.doc(petId).update({
                    'is_favorited': newFavoriteState,
                  });
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save favourite. Please try again.',
                      ),
                    ),
                  );

                  debugPrint('Error saving favourite: $e');
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
