import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDepartment = 'Engineering';
  UserRole _selectedRole = UserRole.employee;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _departments = [
    'Engineering',
    'Human Resources',
    'Sales & Marketing',
    'Operations & Logistics',
    'Finance & Accounting',
    'Product & Design',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please check again.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final regEmail = _emailController.text.trim();
    final auth = context.read<AuthProvider>();
    final success = await auth.registerAccount(
      name: _nameController.text.trim(),
      email: regEmail,
      password: _passwordController.text,
      department: _selectedDepartment,
      role: _selectedRole,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Created Successfully! Please Sign In with your credentials. 🎉'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(prefilledEmail: regEmail)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBF4FA), Color(0xFFD6E8F9)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative top-left curved blob
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Background branding texts
            Positioned(
              top: 70,
              left: 60,
              child: Text(
                'Work\nBuild\nBelong',
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ),
            Positioned(
              top: 70,
              right: 20,
              child: Text(
                'People\nAttendance\nProgress\nTogether',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: 44,
              left: 12,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top Logo Section matching Login Screen
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Transform.scale(
                            scale: 3.3,
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envision Beyond India Pvt Ltd',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Smart Attendance & Workforce System',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Form Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Account 🚀',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter details to register as a new team member',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Full Name
                              Text(
                                'FULL NAME *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Aman Sharma',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              Text(
                                'EMAIL ADDRESS *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'e.g. aman@company.com',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email address is required';
                                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Department
                              Text(
                                'DEPARTMENT *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedDepartment,
                                isExpanded: true,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF2563EB), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                items: _departments
                                    .map((dept) => DropdownMenuItem(
                                          value: dept,
                                          child: Text(dept, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedDepartment = val);
                                },
                              ),
                              const SizedBox(height: 14),

                              // Role
                              Text(
                                'ACCOUNT ROLE *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<UserRole>(
                                initialValue: _selectedRole,
                                isExpanded: true,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: UserRole.employee,
                                    child: Text('Employee (Staff Member)'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserRole.manager,
                                    child: Text('Team Lead / Manager'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserRole.hr,
                                    child: Text('HR Specialist'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                              const SizedBox(height: 14),

                              // Password
                              Text(
                                'PASSWORD *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Minimum 6 characters',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Password is required';
                                  if (v.trim().length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Confirm Password
                              Text(
                                'CONFIRM PASSWORD *',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Re-enter your password',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF2563EB), size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              if (auth.errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          auth.errorMessage!,
                                          style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.danger),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Submit Button
                              ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : Text(
                                        'CREATE ACCOUNT & SIGN IN 🚀',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 20),

                              // Link to Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
