import 'dart:convert';
import 'package:crypto/crypto.dart';

class ConexaoBanco {
  static final Map<String, List<Map<String, dynamic>>> _tabelas = {
    'usuarios': [
      {
        'id': 1,
        'usuario': 'ADMIN',
        'senha_hash': '', // Preenchido na inicialização
        'perfil': 'ADMINISTRADOR',
        'ativo': 1,
      },
      {
        'id': 2,
        'usuario': 'CHAMADA',
        'senha_hash': '', // Preenchido na inicialização
        'perfil': 'RESPONSAVEL_CHAMADA',
        'ativo': 1,
      },
    ],
    'pessoas': [
      {'id': 1, 'nome': 'João Silva', 'cargo': 'Operador', 'ativo': 1},
      {'id': 2, 'nome': 'Maria Souza', 'cargo': 'Supervisora', 'ativo': 1},
    ],
    'turnos': [
      {'id': 1, 'nome': '1º Turno'},
      {'id': 2, 'nome': '2º Turno'},
      {'id': 3, 'nome': '3º Turno'},
    ],
    'pessoa_turno': [
      {'id': 1, 'pessoa_id': 1, 'turno_id': 1, 'data': '2026-10-14'},
      {'id': 2, 'pessoa_id': 1, 'turno_id': 2, 'data': '2026-10-14'},
      {'id': 3, 'pessoa_id': 2, 'turno_id': 2, 'data': '2026-10-14'},
    ],
    'chamadas': [],
    'itens_chamada': [],
    'auditoria': [],
  };

