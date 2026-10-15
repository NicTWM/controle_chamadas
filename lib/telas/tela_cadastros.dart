import 'package:flutter/material.dart';
import '../banco/conexao_banco.dart';
import '../regras/app_controller.dart';

class TelaCadastros extends StatefulWidget {
  const TelaCadastros({super.key});

  @override
  State<TelaCadastros> createState() => _TelaCadastrosState();
}

class _TelaCadastrosState extends State<TelaCadastros> {
  final _nomeController = TextEditingController();
  final _cargoController = TextEditingController();

  final Map<int, bool> _turnosSelecionados = {};
  final List<int> _turnosFiltroIds = []; // Filtro múltiplo de turnos
  int? _idEdicaoEmAndamento;

  List<Map<String, dynamic>> _pessoas = [];
  List<Map<String, dynamic>> _turnos = [];

  @override
  void initState() {
    super.initState();
    _atualizarDados();
  }

  void _atualizarDados() {
    setState(() {
      _turnos = ConexaoBanco.consultar('turnos');
      _pessoas = ConexaoBanco.consultarPessoasPorTurnosFiltro(_turnosFiltroIds);
      
      for (var turno in _turnos) {
        _turnosSelecionados.putIfAbsent(turno['id'], () => false);
      }
    });
  }

  void _limparFormulario() {
    _nomeController.clear();
    _cargoController.clear();
    setState(() {
      _idEdicaoEmAndamento = null;
      _turnosSelecionados.updateAll((key, value) => false);
    });
  }

  void _concluirCadastro() {
    if (_nomeController.text.trim().isEmpty || _cargoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Preencha o nome e o cargo do colaborador!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<int> turnosEscolhidos = _turnosSelecionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (turnosEscolhidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Selecione pelo menos um turno de atuação!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_idEdicaoEmAndamento == null) {
      ConexaoBanco.adicionarPessoaComTurnos(
        _nomeController.text.trim(),
        _cargoController.text.trim(),
        turnosEscolhidos,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colaborador cadastrado com sucesso!'), backgroundColor: Colors.green),
      );
    } else {
      ConexaoBanco.atualizarPessoa(
        _idEdicaoEmAndamento!,
        _nomeController.text.trim(),
        _cargoController.text.trim(),
        turnosEscolhidos,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro atualizado com sucesso!'), backgroundColor: Colors.green),
      );
    }

    // Retorna automaticamente à página inicial
    Navigator.pop(context);
  }

  void _carregarParaEdicao(Map<String, dynamic> pessoa) {
    setState(() {
      _idEdicaoEmAndamento = pessoa['id'];
      _nomeController.text = pessoa['nome'];
      _cargoController.text = pessoa['cargo'];

      List<int> turnosDaPessoa = List<int>.from(pessoa['turnos_ids'] ?? []);
      for (var turno in _turnos) {
        _turnosSelecionados[turno['id']] = turnosDaPessoa.contains(turno['id']);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando cadastro de: ${pessoa['nome']}')),
    );
  }

  void _confirmarExclusao(Map<String, dynamic> pessoa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente inativar o cadastro de ${pessoa['nome']}? O histórico será preservado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ConexaoBanco.excluirPessoaLogica(pessoa['id']);
              Navigator.pop(ctx);
              _atualizarDados();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cadastro inativado com sucesso!')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppController.instance.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Presença - Grupo Multilixo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário de Cadastro / Edição
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _idEdicaoEmAndamento == null
                              ? 'Cadastrar Nova Pessoa'
                              : 'Editando Colaborador (ID: $_idEdicaoEmAndamento)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_idEdicaoEmAndamento != null)
                          TextButton(
                            onPressed: _limparFormulario,
                            child: const Text('Cancelar Edição', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cargoController,
                      decoration: const InputDecoration(
                        labelText: 'Cargo / Função',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Turnos de Atuação (Selecione um ou mais):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._turnos.map((turno) {
                      int turnoId = turno['id'];
                      return CheckboxListTile(
                        title: Text(turno['nome']),
                        value: _turnosSelecionados[turnoId] ?? false,
                        activeColor: const Color(0xFF6B2D82),
                        onChanged: (bool? valor) {
                          setState(() {
                            _turnosSelecionados[turnoId] = valor ?? false;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF28C18), // Laranja Multilixo
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _concluirCadastro,
                        child: Text(
                          _idEdicaoEmAndamento == null ? 'CONCLUIR CADASTRO' : 'CONCLUIR ATUALIZAÇÃO',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filtro por Turno Múltiplo
            Card(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrar Colaboradores por Turno:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8.0,
                      children: _turnos.map((turno) {
                        int tId = turno['id'];
                        bool selecionado = _turnosFiltroIds.contains(tId);
                        return FilterChip(
                          label: Text(turno['nome']),
                          selected: selecionado,
                          selectedColor: const Color(0xFF6B2D82).withOpacity(0.3),
                          checkmarkColor: const Color(0xFF6B2D82),
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                _turnosFiltroIds.add(tId);
                              } else {
                                _turnosFiltroIds.remove(tId);
                              }
                              _atualizarDados();
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
              'Colaboradores Cadastrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pessoas.length,
              itemBuilder: (context, index) {
                var pessoa = _pessoas[index];
                // Exibe explicitamente os turnos vinculados formatados
                String turnosAtuais = pessoa['turno_nome'] ?? 'Nenhum Turno';

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF6B2D82),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      pessoa['nome'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Cargo: ${pessoa['cargo']}\nTurnos: $turnosAtuais'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFF28C18)),
                          tooltip: 'Editar',
                          onPressed: () => _carregarParaEdicao(pessoa),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Excluir / Inativar',
                          onPressed: () => _confirmarExclusao(pessoa),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}