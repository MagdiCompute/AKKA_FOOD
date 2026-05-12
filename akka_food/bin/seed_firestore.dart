/// Seed script for populating Firestore with test data.
///
/// Run with: dart run bin/seed_firestore.dart
///
/// This script creates:
/// - Categories (5)
/// - Meals (10+ with images, prices, descriptions)
/// - A user profile document for the currently signed-in user
/// - Sample leaderboard entries

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  print('🌱 Seeding Firestore...\n');

  // ── Categories ──────────────────────────────────────────────────────────
  print('📂 Creating categories...');
  final categories = [
    {'id': 'cat-burgers', 'name': 'Burgers', 'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', 'isActive': true},
    {'id': 'cat-pizza', 'name': 'Pizza', 'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400', 'isActive': true},
    {'id': 'cat-chicken', 'name': 'Chicken', 'imageUrl': 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400', 'isActive': true},
    {'id': 'cat-salads', 'name': 'Salads', 'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400', 'isActive': true},
    {'id': 'cat-drinks', 'name': 'Drinks', 'imageUrl': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400', 'isActive': true},
  ];

  for (final cat in categories) {
    await firestore.collection('categories').doc(cat['id'] as String).set({
      'name': cat['name'],
      'imageUrl': cat['imageUrl'],
      'isActive': cat['isActive'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  print('   ✅ ${categories.length} categories created');

  // ── Meals ───────────────────────────────────────────────────────────────
  print('🍔 Creating meals...');
  final meals = [
    {
      'id': 'meal-classic-burger',
      'name': 'Classic Burger',
      'description': 'Juicy beef patty with lettuce, tomato, and our special sauce.',
      'price': 3500,
      'categoryId': 'cat-burgers',
      'imageUrls': ['https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600'],
      'isAvailable': true,
      'isFeatured': true,
      'calories': 650,
      'preparationTime': 15,
    },
    {
      'id': 'meal-cheese-burger',
      'name': 'Double Cheese Burger',
      'description': 'Two beef patties with melted cheddar, pickles, and onions.',
      'price': 4500,
      'categoryId': 'cat-burgers',
      'imageUrls': ['https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 850,
      'preparationTime': 18,
    },
    {
      'id': 'meal-margherita',
      'name': 'Margherita Pizza',
      'description': 'Fresh mozzarella, basil, and tomato sauce on thin crust.',
      'price': 5000,
      'categoryId': 'cat-pizza',
      'imageUrls': ['https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600'],
      'isAvailable': true,
      'isFeatured': true,
      'calories': 750,
      'preparationTime': 20,
    },
    {
      'id': 'meal-pepperoni',
      'name': 'Pepperoni Pizza',
      'description': 'Loaded with pepperoni, mozzarella, and oregano.',
      'price': 5500,
      'categoryId': 'cat-pizza',
      'imageUrls': ['https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 900,
      'preparationTime': 22,
    },
    {
      'id': 'meal-grilled-chicken',
      'name': 'Grilled Chicken',
      'description': 'Tender grilled chicken breast with herbs and spices.',
      'price': 4000,
      'categoryId': 'cat-chicken',
      'imageUrls': ['https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=600'],
      'isAvailable': true,
      'isFeatured': true,
      'calories': 450,
      'preparationTime': 25,
    },
    {
      'id': 'meal-fried-chicken',
      'name': 'Crispy Fried Chicken',
      'description': 'Golden crispy fried chicken with coleslaw.',
      'price': 3800,
      'categoryId': 'cat-chicken',
      'imageUrls': ['https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 700,
      'preparationTime': 20,
    },
    {
      'id': 'meal-caesar-salad',
      'name': 'Caesar Salad',
      'description': 'Romaine lettuce, croutons, parmesan, and Caesar dressing.',
      'price': 2500,
      'categoryId': 'cat-salads',
      'imageUrls': ['https://images.unsplash.com/photo-1546793665-c74683f339c1?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 350,
      'preparationTime': 10,
    },
    {
      'id': 'meal-greek-salad',
      'name': 'Greek Salad',
      'description': 'Cucumber, tomato, olives, feta cheese with olive oil.',
      'price': 2800,
      'categoryId': 'cat-salads',
      'imageUrls': ['https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 300,
      'preparationTime': 8,
    },
    {
      'id': 'meal-mango-smoothie',
      'name': 'Mango Smoothie',
      'description': 'Fresh mango blended with yogurt and honey.',
      'price': 1500,
      'categoryId': 'cat-drinks',
      'imageUrls': ['https://images.unsplash.com/photo-1546173159-315724a31696?w=600'],
      'isAvailable': true,
      'isFeatured': true,
      'calories': 200,
      'preparationTime': 5,
    },
    {
      'id': 'meal-iced-coffee',
      'name': 'Iced Coffee',
      'description': 'Cold brew coffee with milk and caramel syrup.',
      'price': 1200,
      'categoryId': 'cat-drinks',
      'imageUrls': ['https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600'],
      'isAvailable': true,
      'isFeatured': false,
      'calories': 150,
      'preparationTime': 5,
    },
    {
      'id': 'meal-unavailable',
      'name': 'Seasonal Special (Sold Out)',
      'description': 'This item is currently unavailable.',
      'price': 6000,
      'categoryId': 'cat-burgers',
      'imageUrls': ['https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=600'],
      'isAvailable': false,
      'isFeatured': false,
      'calories': 500,
      'preparationTime': 30,
    },
  ];

  for (final meal in meals) {
    await firestore.collection('meals').doc(meal['id'] as String).set({
      ...meal,
      'createdAt': FieldValue.serverTimestamp(),
    }..remove('id'));
  }
  print('   ✅ ${meals.length} meals created');

  // ── User Profile (for testing) ──────────────────────────────────────────
  print('👤 Creating test user profiles...');

  // Get all users from Firebase Auth (we'll create a profile for a test UID)
  // Since we can't list auth users from client SDK, create a known test profile.
  const testUid = 'REPLACE_WITH_YOUR_UID';
  await firestore.collection('users').doc(testUid).set({
    'displayName': 'Test User',
    'email': 'test@example.com',
    'phoneNumber': null,
    'avatarUrl': null,
    'role': 'admin', // Set as admin so you can test admin features
    'coinBalance': 5000,
    'isDeactivated': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  print('   ✅ Test user profile created (UID: $testUid)');
  print('   ⚠️  IMPORTANT: Replace REPLACE_WITH_YOUR_UID with your actual Firebase Auth UID!');

  // ── Leaderboard entries ─────────────────────────────────────────────────
  print('🏆 Creating leaderboard entries...');
  final leaderboardUsers = [
    {'uid': 'user-1', 'displayName': 'Alice', 'coinBalance': 12500, 'totalOrders': 25},
    {'uid': 'user-2', 'displayName': 'Bob', 'coinBalance': 9800, 'totalOrders': 20},
    {'uid': 'user-3', 'displayName': 'Charlie', 'coinBalance': 7200, 'totalOrders': 15},
    {'uid': 'user-4', 'displayName': 'Diana', 'coinBalance': 5500, 'totalOrders': 11},
    {'uid': 'user-5', 'displayName': 'Eve', 'coinBalance': 3000, 'totalOrders': 6},
  ];

  for (final user in leaderboardUsers) {
    await firestore.collection('users').doc(user['uid'] as String).set({
      'displayName': user['displayName'],
      'email': '${(user['displayName'] as String).toLowerCase()}@example.com',
      'coinBalance': user['coinBalance'],
      'totalOrders': user['totalOrders'],
      'role': 'user',
      'isDeactivated': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  print('   ✅ ${leaderboardUsers.length} leaderboard users created');

  // ── Firestore indexes note ──────────────────────────────────────────────
  print('\n✅ Seeding complete!\n');
  print('📋 Next steps:');
  print('   1. Replace REPLACE_WITH_YOUR_UID in this script with your actual UID');
  print('      (Find it in Firebase Console > Authentication > Users)');
  print('   2. Re-run this script after replacing the UID');
  print('   3. Set Firestore rules to allow authenticated reads:');
  print('      rules_version = "2";');
  print('      service cloud.firestore {');
  print('        match /databases/{database}/documents {');
  print('          match /{document=**} {');
  print('            allow read, write: if request.auth != null;');
  print('          }');
  print('        }');
  print('      }');
  print('   4. Hot-reload the app to see the data');
}
