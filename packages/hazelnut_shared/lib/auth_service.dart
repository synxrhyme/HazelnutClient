abstract class AuthService {
  Future<String> signUp(String username, String password);

  Future<String?> signIn();

  Future<void> signOut();
}