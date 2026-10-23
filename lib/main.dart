import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/session.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'widgets/app_logo.dart';
import 'config.dart';

void main() {
  runApp(const EdmateApp());
}

class EdmateApp extends StatefulWidget {
  const EdmateApp({super.key});

  @override
  State<EdmateApp> createState() => _EdmateAppState();
}

class _EdmateAppState extends State<EdmateApp> {
  final Session _session = Session();
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _session.restore().whenComplete(() {
      if (mounted) setState(() => _restoring = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Same brand blue the web admin/edmate redesign uses
    // (theme-vibrant-edmate.css: hsl(217 91% 60%)) — kept as-is per the
    // user's call to keep the existing blue theme rather than adopt the
    // new logo's navy/gold palette; the logo is used as imagery only.
    const brandBlue = Color(0xFF3B82F6);
    const surfaceBg = Color(0xFFF5F7FB);

    return ChangeNotifierProvider.value(
      value: _session,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: brandBlue,
            primary: brandBlue,
          ),
          scaffoldBackgroundColor: surfaceBg,
          splashFactory: InkRipple.splashFactory,
          appBarTheme: const AppBarTheme(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: .1,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 3,
            shadowColor: brandBlue.withOpacity(0.14),
            surfaceTintColor: Colors.transparent,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: brandBlue, width: 1.6),
            ),
          ),
          chipTheme: ChipThemeData(
            selectedColor: brandBlue,
            backgroundColor: const Color(0xFFEDF2FC),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.white),
            shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: brandBlue.withOpacity(0.14),
            elevation: 10,
            height: 64,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? brandBlue : Colors.grey[600],
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(color: selected ? brandBlue : Colors.grey[500]);
            }),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
        ),
        home: _restoring
            ? const _SplashScreen()
            : Consumer<Session>(
                builder: (context, session, _) {
                  return session.isLoggedIn
                      ? const HomeShell()
                      : const LoginScreen();
                },
              ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(size: 84),
            SizedBox(height: 20),
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF3B82F6)),
            ),
          ],
        ),
      ),
    );
  }
}
