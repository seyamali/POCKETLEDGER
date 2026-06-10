import 'package:flutter/material.dart';
import 'package:pocketledger/app/routes.dart';
import 'package:pocketledger/app/theme.dart';
import 'dart:async';
import 'package:pocketledger/features/auth/lock_screen.dart';
import 'package:pocketledger/services/security_service.dart';

import 'package:pocketledger/services/theme_service.dart';
import 'package:pocketledger/services/language_service.dart';

class PocketLedgerApp extends StatelessWidget {
  const PocketLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().languageNotifier,
      builder: (context, langCode, _) {
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService().themeModeNotifier,
            builder: (context, themeMode, _) {
              return MaterialApp(
                key: ValueKey(langCode),
                title: 'PocketLedger',
              navigatorKey: AppRoutes.navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: appTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              locale: Locale(langCode),
              initialRoute: AppRoutes.splash,
              routes: AppRoutes.routes,
              builder: (context, child) {
                if (child == null) return const SizedBox();
                return SecurityLifecycleWrapper(child: child);
              },
            );
          },
        );
      },
    );
  }
}

class SecurityLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const SecurityLifecycleWrapper({super.key, required this.child});

  @override
  State<SecurityLifecycleWrapper> createState() => _SecurityLifecycleWrapperState();
}

class _SecurityLifecycleWrapperState extends State<SecurityLifecycleWrapper> with WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();
  bool _isLocked = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLock() async {
    final enabled = await _securityService.isPinEnabled();
    if (enabled) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      return;
    }

    // Lock only after the app has remained paused briefly.
    // This avoids false locks caused by transient overlays or system UI.
    if (state == AppLifecycleState.paused) {
      _scheduleLockIfEnabled();
    }
  }

  void _scheduleLockIfEnabled() {
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(milliseconds: 1200), () {
      _lockIfEnabled();
    });
  }

  Future<void> _lockIfEnabled() async {
    final enabled = await _securityService.isPinEnabled();
    if (enabled && !_isLocked) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      // Instead of layering, we completely hide widget.child to prevent UI leaks
      return LockScreen(
        onSuccess: () {
          setState(() {
            _isLocked = false;
          });
        },
      );
    }
    return widget.child;
  }
}
