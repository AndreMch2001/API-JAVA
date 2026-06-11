import 'package:bolsafamilia_app/models/buscas.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/bolsafamilia_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiServices {
  final Dio _dio = Dio();
 
  // Pessoal! USEM A SUA IP LOCAL DO SEU COMPUTADOR PARA ACESSAR A API, A VARIAVEL _url é a URL da API, ela é definida no arquivo .env
  final String _url = dotenv.env['_url']!;

  Future<List<BolsaFamiliaModel>> getBeneficiarios({ // Usado future para esperar a resposta da API
    String usuarioDigitado = "", // Nome do favorecido, município ou NIS
    GetBuscas busca = GetBuscas.nomeFavorecido, //Padrão é nome do favorecido
     int pagina = 0 // Padrão é a primeira página
     }) async { // Usado async poruqeu é uma função assíncrona
       try{ // Usado try para capturar erros
        final queryParameters = <String, dynamic>{ // Usado queryParameters para passar os parâmetros da busca
          "pagina": pagina, // Usado pagina para passar o número da página que defininimos por padão como 0
          "tamanho": 20, // Padrão é 20 resultados por página podemos aumentar ou diminuir conforme necessário
       };
       
       switch(busca){ // Usado switch para verificar a busca
        case GetBuscas.nomeFavorecido:
          queryParameters["nome"] = usuarioDigitado; // Usado nome para buscar por nome do favorecido
          break;
        case GetBuscas.nomeMunicipio:
          queryParameters["nomeMunicipio"] = usuarioDigitado; // Usado nomeMunicipio para buscar por município
          break;
        case GetBuscas.nisFavorecido:
          queryParameters["nisFavorecido"] = usuarioDigitado; // Usado nisFavorecido para buscar por NIS
          break;
       }

       final response = await _dio.get(_url, queryParameters: queryParameters); // Usado _dio.get para fazer a requisição GET
       
       List dados = response.data['content']; // Usado response.data['content'] para pegar os dados da resposta
       return dados.map((json) => BolsaFamiliaModel.fromJson(json)).toList(); // Usado map para converter os dados para o modelo BolsaFamiliaModel
       } catch(e){
        debugPrint("Erro na API: $e"); // Usado debugPrint para imprimir o erro
        return []; // Usado return para retornar a lista vazia caso ocorra um erro
       }
     }
     }