  static bool _inicializado = false;
  static Map<String, dynamic>? _usuarioLogado;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    var usuarios = _tabelas['usuarios']!;
    for (var u in usuarios) {
      String senhaPadrao = u['usuario'] == 'ADMIN' ? 'MultLix44' : 'Check88';
      var bytes = utf8.encode(senhaPadrao);
      u['senha_hash'] = sha256.convert(bytes).toString();
    }
    _inicializado = true;
  }

  // Gestão de Sessão
  static Map<String, dynamic>? get usuarioLogado => _usuarioLogado;

  static bool fazerLogin(String usuario, String senha) {
    var bytes = utf8.encode(senha);
    String senhaHash = sha256.convert(bytes).toString();

    var match = _tabelas['usuarios']!.firstWhere(
      (u) => u['usuario'].toString().toUpperCase() == usuario.toUpperCase() && 
             u['senha_hash'] == senhaHash && 
             u['ativo'] == 1,
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      _usuarioLogado = match;
      return true;
    }
    return false;
  }

  static void fazerLogout() {
    _usuarioLogado = null;
  }

  static List<Map<String, dynamic>> consultar(String tabela) {
    return _tabelas[tabela] ?? [];
  }

  static List<Map<String, dynamic>> consultarPessoasComTurnos() {
    var pessoas = _tabelas['pessoas']!.where((p) => p['ativo'] == 1).toList();
    var vinculos = _tabelas['pessoa_turno']!;
    var turnos = _tabelas['turnos']!;

    return pessoas.map((pessoa) {
      var turnosDaPessoa = vinculos
          .where((v) => v['pessoa_id'] == pessoa['id'])
          .map((v) => v['turno_id'])
          .toList();

      var nomesTurnos = turnos
          .where((t) => turnosDaPessoa.contains(t['id']))
          .map((t) => t['nome'].toString())
          .toList();

      String textoTurnos = nomesTurnos.isNotEmpty ? nomesTurnos.join(', ') : 'Nenhum Turno';

      return {
        ...pessoa,
        'turnos_ids': turnosDaPessoa,
        'turno_nome': textoTurnos,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> consultarPessoasPorTurnosFiltro(List<int> turnosFiltroIds) {
    var todas = consultarPessoasComTurnos();
    if (turnosFiltroIds.isEmpty) return todas;

    return todas.where((pessoa) {
      List<int> idsPessoa = List<int>.from(pessoa['turnos_ids'] ?? []);
      return idsPessoa.any((tId) => turnosFiltroIds.contains(tId));
    }).toList();
  }

  static List<Map<String, dynamic>> consultarPessoasPorTurno(int turnoId) {
    var pessoasComTurnos = consultarPessoasComTurnos();
    return pessoasComTurnos.where((p) {
      List<int> ids = List<int>.from(p['turnos_ids'] ?? []);
      return ids.contains(turnoId);
    }).toList();
  }

  static void adicionarPessoaComTurnos(String nome, String cargo, List<int> turnosIds) {
    var pessoas = _tabelas['pessoas']!;
    int novoIdPessoa = pessoas.isNotEmpty ? pessoas.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1 : 1;

    pessoas.add({
      'id': novoIdPessoa,
      'nome': nome,
      'cargo': cargo,
      'ativo': 1,
    });

    var vinculos = _tabelas['pessoa_turno']!;
    int novoIdVinculo = vinculos.isNotEmpty ? vinculos.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1 : 1;

    for (var turnoId in turnosIds) {
      vinculos.add({
        'id': novoIdVinculo++,
        'pessoa_id': novoIdPessoa,
        'turno_id': turnoId,
        'data': DateTime.now().toIso8601String().split('T')[0],
      });
    }
  }

  static void atualizarPessoa(int pessoaId, String nome, String cargo, List<int> turnosIds) {
    var pessoas = _tabelas['pessoas']!;
    var pessoaIndex = pessoas.indexWhere((p) => p['id'] == pessoaId);

    if (pessoaIndex != -1) {
      pessoas[pessoaIndex]['nome'] = nome;
      pessoas[pessoaIndex]['cargo'] = cargo;

      _tabelas['pessoa_turno']!.removeWhere((v) => v['pessoa_id'] == pessoaId);

      var vinculos = _tabelas['pessoa_turno']!;
      int novoIdVinculo = vinculos.isNotEmpty ? vinculos.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1 : 1;

      for (var turnoId in turnosIds) {
        vinculos.add({
          'id': novoIdVinculo++,
          'pessoa_id': pessoaId,
          'turno_id': turnoId,
          'data': DateTime.now().toIso8601String().split('T')[0],
        });
      }
    }
  }

  static void excluirPessoaLogica(int pessoaId) {
    var pessoas = _tabelas['pessoas']!;
    var index = pessoas.indexWhere((p) => p['id'] == pessoaId);
    if (index != -1) {
      pessoas[index]['ativo'] = 0;
    }
  }

  static Map<int, String> consultarStatusChamadaSalva(int turnoId, String data) {
    var chamadas = _tabelas['chamadas']!;
    var chamadaMatch = chamadas.firstWhere(
      (c) => c['turno_id'] == turnoId && c['data'] == data,
      orElse: () => {},
    );

    if (chamadaMatch.isEmpty) return {};

    int chamadaId = chamadaMatch['id'];
    var itens = _tabelas['itens_chamada']!.where((i) => i['chamada_id'] == chamadaId);
    
    Map<int, String> resultado = {};
    for (var item in itens) {
      resultado[item['pessoa_id']] = item['status'];
    }
    return resultado;
  }

  static void salvarChamada(int turnoId, String data, Map<int, String> statusMap) {
    var chamadas = _tabelas['chamadas']!;
    var indexChamada = chamadas.indexWhere((c) => c['turno_id'] == turnoId && c['data'] == data);
    int chamadaId;

    if (indexChamada != -1) {
      chamadaId = chamadas[indexChamada]['id'];
      _tabelas['itens_chamada']!.removeWhere((i) => i['chamada_id'] == chamadaId);
    } else {
      chamadaId = chamadas.isNotEmpty ? chamadas.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1 : 1;
      chamadas.add({
        'id': chamadaId,
        'turno_id': turnoId,
        'data': data,
        'criado_em': DateTime.now().toIso8601String(),
      });
    }

    var itens = _tabelas['itens_chamada']!;
    int novoItemId = itens.isNotEmpty ? itens.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1 : 1;

    statusMap.forEach((pessoaId, status) {
      itens.add({
        'id': novoItemId++,
        'chamada_id': chamadaId,
        'pessoa_id': pessoaId,
        'status': status,
      });
    });
  }

  static List<Map<String, dynamic>> consultarHistoricoChamadas() {
    var chamadas = _tabelas['chamadas']!;
    var turnos = _tabelas['turnos']!;
    var itens = _tabelas['itens_chamada']!;
    var pessoas = _tabelas['pessoas']!;

    return chamadas.map((chamada) {
      var turnoInfo = turnos.firstWhere(
        (t) => t['id'] == chamada['turno_id'],
        orElse: () => {'nome': 'Turno Desconhecido'},
      );

      var itensDaChamada = itens.where((i) => i['chamada_id'] == chamada['id']).toList();

      List<Map<String, dynamic>> detalhesPessoas = itensDaChamada.map((item) {
        var pessoaInfo = pessoas.firstWhere(
          (p) => p['id'] == item['pessoa_id'],
          orElse: () => {'nome': 'Desconhecido', 'cargo': 'N/A'},
        );
        return {
          'nome': pessoaInfo['nome'],
          'cargo': pessoaInfo['cargo'],
          'status': item['status'],
        };
      }).toList();

      int presentes = detalhesPessoas.where((i) => i['status'] == 'PRESENTE').length;
      int faltaJustificada = detalhesPessoas.where((i) => i['status'] == 'FALTA JUSTIFICADA').length;
      int faltaNaoJustificada = detalhesPessoas.where((i) => i['status'] == 'FALTA NÃO JUSTIFICADA').length;
      int faltaAtestado = detalhesPessoas.where((i) => i['status'] == 'FALTA COM ATESTADO').length;

      return {
        'id': chamada['id'],
        'data': chamada['data'],
        'turno': turnoInfo['nome'],
        'criado_em': chamada['criado_em'],
        'total_presentes': presentes,
        'total_falta_justificada': faltaJustificada,
        'total_falta_nao_justificada': faltaNaoJustificada,
        'total_falta_atestado': faltaAtestado,
        'detalhes': detalhesPessoas,
      };
    }).toList().reversed.toList();
  }
}