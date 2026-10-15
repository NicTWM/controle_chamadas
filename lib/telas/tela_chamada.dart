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
  String _dataSelecionada = DateTime.now().toIso8601String().split('T')[0];
  
  List<Map<String, dynamic>> _pessoasDoTurno = [];
  final Map<int, String> _statusPresenca = {};
  bool _chamadaCarregada = false;

  @override
  void initState() {
    super.initState();
    _carregarTurnos();
  }

  void _carregarTurnos() {
    setState(() {
      _turnos = ConexaoBanco.consultar('turnos');
      if (_turnos.isNotEmpty) {
        _turnoSelecionadoId = _turnos[0]['id'];
        _carregarPessoasEStatus();
      }
    });
  }

  void _carregarPessoasEStatus() {
    if (_turnoSelecionadoId == null) return;

    setState(() {
      _pessoasDoTurno = ConexaoBanco.consultarPessoasPorTurno(_turnoSelecionadoId!);
      
      // Consulta se já existe chamada salva para este turno e data
      Map<int, String> statusSalvos = ConexaoBanco.consultarStatusChamadaSalva(
        _turnoSelecionadoId!, 
        _dataSelecionada,
      );

      _statusPresenca.clear();
      for (var pessoa in _pessoasDoTurno) {
        int pessoaId = pessoa['id'];
        // Se já houver salvo, carrega o status. Caso contrário, deixa em branco (sem pré-seleção)
        if (statusSalvos.containsKey(pessoaId)) {
          _statusPresenca[pessoaId] = statusSalvos[pessoaId]!;
        }
      }
      _chamadaCarregada = true;
    });
  }

  Future<void> _selecionarData(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_dataSelecionada),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked.toIso8601String().split('T')[0];
        _carregarPessoasEStatus();
      });
    }
  }

  void _atualizarStatus(int pessoaId, String status) {
    setState(() {
      _statusPresenca[pessoaId] = status;
    });
  }

  void _salvarChamada() {
    if (_turnoSelecionadoId == null) return;

    if (_statusPresenca.length < _pessoasDoTurno.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atenção: Existem colaboradores sem status de presença definido!'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    ConexaoBanco.salvarChamada(_turnoSelecionadoId!, _dataSelecionada, _statusPresenca);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamada salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;

    // Cálculo da Barra de Progresso
    int totalColaboradores = _pessoasDoTurno.length;
    int respondidos = _statusPresenca.values.where((s) => s.isNotEmpty).length;
    double progresso = totalColaboradores > 0 ? (respondidos / totalColaboradores) : 0.0;
    int percentual = (progresso * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Chamada / Presença'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros de Turno e Data
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Turno:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _turnoSelecionadoId,
                              isExpanded: true,
                              items: _turnos.map((turno) {
                                return DropdownMenuItem<int>(
                                  value: turno['id'],
                                  child: Text(turno['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (int? novoId) {
                                setState(() {
                                  _turnoSelecionadoId = novoId;
                                  _carregarPessoasEStatus();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Data: $_dataSelecionada', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B2D82),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Alterar Data'),
                          onPressed: () => _selecionarData(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // BARRA DE PROGRESSO DINÂMICA
            Card(
              elevation: 2,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progresso da Chamada:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$respondidos / $totalColaboradores respondidos ($percentual%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: percentual == 100 ? Colors.green : const Color(0xFF6B2D82),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentual == 100 ? Colors.green : const Color(0xFFF28C18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Lista de Colaboradores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Lista de Pessoas para Marcação
            Expanded(
              child: !_chamadaCarregada || _pessoasDoTurno.isEmpty
                  ? Center(
                      child: Text(
                        _pessoasDoTurno.isEmpty
                            ? 'Nenhum colaborador vinculado a este turno.'
                            : 'A carregar...',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pessoasDoTurno.length,
                      itemBuilder: (context, index) {
                        var pessoa = _pessoasDoTurno[index];
                        int pessoaId = pessoa['id'];
                        String statusAtual = _statusPresenca[pessoaId] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pessoa['nome'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Cargo: ${pessoa['cargo']}',
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: [
                                    _botaoStatus(pessoaId, 'PRESENTE', Colors.green, statusAtual),
                                    _botaoStatus(pessoaId, 'FALTA JUSTIFICADA', Colors.blue, statusAtual),
                                    _botaoStatus(pessoaId, 'FALTA NÃO JUSTIFICADA', Colors.red, statusAtual),
                                    _botaoStatus(pessoaId, 'FALTA COM ATESTADO', Colors.orange, statusAtual),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),

            // Botão Finalizar Chamada
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C18), // Laranja Multilixo
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _salvarChamada,
                child: const Text(
                  'FINALIZAR E SALVAR CHAMADA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoStatus(int pessoaId, String statusTexto, Color cor, String statusAtual) {
    bool selecionado = statusAtual == statusTexto;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionado ? cor : Colors.transparent,
        foregroundColor: selecionado ? Colors.white : cor,
        side: BorderSide(color: cor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
      onPressed: () => _atualizarStatus(pessoaId, statusTexto),
      child: Text(
        statusTexto,
        style: TextStyle(fontSize: 11, fontWeight: selecionado ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}