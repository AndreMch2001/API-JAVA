import 'package:flutter/material.dart'; // Importa componentes visuais base do Flutter.
import 'package:flutter/services.dart'; // Importa formatadores de entrada (ex.: apenas dígitos).
import 'package:provider/provider.dart'; // Importa gerenciamento de estado com Provider.
import '../providers/bolsa_provider.dart'; // Importa o provider responsável pelas buscas e paginação.
import '../models/filtro_busca.dart'; // Importa o modelo que representa todos os filtros da API.

class _AppColors { // Classe utilitária com paleta centralizada para manter consistência visual.
  static const background    = Color(0xFF0D1117); // Cor de fundo principal da página.
  static const surface       = Color(0xFF161B22); // Cor de superfícies de campos e painéis.
  static const card          = Color(0xFF1C2333); // Cor base dos cards e containers de destaque.
  static const accent        = Color(0xFFF78166); // Cor de destaque para ações principais.
  static const accentDark    = Color(0xFFBF3600); // Tom escuro da cor de destaque para gradientes.
  static const accentMuted   = Color(0xFF3D1A0A); // Fundo suave para chips/etiquetas de destaque.
  static const textPrimary   = Color(0xFFE6EDF3); // Cor principal dos textos.
  static const textSecondary = Color(0xFF8B949E); // Cor secundária para textos de apoio.
  static const border        = Color(0xFF30363D); // Cor padrão de bordas.
}

// Lista de UFs para o seletor (evita erro de digitação — heurística de prevenção de erros).
const List<String> _ufs = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB',
  'PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
];

