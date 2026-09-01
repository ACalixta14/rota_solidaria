import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../services/session_service.dart';
import '../admin/admin_home_screen.dart';
import 'login_screen.dart';



class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _authRepository = AuthRepository();

  StreamSubscription<AuthState>? _authSubscription;
  Future<AppUser?>? _profileFuture;

  @override
  void initState() {
    super.initState();

    _loadCurrentProfile();

    // Escuta mudanças de autenticação:
    // login, logout, renovação de sessão etc.
    _authSubscription =
        _authRepository.authStateChanges.listen((authState) {
      if (!mounted) return;

//Atualização das variáveis carregadas na tela
      setState(() {
//"o usuário acabou de sair?"
        if (authState.session == null) {
//"limpe todas as informações da sessão"
          SessionService.instance.clear();
//"esta tela não possui mais um perfil para carregar"
          _profileFuture = null;
//"existe um usuario logado, então:"
        } else {
//"comece a carregar o perfil do usuário logado"
          _profileFuture = _authRepository.getCurrentProfile();
        }
      });
    });
  }

  void _loadCurrentProfile() {
    if (_authRepository.currentSession == null) {
      SessionService.instance.clear();
      _profileFuture = null;
      return;
    }

    _profileFuture = _authRepository.getCurrentProfile();
  }

  Future<void> _retryProfile() async {
    setState(() {
      _profileFuture = _authRepository.getCurrentProfile();
    });
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Não existe sessão.
    if (_authRepository.currentSession == null) {
      return const LoginScreen();
    }

    final profileFuture = _profileFuture;

    if (profileFuture == null) {
      return const _LoadingScreen();
    }

    return FutureBuilder<AppUser?>(
      future: profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          return _ProfileErrorScreen(
            error: snapshot.error,
            onRetry: _retryProfile,
            onSignOut: _signOut,
          );
        }

        final appUser = snapshot.data;

        if (appUser == null) {
          return _ProfileNotFoundScreen(
            onRetry: _retryProfile,
            onSignOut: _signOut,
          );
        }

        if (!appUser.isActive) {
          return _InactiveUserScreen(
            user: appUser,
            onSignOut: _signOut,
          );
        }

        if (appUser.roles.isEmpty) {
          return _MissingRoleScreen(
            user: appUser,
            onRetry: _retryProfile,
            onSignOut: _signOut,
          );
        }

    if (appUser.canManage || appUser.isVolunteer) {
  return AdminHomeScreen(user: appUser);
}

        return _MissingRoleScreen(
          user: appUser,
          onRetry: _retryProfile,
          onSignOut: _signOut,
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  final Object? error;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const _ProfileErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro ao carregar perfil'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar os dados do utilizador.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: onSignOut,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNotFoundScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const _ProfileNotFoundScreen({
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil não encontrado'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'A conta foi autenticada, mas o perfil não foi encontrado.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: onSignOut,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveUserScreen extends StatelessWidget {
  final AppUser user;
  final Future<void> Function() onSignOut;

  const _InactiveUserScreen({
    required this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso desativado'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Olá, ${user.fullName}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'O seu acesso está desativado. Entre em contacto com a coordenação da Rota Solidária.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSignOut,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingRoleScreen extends StatelessWidget {
  final AppUser user;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const _MissingRoleScreen({
    required this.user,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil sem função'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.manage_accounts_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                '${user.fullName}, o seu perfil ainda não possui uma função.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Peça a um administrador para verificar o seu acesso.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Verificar novamente'),
              ),
              TextButton(
                onPressed: onSignOut,
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolunteerTemporaryScreen extends StatelessWidget {
  final AppUser user;
  final Future<void> Function() onSignOut;

  const _VolunteerTemporaryScreen({
    required this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Solidária'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Olá, ${user.fullName}!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'O seu acesso de voluntário está ativo. A área operacional será desenvolvida nas próximas etapas.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}