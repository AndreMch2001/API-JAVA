# Entendendo o App Flutter — explicação para iniciantes

Este documento explica, de forma bem simples e didática, **o que cada arquivo `.dart` faz** no app do Bolsa Família. A linguagem é propositalmente fácil, com comparações do dia a dia, para que mesmo quem está começando consiga entender e reproduzir.

---

## A grande ideia: o app é como um restaurante 🍽️

Imagine um restaurante:

- **Você (cliente)** = a pessoa usando o app
- **O garçom** = a tela (`page_one.dart`)
- **O gerente** = o "cérebro" que organiza tudo (`bolsa_provider.dart`)
- **O entregador que vai na cozinha** = o serviço de internet (`api_services.dart`)
- **A cozinha (a API Java, em outro lugar)** = o servidor que tem os dados
- **As fôrmas/moldes** = os modelos de dados (`bolsafamilia_model.dart` e `filtro_busca.dart`)

O app inteiro é só isso: você pede algo ao garçom, ele avisa o gerente, o gerente manda o entregador buscar na cozinha, e a comida volta para a sua mesa. Vamos ver cada "pessoa" desse restaurante.

| Pessoa do restaurante | Arquivo | O que faz |
|---|---|---|
| O interruptor de ligar | `main.dart` | Liga o app e abre a 1ª tela |
| A fôrma do resultado | `models/bolsafamilia_model.dart` | Formato dos dados que voltam |
| A fôrma dos filtros | `models/filtro_busca.dart` | Formato dos filtros enviados |
| O entregador | `services/api_services.dart` | Conversa com a internet/API |
| O gerente | `providers/bolsa_provider.dart` | Guarda o estado e a lógica |
| O garçom | `views/page_one.dart` | Mostra a tela e capta toques |

---

## 1. `main.dart` — A porta de entrada (onde tudo começa) 🚪

Todo app Flutter começa por uma função chamada `main()`. É o primeiro código que roda quando você abre o app.

```dart
void main() async {
  await dotenv.load(fileName: ".env"); // Carrega variáveis do arquivo .env.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BolsaProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

Passo a passo:

1. **`await dotenv.load(...)`** → antes de tudo, lê o arquivo `.env`. Esse arquivo guarda o endereço da API (o "endereço da cozinha") como um segredo, para não ficar escrito direto no código.
2. **`MultiProvider` / `ChangeNotifierProvider`** → isto "liga" o gerente (`BolsaProvider`) e o deixa disponível para **todas** as telas. É como contratar o gerente e dar a ele um crachá que toda a equipe reconhece.
3. **`runApp(MyApp())`** → manda o Flutter desenhar o app na tela.

E o `MyApp`:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PageOne(),
    );
  }
}
```

- **`MaterialApp`** → é a "casca" do app (define tema, cores, etc.).
- **`home: const PageOne()`** → diz qual é a **primeira tela** que aparece.

**Resumo:** `main.dart` é o interruptor geral. Ele liga o gerente e abre a primeira tela.

---

## 2. Os "moldes" de dados (Models) — As fôrmas de bolo 🧁

Models não fazem nada sozinhos. Eles só **descrevem o formato** de uma informação. É como uma fôrma de bolo: define o formato, mas não é o bolo.

### 2a. `bolsafamilia_model.dart` — O molde de UM resultado

Cada beneficiário que volta da API vira um objeto desse molde:

```dart
class BolsaFamiliaModel {
  final int? id;
  final String? competencia;
  final String? uf;
  final String? nomeMunicipio;
  final String? nomeFavorecido;
  final double? valorParcela;
  final String? nisFavorecido;
  // ...
```

- Cada linha é um "campo" (uma gaveta) que guarda uma informação: nome, UF, valor da parcela, etc.
- O `?` significa "pode estar vazio" (pode vir nulo da API).

A parte mais importante é o `fromJson`:

```dart
factory BolsaFamiliaModel.fromJson(Map<String, dynamic> json) {
  return BolsaFamiliaModel(
    id: json['id'],
    competencia: json['competencia'],
    // ...
    valorParcela: json['valorParcela'] is int
        ? (json['valorParcela'] as int).toDouble()
        : json['valorParcela'],
    nisFavorecido: json['nisFavorecido'],
  );
}
```

