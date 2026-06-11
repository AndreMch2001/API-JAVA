# Documentação didática: `page_one.dart`

Este arquivo explica o código da tela de busca do app Bolsa Família após a refatoração visual com tema **GitHub Dark** e acentos **laranja**. Além da funcionalidade de **scroll infinito**, o código agora possui uma paleta de cores centralizada, um helper de estilo de inputs e um widget separado para os cards da lista.

---

## Índice

1. [Imports](#1-imports-linhas-1-4)
2. [Classe `_AppColors` — paleta de cores](#2-classe-_appcolors-linhas-6-16)
3. [Classe `PageOne` (StatefulWidget)](#3-classe-pageone-linhas-18-23)
4. [Classe `_PageOneState` e variáveis](#4-classe-_pageonestate-e-variáveis-linhas-25-29)
5. [initState e scroll infinito](#5-initstate-e-scroll-infinito-linhas-31-40)
6. [Helper `_inputDecoration`](#6-helper-_inputdecoration-linhas-42-58)
7. [Método `build`](#7-método-build-linhas-60-218)
8. [dispose](#8-dispose-linhas-220-225)
9. [Widget `_BeneficiarioCard`](#9-widget-_beneficiariocard-linhas-228-310)

---

## 1. Imports (linhas 1-4)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bolsa_provider.dart';
import '../models/buscas.dart';
```

| Linha | Código | Explicação |
|-------|--------|------------|
| 1 | `import 'package:flutter/material.dart';` | Importa os widgets de interface do Flutter (botões, textos, listas, cores, gradientes, etc.). |
| 2 | `import 'package:provider/provider.dart';` | Importa o Provider para observar dados e reconstruir a tela quando a lista ou o loading mudam. |
| 3 | `import '../providers/bolsa_provider.dart';` | Importa o `BolsaProvider`, que guarda a lista de resultados e expõe os métodos `novaBusca` e `carregarMais`. |
| 4 | `import '../models/buscas.dart';` | Importa o enum `GetBuscas` (Nome, Município, NIS) usado no dropdown de tipo de busca. |

---

## 2. Classe `_AppColors` (linhas 6-16)

```dart
class _AppColors {
  static const background    = Color(0xFF0D1117);
  static const surface       = Color(0xFF161B22);
  static const card          = Color(0xFF1C2333);
  static const accent        = Color(0xFFF78166);
  static const accentDark    = Color(0xFFBF3600);
  static const accentMuted   = Color(0xFF3D1A0A);
  static const textPrimary   = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const border        = Color(0xFF30363D);
}
```

Classe auxiliar **privada** (o `_` impede uso fora do arquivo) que centraliza toda a paleta de cores do tema GitHub Dark com acentos laranja. Usar uma classe de constantes evita "números mágicos" espalhados pelo código — se uma cor precisar mudar, basta alterar aqui.

| Constante | Hex | Onde é usada |
|-----------|-----|-------------|
| `background` | `#0D1117` | Fundo do `Scaffold` |
| `surface` | `#161B22` | Preenchimento dos inputs (campo de texto e dropdown) |
| `card` | `#1C2333` | Cor de fundo do container de busca e dos cards da lista |
| `accent` | `#F78166` | Laranja principal: ícone da AppBar, borda de foco, botão de busca, avatar UF, badge de valor |
| `accentDark` | `#BF3600` | Laranja escuro: segundo tom dos gradientes |
| `accentMuted` | `#3D1A0A` | Laranja muito escuro e opaco: fundo do badge de valor |
| `textPrimary` | `#E6EDF3` | Texto de destaque: título da AppBar, nome do beneficiário |
| `textSecondary` | `#8B949E` | Texto secundário: labels, município/NIS, contador |
| `border` | `#30363D` | Bordas de containers, inputs e separador da AppBar |

> **`static const`**: `static` significa que a propriedade pertence à **classe**, não a uma instância — pode ser acessada como `_AppColors.accent` sem criar um objeto. `const` garante que o valor é resolvido em tempo de compilação, tornando o acesso mais rápido e sem alocação de memória em tempo de execução.

---

## 3. Classe `PageOne` (linhas 18-23)

```dart
class PageOne extends StatefulWidget {
  @override
  _PageOneState createState() => _PageOneState();
}
```

| Linha | Código | Explicação |
|-------|--------|------------|
| 18 | `class PageOne extends StatefulWidget {` | Define a tela como um **StatefulWidget**: um widget que pode mudar ao longo do tempo (texto digitado, tipo de busca selecionado, lista de resultados). |
| 20 | `@override` | Indica que o método abaixo sobrescreve um método da classe pai (`StatefulWidget`). |
| 21 | `_PageOneState createState() => _PageOneState();` | Método obrigatório: cria o objeto de **estado** onde ficam os controladores e toda a lógica da tela. |

---

## 4. Classe `_PageOneState` e variáveis (linhas 25-29)

```dart
class _PageOneState extends State<PageOne> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GetBuscas _tipoBuscaSelecionado = GetBuscas.nomeFavorecido;
```

| Linha | Código | Explicação |
|-------|--------|------------|
| 25 | `class _PageOneState extends State<PageOne> {` | Classe do **estado** da tela. O `_` a torna privada a este arquivo. |
| 26 | `final TextEditingController _textController` | Controlador do campo de texto: permite ler (`_textController.text`) e limpar o que o usuário digitou. |
| 27 | `final ScrollController _scrollController` | Controlador da lista: usado para monitorar a posição do scroll e implementar o **scroll infinito**. |
| 29 | `GetBuscas _tipoBuscaSelecionado` | Guarda o tipo de busca atual (Nome, Município ou NIS). Valor inicial: Nome do Favorecido. |

---

## 5. initState e scroll infinito (linhas 31-40)

```dart
@override
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

| Linha | Código | Explicação |
|-------|--------|------------|
| 31 | `@override` | Sobrescreve o `initState` da classe pai. |
| 32 | `void initState() {` | Executado **uma vez** quando a tela é criada. Ideal para registrar listeners e fazer setup inicial. |
| 33 | `super.initState();` | Chama o `initState` do Flutter — obrigatório antes de qualquer outra lógica. |
| 34 | `_scrollController.addListener(() {` | Registra uma função que é chamada toda vez que o usuário rola a lista. |
| 35 | `final pos = _scrollController.position;` | Captura a posição atual do scroll: `pos.pixels` = quanto já rolou; `pos.maxScrollExtent` = o máximo possível. |
| 36 | `if (pos.pixels >= pos.maxScrollExtent - 200) {` | Se restam 200px ou menos para o fim da lista, entra no `if` — antecipa o carregamento antes de chegar no fim. |
| 37 | `context.read<BolsaProvider>().carregarMais();` | Chama `carregarMais()` no provider, que busca a próxima página na API e adiciona itens à `lista`. `read` é usado (não `watch`) pois só queremos executar a ação, não reconstruir a tela neste ponto. |

**Resumo do scroll infinito:** ao rolar e atingir os últimos 200px, `carregarMais()` é chamado → o provider busca a próxima página → `notifyListeners()` → `build` é rechamado → novos itens aparecem na lista.

---

## 6. Helper `_inputDecoration` (linhas 42-58)

```dart
InputDecoration _inputDecoration({required String label, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _AppColors.textSecondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: _AppColors.surface,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AppColors.accent, width: 2),
    ),
  );
}
```

Método auxiliar privado que retorna um `InputDecoration` padronizado. É reutilizado tanto no `DropdownButtonFormField` quanto no `TextField`, evitando repetição de código.

| Propriedade | Valor | Efeito visual |
|-------------|-------|---------------|
| `labelText` | parâmetro `label` | Texto flutuante acima do campo |
| `labelStyle` | `textSecondary` | Label em cinza suave |
| `suffixIcon` | parâmetro `suffix` | Widget opcional no lado direito (ex.: botão de busca) |
| `filled: true` + `fillColor` | `surface` (`#161B22`) | Fundo escuro preenchido dentro do campo |
| `enabledBorder` | borda `border` + raio 12 | Borda arredondada cinza quando o campo não está focado |
| `focusedBorder` | borda `accent` (laranja), espessura 2 | Borda laranja quando o usuário clica no campo |

---

## 7. Método `build` (linhas 60-218)

### 7.1 Estrutura base — Scaffold e AppBar (linhas 60-97)

```dart
@override
Widget build(BuildContext context) {
  final provider = context.watch<BolsaProvider>();

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
      title: Row(
        children: [
          Icon(Icons.savings_outlined, color: _AppColors.accent, size: 22),
          SizedBox(width: 8),
          Text("Bolsa Família", style: TextStyle(...)),
        ],
      ),
    ),
```

| Linha | Código | Explicação |
|-------|--------|------------|
| 62 | `context.watch<BolsaProvider>()` | Observa o provider: toda vez que `notifyListeners()` for chamado (nova busca, mais itens, loading), o `build` roda novamente. |
| 65 | `backgroundColor: _AppColors.background` | Fundo da tela inteira em `#0D1117`. |
| 67-75 | `flexibleSpace: Container(gradient: ...)` | Preenche o fundo da AppBar com um **gradiente** diagonal do card-escuro até o background. Isso cria profundidade visual. |
| 76 | `backgroundColor: Colors.transparent` | Necessário para que o `flexibleSpace` seja visível — sem isso a cor sólida da AppBar cobriria o gradiente. |
| 77 | `elevation: 0` | Remove a sombra padrão da AppBar. |
| 78-81 | `bottom: PreferredSize(...)` | Adiciona uma linha separadora de 1px na base da AppBar, usando a cor `border`, imitando o estilo GitHub. |
| 82-96 | `title: Row(Icon + Text)` | Título composto: ícone laranja `savings_outlined` + texto "Bolsa Família" em branco com `letterSpacing`. |

### 7.2 Container da barra de busca (linhas 101-171)

```dart
Container(
  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: _AppColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _AppColors.border),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: Offset(0, 4))],
  ),
  child: Row(...)
)
```

A área de busca não é mais um simples `Padding` — é um `Container` com estilo de **card elevado**:

| Propriedade | Efeito |
|-------------|--------|
| `color: card` | Fundo ligeiramente mais claro que o background, criando separação visual |
| `borderRadius: 16` | Cantos arredondados |
| `border` | Borda sutil em `#30363D` |
| `boxShadow` | Sombra preta com blur 10 e deslocamento Y+4 — efeito de "flutuação" |

Dentro do `Row`, os dois campos continuam com `Expanded(flex: 2)` para o dropdown e `Expanded(flex: 3)` para o `TextField`, mantendo a proporção 2:3 de largura.

**Dropdown (`DropdownButtonFormField`):**

| Propriedade | Valor | Efeito |
|-------------|-------|--------|
| `dropdownColor` | `surface` | Menu suspenso com fundo escuro |
| `style` | `textPrimary` | Texto branco no item selecionado |
| `iconEnabledColor` | `accent` | Seta do dropdown em laranja |
| `decoration` | `_inputDecoration(...)` | Estilo padronizado (borda, preenchimento, foco laranja) |

**TextField:**

| Propriedade | Valor | Efeito |
|-------------|-------|--------|
| `style` | `textPrimary` | Texto digitado em branco |
| `cursorColor` | `accent` | Cursor laranja piscante |
| `decoration.suffixIcon` | `Container` com gradiente | Botão de busca com fundo em gradiente laranja → laranja-escuro |

### 7.3 Contador de resultados (linhas 173-191)

```dart
if (provider.lista.isNotEmpty)
  Padding(
    child: Row(
      children: [
        Icon(Icons.people_alt_outlined, color: textSecondary),
        Text("${provider.lista.length} resultado(s) encontrado(s)")
      ],
    ),
  )
```

Linha condicional que aparece somente quando há itens na lista. Exibe um ícone de pessoas e a contagem em texto cinza suave — feedback discreto para o usuário saber quantos registros foram carregados.

### 7.4 Lista de resultados (linhas 193-214)

```dart
Expanded(
  child: ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    itemCount: provider.lista.length + (provider.isLoading ? 1 : 0),
    itemBuilder: (context, index) {
      if (index < provider.lista.length) {
        return _BeneficiarioCard(item: provider.lista[index]);
      }
      return Padding(
        child: Center(child: CircularProgressIndicator(color: _AppColors.accent)),
      );
    },
  ),
)
```

| Linha | Código | Explicação |
|-------|--------|------------|
| `Expanded` | — | Faz a lista ocupar todo o espaço restante da tela abaixo da barra de busca. |
| `controller: _scrollController` | — | Liga a lista ao controller do `initState`, permitindo o scroll infinito. |
| `itemCount: lista.length + (isLoading ? 1 : 0)` | — | Quando `isLoading` é `true`, adiciona 1 item extra no fim — que será o indicador de loading. |
| `_BeneficiarioCard(item: ...)` | — | Delega a construção visual de cada item ao widget `_BeneficiarioCard` (ver seção 9). |
| `CircularProgressIndicator(color: accent)` | — | Spinner laranja centralizado, exibido no último slot quando está carregando mais itens. |

---

## 8. dispose (linhas 220-225)

```dart
@override
void dispose() {
  _scrollController.dispose();
  _textController.dispose();
  super.dispose();
}
```

| Linha | Código | Explicação |
|-------|--------|------------|
| `_scrollController.dispose()` | — | Libera o `ScrollController` e desregistra o listener de scroll infinito, evitando chamadas após a tela ser destruída. |
| `_textController.dispose()` | — | Libera o `TextEditingController`. Agora **também presente** (estava faltando na versão anterior). |
| `super.dispose()` | — | Chama o `dispose` da classe pai — sempre deve ser a última linha. |

---

## 9. Widget `_BeneficiarioCard` (linhas 228-310)

```dart
class _BeneficiarioCard extends StatelessWidget {
  final dynamic item;

  const _BeneficiarioCard({required this.item});

  @override
  Widget build(BuildContext context) { ... }
}
```

Widget auxiliar **privado** e **stateless** (sem estado, pois apenas exibe dados) que encapsula a aparência de cada item da lista. Separá-lo em uma classe própria mantém o `build` principal mais limpo e legível.

**Estrutura do card:**

```
Container (card com sombra e borda)
└── ListTile
    ├── leading → Container com gradiente (avatar UF)
    ├── title   → Text (nome do beneficiário)
    ├── subtitle → Text (município · NIS)
    └── trailing → Container (badge do valor)
```

| Elemento | Estilo | Efeito |
|----------|--------|--------|
| `Container` externo | `color: card`, `borderRadius: 14`, `border`, `boxShadow` | Card escuro com borda sutil e sombra leve |
| `leading` — avatar UF | `gradient: accent → accentDark`, `borderRadius: 12` | Quadrado com cantos arredondados em gradiente laranja |
| `title` | `color: textPrimary`, `fontWeight: w600` | Nome em branco semi-negrito |
| `subtitle` | `color: textSecondary`, `fontSize: 12` | Município e NIS em cinza suave, separados por `·` |
| `trailing` — badge valor | `color: accentMuted`, `border: accent 0.45` | Badge laranja-escuro translúcido com borda laranja, texto laranja negrito |

> **Por que `StatelessWidget`?** O card não precisa controlar nenhum estado interno — só recebe `item` e exibe seus dados. Usar `StatelessWidget` é mais eficiente que `StatefulWidget` nesse caso.

---

## Resumo das mudanças em relação à versão anterior

| O que mudou | Antes | Depois |
|-------------|-------|--------|
| Cores | Hardcoded (`Color.fromARGB`, `Colors.black`) | Centralizadas em `_AppColors` |
| AppBar | Cor sólida preta | Gradiente diagonal + separador de 1px + ícone |
| Barra de busca | `Padding` simples | `Container` com sombra, borda e cor de card |
| Inputs | Borda simples `OutlineInputBorder` | Helper `_inputDecoration` com foco laranja e fundo preenchido |
| Botão de busca | `IconButton` simples | `Container` com gradiente laranja + `IconButton` branco |
| Itens da lista | `ListTile` direto | `_BeneficiarioCard` (widget separado) com card estilizado |
| Avatar UF | `CircleAvatar` | `Container` quadrado com gradiente laranja |
| Badge de valor | `Text` simples | `Container` com fundo `accentMuted` e borda laranja |
| Loading | `CircularProgressIndicator` padrão | Spinner laranja com `strokeWidth: 2.5` |
| Contador | Não existia | Row condicional com ícone e contagem |
| `dispose` | Só `_scrollController` | Ambos `_scrollController` e `_textController` |

---

*Documento atualizado para refletir a refatoração visual com tema GitHub Dark + laranja.*
