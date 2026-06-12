import 'package:dio/dio.dart'; // Importa cliente HTTP para chamadas REST.
import 'package:flutter/material.dart'; // Importa utilitário debugPrint do Flutter.
import '../models/bolsafamilia_model.dart'; // Importa modelo de resposta.
import '../models/filtro_busca.dart'; // Importa modelo de filtros enviados na query.
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa leitura de variáveis de ambiente.

class ApiServices {
  final Dio _dio = Dio(); // Instância HTTP reutilizada para requisições.

  // Pessoal! USEM A SUA IP LOCAL DO SEU COMPUTADOR PARA ACESSAR A API, A VARIAVEL _url é a URL da API, ela é definida no arquivo .env
  final String _url = dotenv.env['_url']!;

  // Quantidade de itens por página (usada pela paginação infinita).
  static const int tamanhoPagina = 20;

  Future<List<BolsaFamiliaModel>> getBeneficiarios({
    required FiltroBusca filtro, // Agora recebemos TODOS os filtros de uma vez
    int pagina = 0,
  }) async {
    try {
      // Parâmetros base de paginação enviados em toda requisição.
      final queryParameters = <String, dynamic>{
        "pagina": pagina,
        "tamanho": tamanhoPagina,
      };

      // Cada filtro só é incluído na query quando o usuário o preencheu.
      if (filtro.nome != null && filtro.nome!.trim().isNotEmpty) {
        queryParameters["nome"] = filtro.nome!.trim();
      }
      if (filtro.uf != null && filtro.uf!.trim().isNotEmpty) {
        queryParameters["uf"] = filtro.uf!.trim();
      }
      if (filtro.nomeMunicipio != null && filtro.nomeMunicipio!.trim().isNotEmpty) {
        queryParameters["nomeMunicipio"] = filtro.nomeMunicipio!.trim();
      }
      if (filtro.competencia != null && filtro.competencia!.trim().isNotEmpty) {
        queryParameters["competencia"] = filtro.competencia!.trim();
      }
      if (filtro.nisFavorecido != null && filtro.nisFavorecido!.trim().isNotEmpty) {
        queryParameters["nisFavorecido"] = filtro.nisFavorecido!.trim();
      }
      if (filtro.valorMinimo != null) {
        queryParameters["valorMinimo"] = filtro.valorMinimo;
      }
      if (filtro.valorMaximo != null) {
        queryParameters["valorMaximo"] = filtro.valorMaximo;
      }

      final response = await _dio.get(_url, queryParameters: queryParameters); // Faz a requisição GET com todos os filtros

      List dados = response.data['content']; // Pega os dados paginados da resposta
      return dados.map((json) => BolsaFamiliaModel.fromJson(json)).toList(); // Converte para o modelo
    } catch (e) {
      debugPrint("Erro na API: $e"); // Registra erro para facilitar diagnóstico.
      return []; // Retorna lista vazia para evitar quebra na UI.
    }
  }
}