class PageOne extends StatefulWidget { // Tela principal de pesquisa dos beneficiários.
  const PageOne({super.key}); // Construtor padrão do widget.

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> { // Estado mutável da tela PageOne.
  final TextEditingController _nomeController = TextEditingController(); // Controla o texto digitado no campo de busca rápida por nome.
  final ScrollController _scrollController = ScrollController(); // Controla o scroll para disparar paginação infinita.

  @override
  void initState() { // Método executado uma vez quando o estado é criado.
    super.initState(); // Inicializa o ciclo de vida da classe pai.
    _scrollController.addListener(() { // Escuta movimentação da lista de resultados.
      final pos = _scrollController.position; // Captura posição atual e limite de scroll.
      if (pos.pixels >= pos.maxScrollExtent - 200) { // Quando estiver próximo ao fim da lista...
        context.read<BolsaProvider>().carregarMais(); // ...carrega a próxima página automaticamente.
      }
    });
  }

  // Dispara uma busca rápida apenas pelo campo "Nome" da barra superior.
  void _buscarPorNome() { // Executa busca rápida usando o nome digitado e mantendo os demais filtros já aplicados.
    final provider = context.read<BolsaProvider>(); // Lê o provider sem escutar rebuild desta chamada.
    final filtroAtual = provider.filtroAtual; // Recupera filtros atuais para preservar os demais campos.
    final novoFiltro = FiltroBusca( // Cria novo objeto de filtros com o nome atualizado.
      nome: _nomeController.text.trim().isEmpty ? null : _nomeController.text.trim(), // Nome vazio vira null para não ser enviado à API.
      uf: filtroAtual.uf, // Mantém UF existente.
      nomeMunicipio: filtroAtual.nomeMunicipio, // Mantém município existente.
      competencia: filtroAtual.competencia, // Mantém competência existente.
      nisFavorecido: filtroAtual.nisFavorecido, // Mantém NIS existente.
      valorMinimo: filtroAtual.valorMinimo, // Mantém valor mínimo existente.
      valorMaximo: filtroAtual.valorMaximo, // Mantém valor máximo existente.
    );
    FocusScope.of(context).unfocus(); // Fecha teclado para melhorar experiência após pesquisar.
    provider.novaBusca(novoFiltro); // Dispara nova busca com o filtro montado.
  }

  // Abre o painel de filtros avançados (todos os filtros da API).
  Future<void> _abrirFiltros() async { // Abre o painel de filtros avançados e aguarda retorno do filtro aplicado.
    final provider = context.read<BolsaProvider>(); // Acessa estado atual para preencher valores iniciais do painel.
    final resultado = await showModalBottomSheet<FiltroBusca>( // Exibe bottom sheet e espera objeto FiltroBusca ao fechar.
      context: context, // Contexto atual da tela.
      isScrollControlled: true, // Permite o painel subir junto com teclado.
      backgroundColor: Colors.transparent, // Fundo transparente para manter estilo customizado.
      builder: (_) => _FiltrosSheet(filtroInicial: provider.filtroAtual), // Envia filtro atual para edição.
    );
    if (resultado != null) { // Se o usuário aplicou filtros...
      _nomeController.text = resultado.nome ?? ''; // Sincroniza campo de busca rápida com o nome retornado.
      provider.novaBusca(resultado); // Executa busca com os filtros escolhidos no painel.
    }
  }

  // Remove um filtro individual ao tocar no "x" do chip.
  void _removerFiltro(String rotulo) { // Remove apenas um filtro ao tocar no "x" do chip.
    final provider = context.read<BolsaProvider>(); // Acessa provider atual para alterar filtros.
    final novoFiltro = provider.filtroAtual.removerPorRotulo(rotulo); // Gera nova cópia dos filtros sem o rótulo removido.
    if (rotulo == 'Nome') _nomeController.clear(); // Se removeu o nome, limpa também o campo visual de busca.
    if (novoFiltro.isVazio) { // Se não restou nenhum filtro...
      provider.limpar(); // ...volta tela ao estado inicial.
    } else {
      provider.novaBusca(novoFiltro); // Senão, pesquisa novamente com os filtros restantes.
    }
  }

  void _limparTudo() { // Limpa todos os filtros e resultados exibidos.
    _nomeController.clear(); // Limpa o texto da busca rápida.
    FocusScope.of(context).unfocus(); // Fecha teclado para evitar ruído visual.
    context.read<BolsaProvider>().limpar(); // Reseta estado completo da pesquisa.
  }

  @override
  Widget build(BuildContext context) { // Monta interface da tela a cada mudança de estado.
    final provider = context.watch<BolsaProvider>(); // Escuta provider para reconstruir quando houver notifyListeners().
    final filtrosAtivos = provider.filtroAtual.ativos; // Obtém mapa de chips ativos para exibição.

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1C2333), Color(0xFF0D1117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.savings_outlined, color: _AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text(
              "Bolsa Família",
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca rápida (Nome) + botão de filtros avançados
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nomeController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarPorNome(),
                    style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
                    cursorColor: _AppColors.accent,
                    decoration: _inputDecoration(
                      label: "Buscar por nome",
                      hint: "Digite o nome do favorecido",
                      prefix: const Icon(Icons.search, color: _AppColors.textSecondary, size: 20),
                      suffix: _nomeController.text.isNotEmpty
                          ? IconButton(
                              tooltip: "Limpar",
                              icon: const Icon(Icons.close, color: _AppColors.textSecondary, size: 18),
                              onPressed: () {
                                setState(() => _nomeController.clear());
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                // Botão de filtros com badge indicando quantidade ativa
                _FilterButton(
                  quantidade: provider.filtroAtual.quantidadeAtiva,
                  onTap: _abrirFiltros,
                ),
              ],
            ),
          ),

          // Chips de filtros ativos (reconhecimento em vez de memorização + controle do usuário)
          if (filtrosAtivos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filtrosAtivos.entries.map((e) {
                        return _FiltroChip(
                          rotulo: e.key,
                          valor: e.value,
                          onRemover: () => _removerFiltro(e.key),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _limparTudo,
                    icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                    label: const Text("Limpar"),
                    style: TextButton.styleFrom(
                      foregroundColor: _AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),

          // Barra de status: contador de resultados (visibilidade do status do sistema)
          if (provider.buscaRealizada && provider.lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 14, color: _AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    "${provider.lista.length} resultado(s)${provider.temMais ? '+' : ''}",
                    style: const TextStyle(color: _AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Área principal de conteúdo com seus diferentes estados
          Expanded(child: _buildConteudo(provider)), // Renderiza estados principais: loading, vazio ou lista de resultados.
        ],
      ),
    );
  }

  Widget _buildConteudo(BolsaProvider provider) { // Decide qual conteúdo mostrar conforme estado da busca.
    // Estado de carregamento inicial (sem itens ainda)
    if (provider.isLoading && provider.lista.isEmpty) { // Primeiro carregamento sem resultados prévios.
      return const Center(
        child: CircularProgressIndicator(color: _AppColors.accent, strokeWidth: 2.5),
      );
    }

    // Estado inicial: nenhuma busca feita ainda
    if (!provider.buscaRealizada) { // Estado inicial antes de qualquer pesquisa.
      return const _EstadoVazio(
        icone: Icons.travel_explore_outlined,
        titulo: "Comece sua pesquisa",
        descricao: "Busque por nome ou use os filtros avançados para refinar os resultados (UF, município, competência, NIS e faixa de valor).",
      );
    }

    // Busca feita mas sem resultados (ajuda o usuário a se recuperar)
    if (provider.lista.isEmpty) { // Busca executada, porém sem resultados.
      return const _EstadoVazio(
        icone: Icons.search_off_outlined,
        titulo: "Nenhum resultado encontrado",
        descricao: "Tente remover algum filtro ou revisar os termos da busca.",
      );
    }

    // Lista de resultados com paginação infinita
    return ListView.builder( // Lista principal com paginação infinita.
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: provider.lista.length + (provider.isLoading ? 1 : 0), // Soma célula extra para loader de rodapé enquanto carrega próxima página.
      itemBuilder: (context, index) {
        if (index < provider.lista.length) { // Índices válidos da lista retornam cards de beneficiário.
          return _BeneficiarioCard(item: provider.lista[index]);
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: _AppColors.accent, strokeWidth: 2.5),
          ),
        );
      },
    );
  }

  @override
  void dispose() { // Libera recursos dos controllers para evitar vazamento de memória.
    _scrollController.dispose(); // Descarta listener/estado do scroll.
    _nomeController.dispose(); // Descarta controller do campo de nome.
    super.dispose(); // Finaliza ciclo de vida do estado.
  }
}

// Decoração reutilizável dos campos (consistência e padrões).
InputDecoration _inputDecoration({ // Função utilitária para padronizar aparência dos campos.
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
}) { // Recebe rótulo, dica e ícones opcionais para o campo.
  return InputDecoration( // Retorna configuração única reutilizada em toda a tela.
    labelText: label, // Texto exibido como label do campo.
    hintText: hint, // Texto auxiliar exibido quando o campo está vazio.
    labelStyle: const TextStyle(color: _AppColors.textSecondary), // Estilo padrão do label.
    hintStyle: const TextStyle(color: _AppColors.textSecondary, fontSize: 13), // Estilo padrão da dica.
    prefixIcon: prefix, // Ícone no início do campo (quando informado).
    suffixIcon: suffix, // Ícone no fim do campo (quando informado).
    filled: true, // Ativa preenchimento de fundo do campo.
    fillColor: _AppColors.surface, // Define cor de fundo do campo.
    isDense: true, // Reduz altura vertical para layout mais compacto.
    enabledBorder: OutlineInputBorder( // Borda padrão quando campo não está focado.
      borderRadius: BorderRadius.circular(12), // Arredondamento consistente dos cantos.
      borderSide: const BorderSide(color: _AppColors.border), // Cor de borda padrão.
    ),
    focusedBorder: OutlineInputBorder( // Borda destacada quando o campo recebe foco.
      borderRadius: BorderRadius.circular(12), // Mantém mesmo arredondamento da borda padrão.
      borderSide: const BorderSide(color: _AppColors.accent, width: 2), // Cor e espessura de foco para feedback visual.
    ),
  );
}

// Botão de filtros com badge de quantidade ativa.
class _FilterButton extends StatelessWidget { // Botão de abrir filtros avançados com badge de quantidade ativa.
  final int quantidade; // Número de filtros ativos exibido no badge.
  final VoidCallback onTap; // Callback executado ao tocar no botão.

  const _FilterButton({required this.quantidade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Filtros avançados",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AppColors.accent, _AppColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.tune, color: Colors.white, size: 22),
                if (quantidade > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "$quantidade",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Chip que mostra um filtro ativo e permite removê-lo.
class _FiltroChip extends StatelessWidget { // Componente visual de filtro ativo com ação de remover.
  final String rotulo; // Nome do filtro (ex.: UF, Município, NIS).
  final String valor; // Valor aplicado naquele filtro.
  final VoidCallback onRemover; // Callback executado ao clicar no "x" do chip.

  const _FiltroChip({required this.rotulo, required this.valor, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: _AppColors.accentMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$rotulo: $valor",
            style: const TextStyle(color: _AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemover,
            borderRadius: BorderRadius.circular(20),
            child: const Icon(Icons.close, size: 15, color: _AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// Estado vazio / inicial reutilizável (mensagens claras de ajuda).
class _EstadoVazio extends StatelessWidget { // Componente reutilizável para estados sem dados.
  final IconData icone; // Ícone central para reforçar contexto da mensagem.
  final String titulo; // Título principal do estado vazio.
  final String descricao; // Texto auxiliar com orientação para o usuário.

  const _EstadoVazio({required this.icone, required this.titulo, required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.border),
              ),
              child: Icon(icone, size: 40, color: _AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painel (bottom sheet) com TODOS os filtros disponíveis na API.
// ---------------------------------------------------------------------------
class _FiltrosSheet extends StatefulWidget { // Painel inferior para edição de todos os filtros avançados.
  final FiltroBusca filtroInicial; // Filtros atuais usados para preencher os campos ao abrir.

  const _FiltrosSheet({required this.filtroInicial});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> { // Estado local do formulário de filtros.
  late final TextEditingController _nome; // Controller do campo nome.
  late final TextEditingController _municipio; // Controller do campo município.
  late final TextEditingController _competencia; // Controller do campo competência.
  late final TextEditingController _nis; // Controller do campo NIS.
  late final TextEditingController _valorMin; // Controller do campo valor mínimo.
  late final TextEditingController _valorMax; // Controller do campo valor máximo.
  String? _uf; // UF selecionada no dropdown.
  String? _erroValor; // Mensagem de erro para validação da faixa de valores.

  @override
  void initState() { // Inicializa campos do formulário com os filtros que já estavam aplicados.
    super.initState(); // Inicializa ciclo de vida do estado.
    final f = widget.filtroInicial; // Atalho para leitura do filtro recebido no widget.
    _nome = TextEditingController(text: f.nome ?? ''); // Preenche nome inicial.
    _municipio = TextEditingController(text: f.nomeMunicipio ?? ''); // Preenche município inicial.
    _competencia = TextEditingController(text: f.competencia ?? ''); // Preenche competência inicial.
    _nis = TextEditingController(text: f.nisFavorecido ?? ''); // Preenche NIS inicial.
    _valorMin = TextEditingController(text: f.valorMinimo?.toString() ?? ''); // Preenche valor mínimo inicial.
    _valorMax = TextEditingController(text: f.valorMaximo?.toString() ?? ''); // Preenche valor máximo inicial.
    _uf = f.uf; // Define UF inicial.
  }

  double? _parseValor(TextEditingController c) { // Converte texto em double aceitando vírgula ou ponto.
    final txt = c.text.trim().replaceAll(',', '.'); // Normaliza decimal para ponto antes do parse.
    if (txt.isEmpty) return null; // Campo vazio retorna null para não aplicar filtro.
    return double.tryParse(txt); // Retorna valor numérico ou null se inválido.
  }

  void _aplicar() { // Valida e devolve o filtro preenchido para a tela principal.
    final min = _parseValor(_valorMin); // Lê valor mínimo digitado.
    final max = _parseValor(_valorMax); // Lê valor máximo digitado.

    // Prevenção de erro: valor mínimo não pode ser maior que o máximo.
    if (min != null && max != null && min > max) { // Regra de validação da faixa.
      setState(() => _erroValor = "O valor mínimo não pode ser maior que o máximo."); // Exibe mensagem de erro na UI.
      return; // Interrompe envio até corrigir valores.
    }

    final filtro = FiltroBusca( // Monta objeto final com tudo que foi preenchido.
      nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(), // Nome vazio vira null.
      uf: _uf, // UF selecionada no dropdown.
      nomeMunicipio: _municipio.text.trim().isEmpty ? null : _municipio.text.trim(), // Município vazio vira null.
      competencia: _competencia.text.trim().isEmpty ? null : _competencia.text.trim(), // Competência vazia vira null.
      nisFavorecido: _nis.text.trim().isEmpty ? null : _nis.text.trim(), // NIS vazio vira null.
      valorMinimo: min, // Valor mínimo convertido.
      valorMaximo: max, // Valor máximo convertido.
    );

    Navigator.of(context).pop(filtro); // Fecha o painel retornando o filtro para quem abriu.
  }

  void _limpar() { // Limpa todos os campos do formulário de filtros.
    setState(() { // Atualiza UI imediatamente após limpeza.
      _nome.clear(); // Limpa nome.
      _municipio.clear(); // Limpa município.
      _competencia.clear(); // Limpa competência.
      _nis.clear(); // Limpa NIS.
      _valorMin.clear(); // Limpa valor mínimo.
      _valorMax.clear(); // Limpa valor máximo.
      _uf = null; // Remove seleção de UF.
      _erroValor = null; // Remove mensagem de erro, caso exista.
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: _AppColors.border),
          left: BorderSide(color: _AppColors.border),
          right: BorderSide(color: _AppColors.border),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Handle" + cabeçalho com ação de fechar (controle e liberdade do usuário)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.tune, color: _AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Filtros de pesquisa",
                    style: TextStyle(
                      color: _AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Fechar",
                  icon: const Icon(Icons.close, color: _AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _campo(
              controller: _nome,
              label: "Nome do favorecido",
              hint: "Ex.: Maria da Silva",
              icone: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            _campo(
              controller: _nis,
              label: "NIS do favorecido",
              hint: "Número de Identificação Social",
              icone: Icons.badge_outlined,
              teclado: TextInputType.number,
              apenasNumeros: true,
            ),
            const SizedBox(height: 12),

            _campo(
              controller: _municipio,
              label: "Município",
              hint: "Ex.: São Paulo",
              icone: Icons.location_city_outlined,
            ),
            const SizedBox(height: 12),

            // UF como dropdown evita erros de digitação
            DropdownButtonFormField<String>(
              initialValue: _uf,
              isExpanded: true,
              dropdownColor: _AppColors.surface,
              style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
              iconEnabledColor: _AppColors.accent,
              decoration: _inputDecoration(
                label: "UF",
                prefix: const Icon(Icons.map_outlined, color: _AppColors.textSecondary, size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text("Todas"),
                ),
                ..._ufs.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))),
              ],
              onChanged: (v) => setState(() => _uf = v),
            ),
            const SizedBox(height: 12),

            _campo(
              controller: _competencia,
              label: "Competência",
              hint: "Formato AAAAMM (ex.: 202401)",
              icone: Icons.calendar_today_outlined,
              teclado: TextInputType.number,
              apenasNumeros: true,
              maxLength: 6,
            ),
            const SizedBox(height: 12),

            // Faixa de valor (mínimo e máximo) lado a lado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    controller: _valorMin,
                    label: "Valor mín.",
                    hint: "0,00",
                    icone: Icons.attach_money,
                    teclado: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    controller: _valorMax,
                    label: "Valor máx.",
                    hint: "0,00",
                    icone: Icons.attach_money,
                    teclado: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            // Mensagem de erro de validação (ajuda a reconhecer/recuperar de erros)
            if (_erroValor != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _erroValor!,
                        style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Ações: limpar e aplicar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _limpar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AppColors.textPrimary,
                      side: const BorderSide(color: _AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Limpar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _aplicar,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Aplicar filtros"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({ // Factory de campo para reduzir repetição no formulário.
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icone,
    TextInputType teclado = TextInputType.text,
    bool apenasNumeros = false,
    int? maxLength,
  }) { // Recebe parâmetros do campo e devolve TextField configurado.
    return TextField( // Campo de entrada padrão do painel de filtros.
      controller: controller, // Liga campo ao respectivo controller.
      keyboardType: teclado, // Define tipo de teclado (texto, número, decimal).
      maxLength: maxLength, // Limita quantidade de caracteres quando informado.
      inputFormatters: apenasNumeros ? [FilteringTextInputFormatter.digitsOnly] : null, // Restringe entrada a números quando necessário.
      style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14), // Estilo visual do texto digitado.
      cursorColor: _AppColors.accent, // Cor do cursor.
      decoration: _inputDecoration( // Usa decoração padrão para consistência visual.
        label: label, // Define label do campo.
        hint: hint, // Define texto de dica.
        prefix: icone != null // Verifica se deve renderizar ícone prefixo.
            ? Icon(icone, color: _AppColors.textSecondary, size: 20) // Cria ícone de apoio visual.
            : null, // Sem ícone quando não informado.
      ).copyWith(counterText: ""), // Remove contador visual de caracteres para layout limpo.
    );
  }
}

class _BeneficiarioCard extends StatelessWidget { // Card visual de cada beneficiário retornado na busca.
  final dynamic item; // Item de dados exibido no card (modelo de beneficiário).

  const _BeneficiarioCard({required this.item});

  String _formatarValor(dynamic valor) { // Formata valor numérico para padrão brasileiro (2 casas e vírgula).
    if (valor == null) return "0,00"; // Valor nulo recebe fallback seguro.
    final d = valor is num ? valor.toDouble() : double.tryParse(valor.toString()) ?? 0; // Converte diferentes tipos para double.
    return d.toStringAsFixed(2).replaceAll('.', ','); // Formata para duas casas e troca ponto por vírgula.
  }

  @override
  Widget build(BuildContext context) {
    final subtituloPartes = <String>[
      if (item.nomeMunicipio != null && (item.nomeMunicipio as String).isNotEmpty) item.nomeMunicipio,
      if (item.nisFavorecido != null && (item.nisFavorecido as String).isNotEmpty) "NIS: ${item.nisFavorecido}",
      if (item.competencia != null && (item.competencia as String).isNotEmpty) "Comp.: ${item.competencia}",
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_AppColors.accent, _AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              item.uf ?? "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          item.nomeFavorecido ?? "",
          style: const TextStyle(
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtituloPartes.join(" · "),
            style: const TextStyle(color: _AppColors.textSecondary, fontSize: 12),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _AppColors.accentMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _AppColors.accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            "R\$ ${_formatarValor(item.valorParcela)}",
            style: const TextStyle(
              color: _AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