A API responde em um formato chamado **JSON** (um texto tipo `{"nome": "Maria", "uf": "SP"}`). O `fromJson` é o **tradutor**: pega esse texto e transforma em um objeto Dart organizado, com gavetas nomeadas. Assim você escreve `item.nomeFavorecido` em vez de mexer no texto cru.

> **Detalhe esperto:** às vezes o valor vem como inteiro (ex.: `100`) e às vezes como decimal (`100.50`). Esse trecho garante que sempre vire um número com casas decimais (`double`).

### 2b. `filtro_busca.dart` — O molde dos FILTROS de pesquisa

Enquanto o anterior representa o que **volta** da API, este representa o que o usuário **manda** para a API:

```dart
class FiltroBusca {
  final String? nome;
  final String? uf;
  final String? nomeMunicipio;
  final String? competencia;
  final String? nisFavorecido;
  final double? valorMinimo;
  final double? valorMaximo;
  // ...
```

Esse arquivo é esperto: além de guardar os filtros, ele tem "ajudantes" (chamados `getters`):

- **`isVazio`** → responde "nenhum filtro foi preenchido?". Útil para voltar a tela ao estado inicial.
- **`quantidadeAtiva`** → conta quantos filtros estão ativos (aquele numerozinho no botão de filtro).
- **`ativos`** → monta uma lista tipo `"UF → SP"`, `"Nome → Maria"` para mostrar as "etiquetas" (chips) na tela.
- **`removerPorRotulo`** → cria uma **cópia** dos filtros sem aquele que você clicou para remover.

> **Conceito importante:** repare que todos os campos são `final`. Isso significa **imutável** — depois de criado, o objeto não muda. Quando você quer "mudar" um filtro, você na verdade cria um objeto NOVO (é o que o `removerPorRotulo` faz). Isso evita bugs difíceis.

**Resumo dos models:** são fôrmas que organizam os dados. Um descreve o que volta (resultado), o outro descreve o que vai (filtro).

---

## 3. `api_services.dart` — O entregador que vai na cozinha 🛵

Este arquivo é o único que **conversa com a internet** (a API Java). Ele não cuida de tela nem de estado — só busca dados.

```dart
class ApiServices {
  final Dio _dio = Dio();
  final String _url = dotenv.env['_url']!;
  static const int tamanhoPagina = 20;
```

- **`Dio`** → é uma ferramenta (biblioteca) que sabe fazer pedidos pela internet. Pense nela como a moto do entregador.
- **`_url`** → o endereço da API, lido do arquivo `.env`.
- **`tamanhoPagina = 20`** → busca de 20 em 20 resultados por vez (a base da "rolagem infinita").

A função principal:

```dart
Future<List<BolsaFamiliaModel>> getBeneficiarios({
  required FiltroBusca filtro,
  int pagina = 0,
}) async {
  try {
    final queryParameters = <String, dynamic>{
      "pagina": pagina,
      "tamanho": tamanhoPagina,
    };

    if (filtro.nome != null && filtro.nome!.trim().isNotEmpty) {
      queryParameters["nome"] = filtro.nome!.trim();
    }
    // ... mesmo padrão para uf, município, competência, NIS, valores...

    final response = await _dio.get(_url, queryParameters: queryParameters);
    List dados = response.data['content'];
    return dados.map((json) => BolsaFamiliaModel.fromJson(json)).toList();
  } catch (e) {
    debugPrint("Erro na API: $e");
    return [];
  }
}
```

Passo a passo, em linguagem simples:

1. **Monta o pedido** (`queryParameters`): começa dizendo qual página quer e quantos itens. Depois, para cada filtro preenchido, adiciona no pedido. Filtro vazio **não** é enviado.
2. **Faz o pedido** (`_dio.get`): o `await` significa "espere a resposta chegar antes de continuar" (igual esperar o entregador voltar da cozinha).
3. **Pega só a parte útil** (`response.data['content']`): a API devolve uma "página"; a lista de resultados está dentro do campo `content`.
4. **Traduz cada item** (`.map(... fromJson ...)`): transforma cada JSON cru em um `BolsaFamiliaModel` organizado.
5. **Se der erro** (`catch`): em vez de quebrar o app, imprime o erro e devolve uma **lista vazia**. Assim o app não trava.

> **Conceitos novos:**
> - `Future` = "uma promessa de que o resultado vai chegar depois" (porque internet demora).
> - `async/await` = a forma de esperar essa promessa sem travar a tela.

