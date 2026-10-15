import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import '../regras/app_controller.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  List<Map<String, dynamic>> _historicoOriginal = [];
  List<Map<String, dynamic>> _historicoFiltrado = [];

  DateTime? _dataInicial;
  DateTime? _dataFinal;
  
  final Set<String> _cargosDisponiveis = {};
  final Set<String> _cargosSelecionados = {};

  final List<String> _statusDisponiveis = [
    'PRESENTE',
    'FALTA JUSTIFICADA',
    'FALTA NÃO JUSTIFICADA',
    'FALTA COM ATESTADO'
  ];
  final Set<String> _statusSelecionados = {};

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  void _carregarHistorico() {
    var dados = ConexaoBanco.consultarHistoricoChamadas();
    
    _cargosDisponiveis.clear();
    for (var chamada in dados) {
      for (var det in (chamada['detalhes'] as List)) {
        if (det['cargo'] != null) {
          _cargosDisponiveis.add(det['cargo'].toString());
        }
      }
    }

    setState(() {
      _historicoOriginal = dados;
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = [];

    for (var chamada in _historicoOriginal) {
      String dataStr = chamada['data'];
      DateTime? dataChamada = DateTime.tryParse(dataStr);

      if (_dataInicial != null && dataChamada != null) {
        DateTime inicioSemHoras = DateTime(_dataInicial!.year, _dataInicial!.month, _dataInicial!.day);
        DateTime chamadaSemHoras = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
        if (chamadaSemHoras.isBefore(inicioSemHoras)) continue;
      }

      if (_dataFinal != null && dataChamada != null) {
        DateTime fimSemHoras = DateTime(_dataFinal!.year, _dataFinal!.month, _dataFinal!.day);
        DateTime chamadaSemHoras = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
        if (chamadaSemHoras.isAfter(fimSemHoras)) continue;
      }

      List<dynamic> detalhes = chamada['detalhes'] ?? [];
      List<dynamic> detalhesFiltrados = detalhes.where((det) {
        String cargo = det['cargo'] ?? '';
        String status = det['status'] ?? '';

        bool passaCargo = _cargosSelecionados.isEmpty || _cargosSelecionados.contains(cargo);
        bool passaStatus = _statusSelecionados.isEmpty || _statusSelecionados.contains(status);

        return passaCargo && passaStatus;
      }).toList();

      if (detalhesFiltrados.isNotEmpty) {
        int presentes = detalhesFiltrados.where((i) => i['status'] == 'PRESENTE').length;
        int faltaJustificada = detalhesFiltrados.where((i) => i['status'] == 'FALTA JUSTIFICADA').length;
        int faltaNaoJustificada = detalhesFiltrados.where((i) => i['status'] == 'FALTA NÃO JUSTIFICADA').length;
        int faltaAtestado = detalhesFiltrados.where((i) => i['status'] == 'FALTA COM ATESTADO').length;

        Map<String, dynamic> chamadaFiltrada = {
          ...chamada,
          'total_presentes': presentes,
          'total_falta_justificada': faltaJustificada,
          'total_falta_nao_justificada': faltaNaoJustificada,
          'total_falta_atestado': faltaAtestado,
          'detalhes': detalhesFiltrados,
        };
        resultado.add(chamadaFiltrada);
      }
    }

    setState(() {
      _historicoFiltrado = resultado;
    });
  }

  void _limparFiltros() {
    setState(() {
      _dataInicial = null;
      _dataFinal = null;
      _cargosSelecionados.clear();
      _statusSelecionados.clear();
      _aplicarFiltros();
    });
  }

  Future<void> _selecionarPeriodo(BuildContext context, bool isInicial) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isInicial) {
          _dataInicial = picked;
        } else {
          _dataFinal = picked;
        }
        _aplicarFiltros();
      });
    }
  }

  String _formatarDataPtBr(String dataIso) {
    try {
      var partes = dataIso.split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}
    return dataIso;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;

    Map<String, List<Map<String, dynamic>>> historicoAgrupadoPorData = {};
    for (var chamada in _historicoFiltrado) {
      String data = chamada['data'];
      historicoAgrupadoPorData.putIfAbsent(data, () => []);
      historicoAgrupadoPorData[data]!.add(chamada);
    }

    var datasOrdenadas = historicoAgrupadoPorData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Histórico de Chamadas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Combinados (Data, Cargo, Status)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton.icon(
                        onPressed: _limparFiltros,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Limpar Filtros', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(_dataInicial == null ? 'Data Inicial' : _formatarDataPtBr(_dataInicial!.toIso8601String().split('T')[0])),
                            onPressed: () => _selecionarPeriodo(context, true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(_dataFinal == null ? 'Data Final' : _formatarDataPtBr(_dataFinal!.toIso8601String().split('T')[0])),
                            onPressed: () => _selecionarPeriodo(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Filtrar por Cargo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6.0,
                      children: _cargosDisponiveis.map((cargo) {
                        bool selecionado = _cargosSelecionados.contains(cargo);
                        return FilterChip(
                          label: Text(cargo, style: const TextStyle(fontSize: 12)),
                          selected: selecionado,
                          selectedColor: const Color(0xFF6B2D82).withOpacity(0.3),
                          checkmarkColor: const Color(0xFF6B2D82),
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                _cargosSelecionados.add(cargo);
                              } else {
                                _cargosSelecionados.remove(cargo);
                              }
                              _aplicarFiltros();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Filtrar por Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6.0,
                      children: _statusDisponiveis.map((status) {
                        bool selecionado = _statusSelecionados.contains(status);
                        return FilterChip(
                          label: Text(status, style: const TextStyle(fontSize: 11)),
                          selected: selecionado,
                          selectedColor: const Color(0xFFF28C18).withOpacity(0.3),
                          checkmarkColor: const Color(0xFFF28C18),
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                _statusSelecionados.add(status);
                              } else {
                                _statusSelecionados.remove(status);
                              }
                              _aplicarFiltros();
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Histórico Agrupado por Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: datasOrdenadas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum registro encontrado com os filtros aplicados.',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: datasOrdenadas.length,
                      itemBuilder: (context, index) {
                        String dataIso = datasOrdenadas[index];
                        String dataFormatada = _formatarDataPtBr(dataIso);
                        List<Map<String, dynamic>> turnosDoDia = historicoAgrupadoPorData[dataIso]!;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6B2D82),
                              child: Icon(Icons.date_range, color: Colors.white),
                            ),
                            title: Text(
                              'Data: $dataFormatada',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text('Turnos registrados neste dia: ${turnosDoDia.length}'),
                            children: turnosDoDia.map((chamada) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.access_time, color: Color(0xFFF28C18)),
                                  title: Text(
                                    'Turno: ${chamada['turno']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Text('Registros filtrados: ${chamada['detalhes'].length} colaboradores'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Resumo Estatístico do Turno:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            }).toList(),
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