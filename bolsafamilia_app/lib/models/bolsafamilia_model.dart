class BolsaFamiliaModel {
  final int? id; // Identificador único do registro.
  final String? competencia; // Competência de pagamento (ex.: 202401).
  final String? uf; // Unidade federativa do beneficiário.
  final String? nomeMunicipio; // Nome do município do beneficiário.
  final String? nomeFavorecido; // Nome da pessoa favorecida.
  final double? valorParcela; // Valor da parcela paga ao beneficiário.
  final String? nisFavorecido; // Número NIS do favorecido.

  BolsaFamiliaModel({
    this.id, // Recebe o id opcional da resposta.
    this.competencia, // Recebe a competência opcional.
    this.uf, // Recebe a UF opcional.
    this.nomeMunicipio, // Recebe o município opcional.
    this.nomeFavorecido, // Recebe o nome opcional.
    this.valorParcela, // Recebe o valor opcional da parcela.
    this.nisFavorecido, // Recebe o NIS opcional.
  });

  // Converte o JSON do Java (Spring) para o Objeto Flutter
  factory BolsaFamiliaModel.fromJson(Map<String, dynamic> json) {
    return BolsaFamiliaModel(
      id: json['id'], // Mapeia o id retornado pela API.
      competencia: json['competencia'], // Mapeia a competência retornada pela API.
      uf: json['uf'], // Mapeia a UF retornada pela API.
      nomeMunicipio: json['nomeMunicipio'], // Mapeia o município retornado pela API.
      nomeFavorecido: json['nomeFavorecido'], // Mapeia o nome do favorecido retornado pela API.
      valorParcela: json['valorParcela'] is int 
          ? (json['valorParcela'] as int).toDouble() 
          : json['valorParcela'], // Converte para double quando vier inteiro.
      nisFavorecido: json['nisFavorecido'], // Mapeia o NIS retornado pela API.
    );
  }
}