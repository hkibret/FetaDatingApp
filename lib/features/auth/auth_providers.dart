import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
