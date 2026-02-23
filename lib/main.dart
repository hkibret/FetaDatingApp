import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/storage/hive_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw Exception('Missing/invalid SUPABASE_URL. Pass it via --dart-define.');
  }
  if (supabaseAnonKey.isEmpty) {
    throw Exception('Missing SUPABASE_ANON_KEY. Pass it via --dart-define.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;
