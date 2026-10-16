import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
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

  void _mostrarDialogoExportacao() {
    DateTime? dataInicioModal = _dataInicial;
    DateTime? dataFimModal = _dataFinal;
    Set<String> cargosModal = Set.from(_cargosSelecionados);
    Set<String> statusModal = Set.from(_statusSelecionados);
    
    final Set<String> turnosDisponiveis = {'1º Turno', '2º Turno', '3º Turno'};
    final Set<String> turnosSelecionados = {'1º Turno', '2º Turno', '3º Turno'};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            int totalRegistrosPreview = 0;
            for (var chamada in _historicoOriginal) {
              String dataStr = chamada['data'];
              DateTime? dataChamada = DateTime.tryParse(dataStr);
              String turno = chamada['turno'] ?? '';

              if (dataInicioModal != null && dataChamada != null) {
                DateTime inicioSemHoras = DateTime(dataInicioModal!.year, dataInicioModal!.month, dataInicioModal!.day);
                DateTime chamadaSemHoras = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
                if (chamadaSemHoras.isBefore(inicioSemHoras)) continue;
              }

              if (dataFimModal != null && dataChamada != null) {
                DateTime fimSemHoras = DateTime(dataFimModal!.year, dataFimModal!.month, dataFimModal!.day);
                DateTime chamadaSemHoras = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
                if (chamadaSemHoras.isAfter(fimSemHoras)) continue;
              }

              if (!turnosSelecionados.contains(turno)) continue;

              List<dynamic> detalhes = chamada['detalhes'] ?? [];
              var filtrados = detalhes.where((det) {
                String cargo = det['cargo'] ?? '';
                String status = det['status'] ?? '';
                bool passaCargo = cargosModal.isEmpty || cargosModal.contains(cargo);
                bool passaStatus = statusModal.isEmpty || statusModal.contains(status);
                return passaCargo && passaStatus;
              }).toList();

              totalRegistrosPreview += filtrados.length;
            }

            return AlertDialog(
              title: const Text('Exportar Relatorio para Excel'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selecione os parametros para o arquivo XLSX:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      const Text('Periodo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setStateModal(() => dataInicioModal = picked);
                                }
                              },
                              child: Text(dataInicioModal == null ? 'Data Inicial' : _formatarDataPtBr(dataInicioModal!.toIso8601String().split('T')[0])),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setStateModal(() => dataFimModal = picked);
                                }
                              },
                              child: Text(dataFimModal == null ? 'Data Final' : _formatarDataPtBr(dataFimModal!.toIso8601String().split('T')[0])),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text('Turnos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Wrap(
                        spacing: 6,
                        children: turnosDisponiveis.map((turno) {
                          bool sel = turnosSelecionados.contains(turno);
                          return FilterChip(
                            label: Text(turno, style: const TextStyle(fontSize: 11)),
                            selected: sel,
                            onSelected: (val) {
                              setStateModal(() {
                                if (val) {
                                  turnosSelecionados.add(turno);
                                } else {
                                  turnosSelecionados.remove(turno);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('Cargos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Wrap(
                        spacing: 6,
                        children: _cargosDisponiveis.map((cargo) {
                          bool sel = cargosModal.contains(cargo);
                          return FilterChip(
                            label: Text(cargo, style: const TextStyle(fontSize: 11)),
                            selected: sel,
                            onSelected: (val) {
                              setStateModal(() {
                                if (val) {
                                  cargosModal.add(cargo);
                                } else {
                                  cargosModal.remove(cargo);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Wrap(
                        spacing: 6,
                        children: _statusDisponiveis.map((status) {
                          bool sel = statusModal.contains(status);
                          return FilterChip(
                            label: Text(status, style: const TextStyle(fontSize: 10)),
                            selected: sel,
                            onSelected: (val) {
                              setStateModal(() {
                                if (val) {
                                  statusModal.add(status);
                                } else {
                                  statusModal.remove(status);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 24),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B2D82).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6B2D82)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resumo da Exportacao:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B2D82))),
                            const SizedBox(height: 4),
                            Text('Registros selecionados: $totalRegistrosPreview'),
                            Text('Periodo: ${dataInicioModal == null && dataFimModal == null ? "Todos" : "Personalizado"}'),
                            Text('Turnos: ${turnosSelecionados.length == turnosDisponiveis.length ? "Todos" : turnosSelecionados.join(", ")}'),
                            Text('Cargos: ${cargosModal.isEmpty ? "Todos" : "${cargosModal.length} selecionados"}'),
                            Text('Status: ${statusModal.isEmpty ? "Todos" : "${statusModal.length} selecionados"}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B2D82),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: totalRegistrosPreview == 0 ? null : () {
                    Navigator.pop(context);
                    _executarExportacaoFinal(dataInicioModal, dataFimModal, turnosSelecionados, cargosModal, statusModal);
                  },
                  child: const Text('Confirmar e Gerar XLSX'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _executarExportacaoFinal(DateTime? inicio, DateTime? fim, Set<String> turnosSel, Set<String> cargosSel, Set<String> statusSel) {
    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Relatorio_Presenca';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    excel_lib.Sheet sheetObject = excel[sheetName]!;

    List<excel_lib.CellValue> cabecalho = [
      excel_lib.TextCellValue('Data'),
      excel_lib.TextCellValue('Turno'),
      excel_lib.TextCellValue('Colaborador'),
      excel_lib.TextCellValue('Cargo'),
      excel_lib.TextCellValue('Status'),
    ];
    sheetObject.appendRow(cabecalho);

    for (var chamada in _historicoOriginal) {
      String dataStr = chamada['data'];
      DateTime? dataChamada = DateTime.tryParse(dataStr);
      String turno = chamada['turno'] ?? '';

      if (inicio != null && dataChamada != null) {
        DateTime inicioSemH = DateTime(inicio.year, inicio.month, inicio.day);
        DateTime chamadaSemH = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
        if (chamadaSemH.isBefore(inicioSemH)) continue;
      }

      if (fim != null && dataChamada != null) {
        DateTime fimSemH = DateTime(fim.year, fim.month, fim.day);
        DateTime chamadaSemH = DateTime(dataChamada.year, dataChamada.month, dataChamada.day);
        if (chamadaSemH.isAfter(fimSemH)) continue;
      }

      if (!turnosSel.contains(turno)) continue;

      List detalhes = chamada['detalhes'] ?? [];
      for (var det in detalhes) {
        String cargo = det['cargo'] ?? '';
        String status = det['status'] ?? '';

        bool passaCargo = cargosSel.isEmpty || cargosSel.contains(cargo);
        bool passaStatus = statusSel.isEmpty || statusSel.contains(status);

        if (passaCargo && passaStatus) {
          List<excel_lib.CellValue> linha = [
            excel_lib.TextCellValue(_formatarDataPtBr(chamada['data'])),
            excel_lib.TextCellValue(turno),
            excel_lib.TextCellValue(det['nome'] ?? ''),
            excel_lib.TextCellValue(cargo),
            excel_lib.TextCellValue(status),
          ];
          sheetObject.appendRow(linha);
        }
      }
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      String nomeArquivo = 'relatorio_presenca_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      if (kIsWeb) {
        baixarArquivoWeb(fileBytes, nomeArquivo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatorio exportado para Excel com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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
        title: const Text('Relatorios e Historico de Chamadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar para Excel (.xlsx)',
            onPressed: _historicoFiltrado.isEmpty ? null : _mostrarDialogoExportacao,
          ),
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historico Agrupado por Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B2D82),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.table_chart, size: 16),
                  label: const Text('Exportar Excel'),
                  onPressed: _historicoFiltrado.isEmpty ? null : _mostrarDialogoExportacao,
                ),
              ],
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
                                          const Text('Resumo Estatistico do Turno:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                              _badgeEstatistica('F. Nao Justif.', chamada['total_falta_nao_justificada'], Colors.red),
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