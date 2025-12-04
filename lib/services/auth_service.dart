import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: email,
      };
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );
      safePrint('Sign up result: ${result.isSignUpComplete}');
    } on AuthException catch (e) {
      safePrint('Error signing up: ${e.message}');
      rethrow;
    }
  }

  // Confirm Sign Up
  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      safePrint('Confirm sign up result: ${result.isSignUpComplete}');
    } on AuthException catch (e) {
      safePrint('Error confirming sign up: ${e.message}');
      rethrow;
    }
  }

  // Sign In
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      safePrint('Sign in result: ${result.isSignedIn}');
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      safePrint('Signed out');
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
      rethrow;
    }
  }

  // Get Current User
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } on AuthException catch (e) {
      safePrint('Error getting current user: ${e.message}');
      return null;
    }
  }

  Future<bool> isUserSignedIn() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      return result.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Error checking auth session: ${e.message}');
      return false;
    }
  }

  // Check if user is Admin
  Future<bool> isAdmin() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        final idToken = session.userPoolTokensResult.value.idToken;
        final groups = idToken.groups;
        return groups.contains('Admins');
      }
      return false;
    } catch (e) {
      safePrint('Error checking admin status: $e');
      return false;
    }
  }
}
