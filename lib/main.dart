// Copyright 2021, Techaas.com. All rights reserved.
//
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:http/http.dart' as http;

// JWTトークンのアクセス検証サーバに変更してください
final url = Uri.parse('https://xxxxxx.appspot.com/');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInOutPage(title: 'Firebase Authentication'),
    );
  }
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignInOutPage extends StatefulWidget {
  SignInOutPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _SignInOutPageState createState() => _SignInOutPageState();
}

class _SignInOutPageState extends State<SignInOutPage> {
  User? user;

  @override
  void initState() {
    _auth.userChanges().listen((event) {
      debugPrint('user: $event');
      setState(() => user = event);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 100),
        alignment: Alignment.center,
        child: (user == null) ? _EmailPasswordForm() : _UserInfoCard(user),
      ),
    );
  }
}

class _EmailPasswordForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<_EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'ユーザー名とパスワードを入力してください',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (String? value) {
                    if (value != null && value.isEmpty) return 'テキストを入力してください';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (String? value) {
                    if (value != null && value.isEmpty) return 'テキストを入力してください';
                    return null;
                  },
                  obscureText: true,
                ),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  alignment: Alignment.center,
                  child: SignInButton(
                    Buttons.Email,
                    text: 'ログイン',
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _signInWithEmailAndPassword();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user?.email} でログインしました'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ユーザー名かパスワードが違います'),
        ),
      );
    }
  }
}

class _UserInfoCard extends StatefulWidget {
  final User? user;

  const _UserInfoCard(this.user);

  @override
  _UserInfoCardState createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<_UserInfoCard> {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
      Text((widget.user == null)
          ? 'Not signed in'
          : '${widget.user!.isAnonymous ? '匿名ユーザ\n\n' : ''}'
              'Email: ${widget.user!.email} (verified: ${widget.user!.emailVerified})\n\n'),
      SizedBox(
        width: 150,
        child: ElevatedButton(
            child: const Text('Check Token'),
            style: ElevatedButton.styleFrom(
              primary: Colors.green,
            ),
            onPressed: () async {
              await _checkToken();
            }),
      ),
      SizedBox(height: 20),
      SizedBox(
        width: 150,
        child: ElevatedButton(
            child: const Text('Logout'),
            onPressed: () async {
              await _signOut();
            }),
      ),
    ]);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ログアウトしました'),
      ),
    );
  }

  Future<void> _checkToken() async {
    String? token = await widget.user?.getIdToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('トークンが取得できませんでした'),
        ),
      );
      return;
    }
    debugPrint('token: $token');

    var response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('トークンが正しく検証されました'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('検証に失敗しました'),
        ),
      );
    }
  }
}
