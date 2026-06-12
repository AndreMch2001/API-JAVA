class FiltroBusca { // Modelo único com todos os filtros aceitos pela API.
  final String? nome; // Campo para filtrar por nome do favorecido (parametro "nome").
  final String? uf; // Campo para filtrar por UF (parametro "uf").
  final String? nomeMunicipio; // Campo para filtrar por município (parametro "nomeMunicipio").
  final String? competencia; // Campo para filtrar por competência (parametro "competencia").
  final String? nisFavorecido; // Campo para filtrar por NIS exato (parametro "nisFavorecido").
  final double? valorMinimo; // Campo para filtrar valorParcela >= valorMinimo.
  final double? valorMaximo; // Campo para filtrar valorParcela <= valorMaximo.

  const FiltroBusca({ // Construtor imutável para criar o conjunto de filtros.
    this.nome, // Recebe o valor opcional do nome.
    this.uf, // Recebe o valor opcional da UF.
    this.nomeMunicipio, // Recebe o valor opcional do município.
    this.competencia, // Recebe o valor opcional da competência.
    this.nisFavorecido, // Recebe o valor opcional do NIS.
    this.valorMinimo, // Recebe o valor opcional mínimo da parcela.
    this.valorMaximo, // Recebe o valor opcional máximo da parcela.
  });

  bool get isVazio => // Getter que informa se nenhum filtro foi preenchido.
      (nome == null || nome!.trim().isEmpty) && // Nome vazio ou nulo não conta como filtro ativo.
      (uf == null || uf!.trim().isEmpty) && // UF vazia ou nula não conta como filtro ativo.
      (nomeMunicipio == null || nomeMunicipio!.trim().isEmpty) && // Município vazio ou nulo não conta como filtro ativo.
      (competencia == null || competencia!.trim().isEmpty) && // Competência vazia ou nula não conta como filtro ativo.
      (nisFavorecido == null || nisFavorecido!.trim().isEmpty) && // NIS vazio ou nulo não conta como filtro ativo.
      valorMinimo == null && // Valor mínimo só conta quando informado.
      valorMaximo == null; // Valor máximo só conta quando informado.

  int get quantidadeAtiva => ativos.length; // Retorna quantos filtros estão ativos para exibir badge na UI.

  Map<String, String> get ativos { // Monta mapa com os filtros ativos para renderizar chips e resumo visual.
    final mapa = <String, String>{}; // Mapa final no formato "rótulo -> valor".
    if (nome != null && nome!.trim().isNotEmpty) mapa['Nome'] = nome!.trim(); // Adiciona o chip de nome quando preenchido.
    if (uf != null && uf!.trim().isNotEmpty) mapa['UF'] = uf!.trim(); // Adiciona o chip de UF quando preenchido.
    if (nomeMunicipio != null && nomeMunicipio!.trim().isNotEmpty) { // Verifica se município está válido.
      mapa['Município'] = nomeMunicipio!.trim(); // Adiciona o chip de município.
    }
    if (competencia != null && competencia!.trim().isNotEmpty) { // Verifica se competência está válida.
      mapa['Competência'] = competencia!.trim(); // Adiciona o chip de competência.
    }
    if (nisFavorecido != null && nisFavorecido!.trim().isNotEmpty) { // Verifica se NIS está válido.
      mapa['NIS'] = nisFavorecido!.trim(); // Adiciona o chip de NIS.
    }
    if (valorMinimo != null) { // Verifica se valor mínimo foi informado.
      mapa['Valor mín.'] = 'R\$ ${valorMinimo!.toStringAsFixed(2)}'; // Formata e adiciona chip de valor mínimo.
    }
    if (valorMaximo != null) { // Verifica se valor máximo foi informado.
      mapa['Valor máx.'] = 'R\$ ${valorMaximo!.toStringAsFixed(2)}'; // Formata e adiciona chip de valor máximo.
    }
    return mapa; // Retorna o mapa final com os filtros ativos.
  }

  FiltroBusca removerPorRotulo(String rotulo) { // Cria uma cópia removendo apenas o filtro clicado no chip.
    return FiltroBusca( // Retorna novo objeto preservando imutabilidade.
      nome: rotulo == 'Nome' ? null : nome, // Remove nome somente quando o chip "Nome" for removido.
      uf: rotulo == 'UF' ? null : uf, // Remove UF somente quando o chip "UF" for removido.
      nomeMunicipio: rotulo == 'Município' ? null : nomeMunicipio, // Remove município somente quando o chip "Município" for removido.
      competencia: rotulo == 'Competência' ? null : competencia, // Remove competência somente quando o chip "Competência" for removido.
      nisFavorecido: rotulo == 'NIS' ? null : nisFavorecido, // Remove NIS somente quando o chip "NIS" for removido.
      valorMinimo: rotulo == 'Valor mín.' ? null : valorMinimo, // Remove valor mínimo somente quando o chip "Valor mín." for removido.
      valorMaximo: rotulo == 'Valor máx.' ? null : valorMaximo, // Remove valor máximo somente quando o chip "Valor máx." for removido.
    );
  }
}
