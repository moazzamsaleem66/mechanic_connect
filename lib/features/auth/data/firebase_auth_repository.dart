import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String vehicleType,
    required String vehicleModel,
    required String vehicleNumber,
    required String vehicleColor,
    required String vehicleYear,
    required String vehicleManufacturer,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Could not create user.',
      );
    }

    await user.updateDisplayName(fullName.trim());

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'vehicle': {
          'type': vehicleType,
          'model': vehicleModel.trim(),
          'number': vehicleNumber.trim(),
          'color': vehicleColor.trim(),
          'year': vehicleYear.trim(),
          'manufacturer': vehicleManufacturer.trim(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Avoid leaving an auth-only account when profile/vehicle DB write fails.
      await user.delete();
      throw FirebaseAuthException(
        code: e.code == 'permission-denied'
            ? 'firestore-permission-denied'
            : 'profile-write-failed',
        message: e.message,
      );
    }

    return credential;
  }
}
