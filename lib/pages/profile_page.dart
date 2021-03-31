import 'package:firebase_auth_flow/providers/auth_provider.dart';
import 'package:firebase_auth_flow/providers/profile_provider.dart';
import 'package:firebase_auth_flow/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;

class ProfilePage extends StatefulWidget {
  static const String routeName = 'profile-page';

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String userId, _name;
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  TextEditingController _emailController, _nameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<firebaseAuth.User>();
      userId = user.uid;

      try {
        await context.read<ProfileProvider>().getUserProfile(userId);
      } catch (e) {
        errorDialog(context, e);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      autovalidateMode = AutovalidateMode.always;
    });
    if (!_formKey.currentState.validate()) return;
    _formKey.currentState.save();

    try {
      await context.read<ProfileProvider>().editUserProfile(
            userId,
            _name,
            _emailController.text,
          );
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Successfully updated'),
          );
        },
      );
    } catch (e) {
      errorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().state;

    if (profile.user != null) {
      _emailController.text = profile.user.email;
      _nameController.text = profile.user.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Form(
            key: _formKey,
            autovalidateMode: autovalidateMode,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    30.0,
                    50.0,
                    30.0,
                    10.0,
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      labelText: 'Email',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 10.0,
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      labelText: 'Name',
                    ),
                    validator: (val) =>
                        val.trim().isEmpty ? 'Name required' : null,
                    onSaved: (val) => _name = val,
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