**Resumo:** `api_services.dart` é o único que sai do app para buscar dados na internet, e devolve os dados já traduzidos em objetos.

---

## 4. `bolsa_provider.dart` — O gerente (o cérebro do app) 🧠

Este é o coração da lógica. Ele guarda o **estado** do app (a "situação atual": está carregando? quais resultados temos? qual página?) e **avisa a tela** quando algo muda.

```dart
class BolsaProvider with ChangeNotifier {
  final ApiServices _service = ApiServices();

  List<BolsaFamiliaModel> lista = [];
  bool isLoading = false;
  bool buscaRealizada = false;
  bool temMais = true;
  int paginaAtual = 0;
  FiltroBusca filtroAtual = const FiltroBusca();
```

As "variáveis de estado" (a memória do gerente):

- `lista` → os resultados atuais na tela.
- `isLoading` → está carregando? (mostra a bolinha girando).
- `buscaRealizada` → o usuário já buscou algo? (diferencia "tela inicial" de "sem resultados").
- `temMais` → ainda existem mais páginas para carregar?
- `paginaAtual` → em qual página estamos.
- `filtroAtual` → os filtros aplicados agora.

O segredo é o **`with ChangeNotifier`** e o método **`notifyListeners()`**. Pense assim: o gerente tem um sininho 🔔. Toda vez que ele toca o sininho (`notifyListeners()`), a tela escuta e se redesenha sozinha com as informações novas. Você não atualiza a tela na mão — você muda o estado e toca o sino.

### A função `novaBusca` (busca nova, do zero):

```dart
Future<void> novaBusca(FiltroBusca filtro) async {
  filtroAtual = filtro;
  paginaAtual = 0;
  lista = [];
  temMais = true;
  buscaRealizada = true;
  isLoading = true;
  notifyListeners(); // toca o sino → tela mostra "carregando"

  final resultados = await _service.getBeneficiarios(
    filtro: filtroAtual,
    pagina: paginaAtual,
  );

  lista = resultados;
  temMais = resultados.length >= ApiServices.tamanhoPagina;
  isLoading = false;
  notifyListeners(); // toca o sino → tela mostra os resultados
}
```

Repare no padrão (vai se repetir muito no Flutter):
1. Muda o estado para "carregando" e toca o sino → tela mostra a bolinha girando.
2. Espera os dados (`await`).
3. Guarda os resultados, desliga o "carregando", toca o sino de novo → tela mostra a lista.

O truque do `temMais`: se voltaram 20 itens (página cheia), provavelmente há mais; se voltaram menos de 20, chegamos ao fim.

### A função `carregarMais` (rolagem infinita):

```dart
Future<void> carregarMais() async {
  if (isLoading || !temMais || !buscaRealizada) return;

  paginaAtual++;
  isLoading = true;
  notifyListeners();

  final novosDados = await _service.getBeneficiarios(...);

  lista.addAll(novosDados); // ADICIONA no fim (não substitui)
  temMais = novosDados.length >= ApiServices.tamanhoPagina;
  isLoading = false;
  notifyListeners();
}
```

Diferença para `novaBusca`: aqui ele **soma** (`addAll`) os novos itens no fim da lista, em vez de apagar tudo. A primeira linha é uma "trava de segurança": se já está carregando, ou não tem mais páginas, ou nem buscou ainda, ele não faz nada (evita pedidos repetidos).

### A função `limpar`:

```dart
void limpar() {
  lista = [];
  filtroAtual = const FiltroBusca();
  buscaRealizada = false;
  paginaAtual = 0;
  temMais = true;
  isLoading = false;
  notifyListeners();
}
```

Reseta tudo de volta ao estado inicial (como se o app tivesse acabado de abrir).

**Resumo:** o provider é o cérebro. Ele guarda a situação atual, chama o serviço quando precisa, e toca o sino para a tela se atualizar. Ele é a **ponte** entre a tela e o serviço.

---

## 5. `page_one.dart` — A tela (o garçom que você vê) 👀

Este é o maior arquivo porque é tudo o que aparece visualmente. Mas não se assuste: ele é só uma montagem de "peças de Lego" (no Flutter, cada peça é chamada de **widget**). Vamos por partes.

### 5a. Cores e lista de UFs

