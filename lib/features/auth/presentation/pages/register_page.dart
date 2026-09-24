import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _userType = 'Alumno';
  String _modality = 'Servicio Social';
  String _gender = 'Femenino';
  bool _speaksEnglish = false;
  double _gpa = 8.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _register() async {
    // CORRECCIÓN: Usamos AppAuthProvider para evitar conflicto con Firebase
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Map<String, dynamic> extraData = {};
    if (_userType == 'Alumno') {
      extraData = {
        'modality': _modality,
        'gender': _gender,
        'speaksEnglish': _speaksEnglish,
        'gpa': _gpa,
        'career': 'Ingeniería en Sistemas Computacionales',
      };
    }

    final error = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      type: _userType.toLowerCase(),
      extraData: extraData,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Únete a RedTESO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Alumno', label: Text('Alumno'), icon: Icon(Icons.school)),
                ButtonSegment(value: 'Empresa', label: Text('Empresa'), icon: Icon(Icons.business)),
              ],
              selected: {_userType},
              onSelectionChanged: (val) => setState(() => _userType = val.first),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Institucional', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
            ),

            if (_userType == 'Alumno') ...[
              const SizedBox(height: 32),
              const Divider(),
              const Text('Información Académica (Sistemas)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _modality,
                decoration: const InputDecoration(labelText: 'Estado / Modalidad'),
                items: ['Servicio Social', 'Residencias', 'Recién Egresado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _modality = val!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Género: '),
                  Radio<String>(
                    value: 'Femenino',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                  const Text('Fem'),
                  Radio<String>(
                    value: 'Masculino',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                  const Text('Mas'),
                ],
              ),
              
              SwitchListTile(
                title: const Text('¿Hablas Inglés?'),
                value: _speaksEnglish,
                onChanged: (val) => setState(() => _speaksEnglish = val),
                activeColor: AppTheme.primaryGreen,
              ),

              const Text('Promedio (GPA)'),
              Slider(
                value: _gpa,
                min: 6.0,
                max: 10.0,
                divisions: 40,
                label: _gpa.toStringAsFixed(1),
                onChanged: (val) => setState(() => _gpa = val),
              ),
            ],

            const SizedBox(height: 40),
            // CORRECCIÓN: Consumer de AppAuthProvider
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('FINALIZAR REGISTRO'),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
