import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/providers.dart';
import 'package:to_do_list/util/gradienttextfield.dart';
import 'package:to_do_list/util/smalltextgradient.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(email, pass);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up successful! Please check your email.')));
      } else {
        await auth.signIn(email, pass);
        // Navigation will happen via AuthWrapper
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    return Scaffold(
      backgroundColor: appTheme.background,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: appTheme.background,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: _isSignUp ? Tittlegradient(text: "Sign Up") : Tittlegradient(text: "Sign In" ),
        ),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [


                   Gradienttextfield(controller: _emailController, text: "Email"),


            const SizedBox(height: 12),

                  Gradienttextfield(controller: _passwordController, text: "Password",obscureText: true,),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: 
                ElevatedButton(
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  onPressed: _loading ? null : _authenticate,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appTheme.accentGradientStart, appTheme.accentGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : _isSignUp
                              ? Smalltextgradient(text: "Sign Up", fontsize: 16)
                              : Smalltextgradient(text: "Sign In", fontsize: 16),
                    ),
                  ),
                )
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: _isSignUp ? Smalltextgradient(text: "Already have an account? Sign In", fontsize: 16) : Smalltextgradient(text: 'Don\'t have an account? Sign Up',fontsize: 16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical :8,horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.abc_sharp,size: 35,),
                  Icon(Icons.abc_sharp,size: 35,),
                  Icon(Icons.abc_sharp,size: 35,),
                ]),
            )
          ],
        ),
      ),
    );
  }
}
