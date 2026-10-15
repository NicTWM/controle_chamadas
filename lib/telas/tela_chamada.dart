import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import '../regras/app_controller.dart';

class TelaChamada extends StatefulWidget {
  const TelaChamada({super.key});

  @override
  State<TelaChamada> createState() => _TelaChamadaState();
}

class _TelaChamadaState extends State<TelaChamada> {
  List<Map<String, dynamic>> _turnos = [];
  int? _turnoSelecionadoId;
  List<Map<String, dynamic>> _pessoasDoTurno = [];
  
  // Armazena o status escolhido para cada pessoa (Chave: pessoaId, Valor: String com a opção)
  final Map<int, String> _statusPresenca = {};

  final String _dataHoje = DateTime.now().toIso8601String().split('T')[0];

  final List<String> _opcoesStatus = [
    'PRESENTE',
    'FALTA JUSTIFICADA',
    'FALTA NÃO JUSTIFICADA',
    'FALTA COM ATESTADO',
  ];

  @override
  void initState() {
    super.initState();
    _carregarTurnos();
  }

  void _carregarTurnos() {
    var turnos = ConexaoBanco.consultar('turnos');
    setState(() {
      _turnos = turnos;
      if (_turnos.isNotEmpty) {
        _turnoSelecionadoId = _turnos.first['id'];
        _carregarDadosTurno();
      }
    });
  }

  void _carregarDadosTurno() {
    if (_turnoSelecionadoId == null) return;

    var pessoas = ConexaoBanco.consultarPessoasPorTurno(_turnoSelecionadoId!);
    // Verifica se já existe chamada salva para hoje neste turno
    var statusSalvos = ConexaoBanco.consultarStatusChamadaSalva(_turnoSelecionadoId!, _dataHoje);

    setState(() {
      _pessoasDoTurno = pessoas;
      _statusPresenca.clear();

      for (var p in _pessoasDoTurno) {
        int pId = p['id'];
        // Se já foi salva, recupera; senão, deixa em branco (nenhuma pré-selecionada)
        if (statusSalvos.containsKey(pId)) {
          _statusPresenca[pId] = statusSalvos[pId]!;
        }
      }
    });
  }

  void _concluirChamada() {
    if (_turnoSelecionadoId == null || _pessoasDoTurno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso: Não há colaboradores neste turno para registrar chamada.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Validação: verifica se todos os colaboradores possuem um status selecionado
    for (var p in _pessoasDoTurno) {
      int pId = p['id'];
      if (!_statusPresenca.containsKey(_statusPresenca.containsKey(pId) ? pId : -1) || 
          _statusPresenca[pId] == null || 
          _statusPresenca[pId]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: O colaborador "${p['nome']}" está sem status de chamada definido!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Salva no banco
    ConexaoBanco.salvarChamada(_turnoSelecionadoId!, _dataHoje, _statusPresenca);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamada concluída e salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    // Retorna automaticamente para a página inicial
    Navigator.pop(context);
  }

  Color _obterCorStatus(String? status) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Presença - Grupo Multilixo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data: $_dataHoje',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _turnoSelecionadoId,
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Turno',
                        border: OutlineInputBorder(),
                      ),
                      items: _turnos.map((turno) {
                        return DropdownMenuItem<int>(
                          value: turno['id'],
                          child: Text(turno['nome']),
                        );
                      }).toList(),
                      onChanged: (novoId) {
                        setState(() {
                          _turnoSelecionadoId = novoId;
                          _carregarDadosTurno();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Lista de Colaboradores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _pessoasDoTurno.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum colaborador ativo vinculado a este turno.',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pessoasDoTurno.length,
                      itemBuilder: (context, index) {
                        var pessoa = _pessoasDoTurno[index];
                        int pessoaId = pessoa['id'];
                        String? statusAtual = _statusPresenca[pessoaId];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _obterCorStatus(statusAtual),
                                      child: const Icon(Icons.person, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pessoa['nome'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text('Cargo: ${pessoa['cargo']}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                const Text('Selecione o Status:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                const SizedBox(height: 6),
                                // Opções de rádio ou chips para as 4 opções exatas
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: _opcoesStatus.map((opcao) {
                                    bool selecionado = statusAtual == opcao;
                                    return ChoiceChip(
                                      label: Text(opcao, style: const TextStyle(fontSize: 12)),
                                      selected: selecionado,
                                      selectedColor: _obterCorStatus(opcao).withOpacity(0.3),
                                      labelStyle: TextStyle(
                                        color: selecionado ? _obterCorStatus(opcao) : (isDark ? Colors.white70 : Colors.black87),
                                        fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            _statusPresenca[pessoaId] = opcao;
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Botão CONCLUIR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C18), // Laranja Multilixo
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _concluirChamada,
                child: const Text('CONCLUIR CHAMADA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}