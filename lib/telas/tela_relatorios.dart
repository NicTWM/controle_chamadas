import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import '../regras/app_controller.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  List<Map<String, dynamic>> _historico = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  void _carregarHistorico() {
    setState(() {
      _historico = ConexaoBanco.consultarHistoricoChamadas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Histórico de Chamadas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico Geral de Presenças',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _historico.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma chamada registrada até o momento.',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historico.length,
                      itemBuilder: (context, index) {
                        var chamada = _historico[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6B2D82),
                              child: Icon(Icons.assignment, color: Colors.white),
                            ),
                            title: Text(
                              'Turno: ${chamada['turno']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('Data: ${chamada['data']} | Registos: ${chamada['detalhes'].length}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Resumo Estatístico:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _badgeEstatistica('Presentes', chamada['total_presentes'], Colors.green),
                                        _badgeEstatistica('F. Justificada', chamada['total_falta_justificada'], Colors.blue),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _badgeEstatistica('F. Não Justif.', chamada['total_falta_nao_justificada'], Colors.red),
                                        _badgeEstatistica('Atestado', chamada['total_falta_atestado'], Colors.orange),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    const Text('Detalhes por Colaborador:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...List.generate(chamada['detalhes'].length, (i) {
                                      var det = chamada['detalhes'][i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(det['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('Cargo: ${det['cargo']}'),
                                        trailing: Chip(
                                          label: Text(det['status'], style: const TextStyle(fontSize: 10, color: Colors.white)),
                                          backgroundColor: _obterCorStatus(det['status']),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeEstatistica(String titulo, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor),
      ),
      child: Column(
        children: [
          Text('$valor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cor)),
          Text(titulo, style: TextStyle(fontSize: 11, color: cor)),
        ],
      ),
    );
  }

  Color _obterCorStatus(String status) {
    switch (status) {
      case 'PRESENTE':
        return Colors.green;
      case 'FALTA JUSTIFICADA':
        return Colors.blue;
      case 'FALTA NÃO JUSTIFICADA':
        return Colors.red;
      case 'FALTA COM ATESTADO':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}