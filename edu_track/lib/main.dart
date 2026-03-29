import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthService()),
        RepositoryProvider(create: (_) => FirestoreService()),
      ],
      child: BlocProvider(
        create: (ctx) => AuthBloc(
          authService: ctx.read<AuthService>();
          firestoreService: ctx.read<FirestoreService>(),
        )..add(AuthStarted()),
        child: const SPMApp(),
      ),
    ),
  );
}
