# controle_chamadas

PROJETO: App Android (APK) de controle de chamadas diárias.
TECNOLOGIA: Flutter + SQLite local (criptografado). Sem servidor, sem internet. 1 aparelho.

TURNOS: Manhã, Tarde, Noite (~40 pessoas por turno).
SITUAÇÕES: Presente, Falta Justificada, Falta Não Justificada, Falta com Atestado.

PESSOAS: nome, cargo, setor, empresa, ativo. Podem pertencer a mais de um turno
(tabela Pessoa_Turno). Nunca apagar, só inativar/reativar.

CHAMADA:
- Só pode ser criada para o dia atual. Única por data+turno.
- Ao iniciar, congela a lista de pessoas ativas daquele turno.
- Salva a cada marcação (status: em andamento / finalizada).
- Chamadas finalizadas e de dias anteriores podem ser EDITADAS por Admin e Operador.
- Nunca criar chamada retroativa.
- Toda correção gera auditoria com valor antes e depois.

PERFIS:
- Administrador: tudo.
- Operador: fazer chamada, corrigir chamadas, consultar histórico.
- Somente Admin: pessoas, usuários, auditoria, exportação Excel.
  
- EXCEL (.xlsx): filtros combináveis (período, turno, pessoa, cargo, setor, empresa,
situação, usuário, chamadas corrigidas) e escolha de colunas.
Planilhas: Presenças, Pessoas (com turnos), Auditoria (só Admin).

BACKUP: Administrador exporta semanalmente. Excel é só consulta.
SEM importação/restauração na V1.
https://share.gemini.google/fe8YvzUikoRO
