import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import 'tela_inicial.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _inicializarBanco();
  }

  Future<void> _inicializarBanco() async {
    await ConexaoBanco.inicializar();
  }

  void _fazerLogin() {
    String usuario = _usuarioController.text.trim();
    String senha = _senhaController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o usuário e a senha!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _carregando = true);

    bool sucesso = ConexaoBanco.fazerLogin(usuario, senha);

    setState(() => _carregando = false);

    if (sucesso) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaInicial()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciais inválidas ou usuário inativo!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_person, size: 64, color: Color(0xFF6B2D82)),
                    const SizedBox(height: 16),
                    const Text(
                      'Controle de Presença\nGrupo Multilixo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usuarioController,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B2D82),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _carregando ? null : _fazerLogin,
                      child: _carregando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}