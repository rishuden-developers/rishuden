import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CharacterUtils {
  static Future<String?> getCurrentCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data()?['character'] != null) {
        return doc.data()?['character'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching character: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<bool> isCharacterSelected() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      return doc.exists && doc.data()?['characterSelected'] == true;
    } catch (e) {
      print('Error checking character selection: $e');
      return false;
    }
  }
}
