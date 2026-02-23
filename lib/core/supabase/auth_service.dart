import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  Future<AuthResponse> signUp(String email, String password) {
    return supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();

  String? uid() => supabase.auth.currentUser?.id;
}
