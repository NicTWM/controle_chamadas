import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import '../regras/app_controller.dart';
import 'tela_cadastros.dart';
import 'tela_chamada.dart';
import 'tela_relatorios.dart';
import 'tela_login.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = ConexaoBanco.usuarioLogado;
  }

  void _fazerLogout() {
    ConexaoBanco.fazerLogout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;
    bool isAdmin = _usuario != null && _usuario!['perfil'] == 'ADMINISTRADOR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Presença - Grupo Multilixo'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              setState(() {
                AppController.instance.alternarTema();
              });
            },
            tooltip: 'Alternar Tema',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _fazerLogout,
            tooltip: 'Terminar Sessão (Logout)',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 80,
                color: isDark ? const Color(0xFF9C49BD) : const Color(0xFF6B2D82),
              ),
              const SizedBox(height: 20),
              const Text(
                'Painel de Controle Principal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Utilizador: ${_usuario?['usuario'] ?? 'Convidado'} (${_usuario?['perfil'] ?? 'N/A'})',
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 30),

              // Botão de Gerenciar Pessoas: Exclusivo para ADMINISTRADOR
              if (isAdmin) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B2D82),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  icon: const Icon(Icons.people),
                  label: const Text('Gerenciar Pessoas e Turnos (Admin)', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TelaCadastros()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Botão de Realizar Chamada: Disponível para ADMIN e RESPONSÁVEL
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C18),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Registrar Chamada / Presença', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaChamada()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Botão de Relatórios: Disponível para ADMIN e RESPONSÁVEL
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B2D82),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Relatórios e Histórico', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaRelatorios()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}