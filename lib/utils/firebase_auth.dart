import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<String> sendCode(String phoneNumber) async {
  Firebase.initializeApp();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String verificationId_ = "";

  await auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await auth.signInWithCredential(credential);
      print("User signed in automatically!");
    },

    verificationFailed: (FirebaseAuthException e) {
      print("Verification failed: ${e.message}");
    },

    codeSent: (String verificationId, int? resendToken) {
      verificationId_ = verificationId;
      print("Code sent! VerificationId: $verificationId");
    },

    codeAutoRetrievalTimeout: (String verificationId) {
      verificationId_ = verificationId;
      print("Timeout: $verificationId");
    },
  );

  return verificationId_;
}