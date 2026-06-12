import 'package:flutter/material.dart'; // Importa base do ChangeNotifier.
import '../models/bolsafamilia_model.dart'; // Importa o modelo de item retornado.
import '../models/filtro_busca.dart'; // Importa o modelo de filtros da busca.
import '../services/api_services.dart'; // Importa serviço responsável por chamar a API.

class BolsaProvider with ChangeNotifier { // classe utilizando notifiers para "avisar" quando algo mudar na tela, para poder ser recontruida
  final ApiServices _service = ApiServices(); // aqui estamos chamando a api usando um _ para indicar que é uma instancia privada da classe

  List<BolsaFamiliaModel> lista = []; // inicia uma lista de respostas da Api vazia inicial
  bool isLoading = false; // funciona como indicador de carregamento da api
  bool buscaRealizada = false; // indica se o usuário já fez ao menos uma busca (controla o estado inicial vs vazio)
  bool temMais = true; // indica se ainda há mais páginas a carregar (evita chamadas inúteis no fim da lista)
  int paginaAtual = 0; // todas as chamadas iniciam na primeira pagina
  FiltroBusca filtroAtual = const FiltroBusca(); // guarda o conjunto de filtros aplicado na busca atual

  // Faz uma nova busca a partir de um conjunto completo de filtros.
  Future<void> novaBusca(FiltroBusca filtro) async {
    filtroAtual = filtro; // memoriza os filtros aplicados (usado na paginação e nos chips)
    paginaAtual = 0; // qualquer nova busca reinicia na primeira página
    lista = []; // limpa os resultados anteriores
    temMais = true; // assume que pode haver mais páginas até a API dizer o contrário
    buscaRealizada = true; // marca que uma busca foi disparada
    isLoading = true; // liga o indicador de carregamento
    notifyListeners(); // reconstrói a tela mostrando o loading

    final resultados = await _service.getBeneficiarios( // chama a api para carregar os resultados
      filtro: filtroAtual, // passa os filtros aplicados
      pagina: paginaAtual, // passa a página atual
    );

    lista = resultados; // substitui a lista pelos novos resultados
    temMais = resultados.length >= ApiServices.tamanhoPagina; // se veio página cheia, provavelmente há mais
    isLoading = false; // desliga o indicador de carregamento
    notifyListeners(); // reconstrói a tela com os resultados
  }

  // Carrega a próxima página dos mesmos filtros (scroll infinito).
  Future<void> carregarMais() async {
    if (isLoading || !temMais || !buscaRealizada) return; // evita chamadas duplicadas/desnecessárias

    paginaAtual++; // avança para a próxima página
    isLoading = true; // mostra o carregamento no rodapé da lista
    notifyListeners(); // reconstrói a tela com o carregamento

    final novosDados = await _service.getBeneficiarios( // chama a api para carregar a próxima página
      filtro: filtroAtual, // passa os filtros aplicados
      pagina: paginaAtual, // passa a página atual
    );

    lista.addAll(novosDados); // adiciona os novos itens à lista existente
    temMais = novosDados.length >= ApiServices.tamanhoPagina; // atualiza se ainda há mais páginas
    isLoading = false; // desliga o indicador de carregamento
    notifyListeners(); // reconstrói a tela com os resultados
  }

  // Limpa todos os filtros e resultados, voltando ao estado inicial.
  void limpar() {
    lista = []; // Remove todos os resultados carregados.
    filtroAtual = const FiltroBusca(); // Reseta filtros aplicados.
    buscaRealizada = false; // Marca que nenhuma busca está ativa.
    paginaAtual = 0; // Volta para a página inicial.
    temMais = true; // Reativa possibilidade de paginação futura.
    isLoading = false; // Garante que loading fique desligado.
    notifyListeners(); // Atualiza a interface após o reset.
  }
}
