import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:note_taking_app/Model/Models/user_model.dart' as user_model;
import 'package:note_taking_app/Model/Models/enumeration.dart' as model;
import 'package:note_taking_app/Service/offline_first_service.dart';

class AuthenticationRepository {
  Future<user_model.User?> login(String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user != null) {
      final uid = userCredential.user!.uid;
      final documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return user_model.User.fromFirestore(documentSnapshot);
    }

    return null;
  }

  Future<user_model.User?> loginAnonymously() async {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInAnonymously();
    if (userCredential.user != null) {
      final uid = userCredential.user!.uid;
      final documentReference = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final documentSnapshot = await documentReference.get();
      if (documentSnapshot.exists) {
        return user_model.User.fromFirestore(documentSnapshot);
      } else {
        final newUser = user_model.User(
          uid: uid,
          name: 'Guest User',
          userType: model.UserType.guest,
        );
        await documentReference.set(newUser.toMap());
        final newDocumentSnapshot = await documentReference.get();
        return user_model.User.fromFirestore(newDocumentSnapshot);
      }
    }
    return null;
  }

  Future<user_model.User> linkAnonymousAccountToEmail(
    String name,
    model.UserType userType,
    String email,
    String password,
  ) async {
    // Link account.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No account to upgrade.");
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.linkWithCredential(credential);

    // Update data in Firebase Firestore.
    user_model.User userModel = user_model.User(
      uid: user.uid,
      name: name,
      email: email,
      userType: userType,
    );
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update(userModel.toMap());
    return userModel;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<User?> signUp(
    String name,
    model.UserType userType,
    String email,
    String password,
  ) async {
    UserCredential? userCredential;

    // Create new user in Firebase Authentication.
    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(name);

      final user = userCredential.user;

      // Create new user in Firebase Firestore.
      if (user != null) {
        user_model.User createdUser = user_model.User(
          uid: user.uid,
          name: name,
          email: user.email,
          profileUrl: user.photoURL,
          userType: userType,
        );
        final createdUserMap = createdUser.toMap();
        createdUserMap.remove('uid');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(createdUserMap);
      }
      return user;
    } catch (ex) {
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      rethrow;
    }
  }

  Future<void> deleteAccount(String email) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Re-enter credentials to continue.");
    }

    for (final p in user.providerData) {
      print('PROVIDER: ${p.providerId}');
    }

    // final AuthCredential credential = EmailAuthProvider.credential(
    //   email: email,
    //   password: password,
    // );
    // await user.reauthenticateWithCredential(credential);
    final collection = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await collection.delete();
    await user.delete();
  }

  Future<void> updateProfile(
    String? name,
    String? email,
    String? password,
    String? profileUrl,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Session expired. Please enter password to continue.');
    }
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    if (name != null) {
      await currentUser.updateDisplayName(name);
      await collection.setOfflineSafe({'name': name});
    }
    if (email != null) {
      await currentUser.verifyBeforeUpdateEmail(email);
      await collection.setOfflineSafe({'email': email});
    }
    if (email != null && password != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      try {
        await currentUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (ex) {
        if (ex.code == "wrong-password") {
          throw Exception("Incorrect password.");
        }
      }
      
      await currentUser.updatePassword(password);
    }
    if (profileUrl != null) {
      await currentUser.updatePhotoURL(profileUrl);
      await collection.setOfflineSafe({'profileUrl': profileUrl});
    }
  }
}