```dart
class _AppColors {
  static const background    = Color(0xFF0D1117);
  static const surface       = Color(0xFF161B22);
  static const card          = Color(0xFF1C2333);
  static const accent        = Color(0xFFF78166);
  // ...
```

É só uma "caixinha de tintas". Em vez de repetir o código da cor toda hora, dá um nome a cada cor (`accent`, `background`...) e usa o nome. Se quiser mudar o visual, muda num lugar só. A `_ufs` é a lista fixa de estados (AC, AL, AP...) usada no menu suspenso.

### 5b. `PageOne` e seu estado

```dart
class PageOne extends StatefulWidget {
  const PageOne({super.key});
  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  final TextEditingController _nomeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
```

- **`StatefulWidget`** → uma tela que **pode mudar** ao longo do tempo (diferente de `StatelessWidget`, que é fixa). Como esta tela muda (digita, rola, carrega), ela é "Stateful".
- **`_nomeController`** → o "controle remoto" da caixa de texto do nome. Permite ler o que foi digitado e limpar o campo.
- **`_scrollController`** → o "controle remoto" da rolagem. Serve para saber quando o usuário chegou perto do fim da lista.

O `initState` (roda uma vez quando a tela nasce):

```dart
void initState() {
  super.initState();
  _scrollController.addListener(() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<BolsaProvider>().carregarMais();
    }
  });
}
```

Tradução: "fica de olho na rolagem; quando faltar 200 pixels para o fim da lista, peça mais resultados ao gerente". **É isso que faz a rolagem infinita funcionar.**

### 5c. As ações do usuário

São quatro funções que respondem ao que você faz:

- **`_buscarPorNome`** → quando você digita um nome e aperta buscar. Monta um filtro novo (mantendo os outros filtros que já existiam) e pede ao gerente `novaBusca`.
- **`_abrirFiltros`** → abre o painel de filtros avançados (aquele que sobe de baixo). Quando o painel fecha, recebe os filtros escolhidos e dispara a busca.
- **`_removerFiltro`** → quando você clica no "x" de uma etiqueta. Remove só aquele filtro e busca de novo (ou limpa tudo, se não sobrou nenhum).
- **`_limparTudo`** → limpa todos os campos e resultados.

> Repare em `context.read<BolsaProvider>()` — é assim que a tela "fala com o gerente". `read` = "fale com ele uma vez" (para mandar uma ação). Mais abaixo aparece `watch` = "fique escutando ele" (para redesenhar quando o sino tocar).

### 5d. O `build` — onde a tela é desenhada

```dart
Widget build(BuildContext context) {
  final provider = context.watch<BolsaProvider>();
  final filtrosAtivos = provider.filtroAtual.ativos;
```

O `build` é a função que **monta a tela**. Ela roda de novo toda vez que o gerente toca o sino (por causa do `context.watch`). A estrutura, de cima para baixo:

1. **`AppBar`** → a barra de título no topo, com o ícone e o nome "Bolsa Família".
2. **Barra de busca** → a caixa de texto do nome + o botão de filtros (`_FilterButton`).
3. **Etiquetas/chips** → só aparecem **se** houver filtros ativos (o `if (filtrosAtivos.isNotEmpty)`).
4. **Contador de resultados** → mostra "X resultado(s)".
5. **Conteúdo principal** → chama `_buildConteudo`, que decide o que mostrar.

> Conceito-chave: o `if` dentro do layout. No Flutter você pode mostrar ou esconder pedaços da tela com `if`. As etiquetas só existem na tela quando há filtros. Isso é "tela reativa": ela se adapta ao estado.

### 5e. `_buildConteudo` — os 4 estados da tela

Esta função é um exemplo lindo de "a tela muda conforme a situação". Ela decide entre 4 cenários:

```dart
Widget _buildConteudo(BolsaProvider provider) {
  // 1. Carregando pela primeira vez → mostra bolinha girando
  if (provider.isLoading && provider.lista.isEmpty) { ... }

  // 2. Nunca buscou nada → mostra "Comece sua pesquisa"
  if (!provider.buscaRealizada) { ... }

  // 3. Buscou mas não achou → mostra "Nenhum resultado encontrado"
  if (provider.lista.isEmpty) { ... }

  // 4. Tem resultados → mostra a lista (ListView)
  return ListView.builder(...);
}
```

