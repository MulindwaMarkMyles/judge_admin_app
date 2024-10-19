import 'package:judge_admin_app/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judge_admin_app/homescreen.dart';
import 'package:judge_admin_app/auth_models.dart'; 

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  String getUsernameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@').first;
    } else {
      throw const FormatException("Invalid email format");
    }
  }

  // Function to handle sign-in logic
  void _validateAndSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String username = getUsernameFromEmail(email);

      // Call the modified signIn function from AuthService
      String? result = await AuthService().signIn(email, password);

      setState(() {
        _isLoading = false;
      });

      if (result == null) {
        // Navigate to Homescreen if login is successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Homescreen(username: username),
          ),
        );
      } else {
        // Display error message for failed login
        setState(() {
          _errorMessage = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Design
          _buildBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sign-In Title
                  Text(
                    "SIGN IN",
                    style: GoogleFonts.poppins(
                      fontSize: 40.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 40.0),

                  // Email TextField
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    isPassword: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Password TextField
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30.0),

                  // Error Message Display
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16.0),
                    ),
                    const SizedBox(height: 10.0),
                  ],

                  // Sign-In Button
                  _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.amber))
                      : ElevatedButton(
                          onPressed: _validateAndSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50.0, vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: Colors.black38,
                            elevation: 5,
                          ),
                          child: Text(
                            'SIGN IN',
                            style: GoogleFonts.poppins(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                  const SizedBox(height: 20.0),

                  // Sign-Up Link
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Don't have an account? Sign up here.",
                      style: GoogleFonts.poppins(
                        fontSize: 16.0,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Background design method
  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.1),
                Colors.amberAccent.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -50,
          left: -50,
          child: _buildCircle(200, Colors.amber.withOpacity(0.3)),
        ),
        Positioned(
          bottom: -60,
          right: -40,
          child: _buildCircle(300, Colors.amberAccent.withOpacity(0.2)),
        ),
      ],
    );
  }

  // Circle design method
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // Custom TextField widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required bool isPassword,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? !_passwordVisible : false,
          style: GoogleFonts.poppins(
            fontSize: 20.0,
            color: Colors.grey[600],
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.amber),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  )
                : null,
          ),
          validator: validator,
        ),
      ),
    );
  }
}