É como um porteiro que olha a situação e decide qual cartaz pendurar. Os casos 2 e 3 usam o widget reutilizável `_EstadoVazio`.

O `ListView.builder` (caso 4) é esperto: só constrói os itens visíveis na tela (não desenha 1000 itens de uma vez, economizando memória). Repare:

```dart
itemCount: provider.lista.length + (provider.isLoading ? 1 : 0),
```

Ele soma "+1" item quando está carregando — esse item extra é a bolinha girando no rodapé, avisando que mais resultados estão chegando.

### 5f. `dispose`

```dart
void dispose() {
  _scrollController.dispose();
  _nomeController.dispose();
  super.dispose();
}
```

Quando a tela "morre", isso **devolve os recursos** dos controllers. É como apagar a luz ao sair do quarto — evita desperdício de memória. **Sempre** faça `dispose` dos controllers.

### 5g. Os widgets auxiliares

O resto do arquivo são "peças de Lego" reutilizáveis, separadas para o código não virar uma bagunça gigante:

- **`_inputDecoration`** → o "estilo padrão" das caixas de texto (borda, cor, cantos arredondados). Definido uma vez, usado em todos os campos.
- **`_FilterButton`** → o botão de filtros com o numerozinho (badge) mostrando quantos filtros estão ativos.
- **`_FiltroChip`** → cada etiqueta de filtro ativo com o "x" para remover.
- **`_EstadoVazio`** → a tela bonita de "nada aqui" (ícone + título + descrição), usada nos estados inicial e sem resultados.
- **`_FiltrosSheet`** → o **painel de filtros avançados** que sobe de baixo. É um `StatefulWidget` próprio, com seus próprios controllers para nome, NIS, município, competência, valor mín/máx e o dropdown de UF. Quando você aperta "Aplicar", ele:
  - valida (ex.: valor mínimo não pode ser maior que o máximo),
  - monta um `FiltroBusca`,
  - e "devolve" esse filtro com `Navigator.of(context).pop(filtro)` para a tela principal.
- **`_BeneficiarioCard`** → o cartão de cada resultado: a "bolinha" com a UF, o nome, o subtítulo (município · NIS · competência) e o valor em R$ formatado.

**Resumo:** `page_one.dart` é tudo o que você vê e toca. Ele lê o estado do gerente e desenha; quando você faz algo, ele avisa o gerente.

---

## O fluxo completo, do começo ao fim 🔄

Vamos juntar tudo numa história. Você busca "Maria":

1. Você digita "Maria" e aperta buscar → `page_one.dart` chama `_buscarPorNome`.
2. `_buscarPorNome` monta um `FiltroBusca` (molde) e chama `provider.novaBusca(...)`.
3. O **gerente** (`bolsa_provider.dart`) liga `isLoading = true` e toca o sino → a tela mostra a bolinha girando.
4. O gerente chama o **entregador** (`api_services.dart`).
5. O entregador monta o pedido com os filtros e faz a chamada à **API Java** pela internet.
6. A API devolve um JSON. O entregador traduz cada item para `BolsaFamiliaModel` (molde) e devolve a lista ao gerente.
7. O gerente guarda a lista, desliga `isLoading` e toca o sino de novo.
8. A tela escuta o sino, roda o `build` outra vez e mostra os cartões (`_BeneficiarioCard`).
9. Você rola até o fim → o `_scrollController` percebe e chama `carregarMais` → repete dos passos 4 ao 8, mas **somando** mais itens.

E é assim que o app inteiro funciona. 🎉

---

## Resumo final para reproduzir

A "fórmula" deste app é uma arquitetura muito comum no Flutter, chamada de separação em camadas:

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| Entrada | `main.dart` | Ligar tudo e abrir a 1ª tela |
| Model | `bolsafamilia_model.dart`, `filtro_busca.dart` | Definir o formato dos dados |
| Service | `api_services.dart` | Falar com a internet/API |
| Provider | `bolsa_provider.dart` | Guardar o estado e a lógica |
| View | `page_one.dart` | Mostrar a tela e captar toques |

**Regra de ouro:** a tela nunca fala direto com a internet. Ela sempre passa pelo gerente (provider), que passa pelo entregador (service). Isso mantém tudo organizado e fácil de consertar.

---

*Documento didático criado para ajudar iniciantes a entender e reproduzir o app Flutter do Bolsa Família.*
