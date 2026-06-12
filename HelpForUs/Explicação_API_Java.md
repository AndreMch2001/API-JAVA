# Entendendo a API Java (Spring Boot) — explicação para iniciantes

Este documento explica, de forma bem simples e didática, **o que cada arquivo Java faz** na API do Bolsa Família. A linguagem é propositalmente fácil, com comparações do dia a dia, para que mesmo quem está começando consiga entender e reproduzir.

---

## A grande ideia: a API é a "cozinha" de um restaurante 🍽️

No app Flutter, usamos a imagem de um restaurante. A **API é a cozinha** desse restaurante:

- O **app Flutter (cliente)** faz um pedido pela internet ("quero beneficiários de SP").
- A **API Java** é a cozinha que recebe o pedido, vai até a despensa (o banco de dados), pega os ingredientes certos e devolve o prato pronto (os dados em JSON).

A API tem 4 "funcionários" principais, cada um com uma função bem clara:

| Funcionário | Arquivo | O que faz |
|---|---|---|
| O porteiro que abre a cozinha | `BolsafamiliaApplication.java` | Liga a API |
| O atendente do balcão | `Bolsafamiliacontroller.java` | Recebe os pedidos pela internet |
| O molde do prato | `Bolsafamiliamodel.java` | Define o formato dos dados |
| O estoquista da despensa | `BolsafamiliaRepository.java` | Pega os dados no banco |

E ainda há a **despensa** (banco de dados PostgreSQL) e a **receita de montagem** (`pom.xml` e `application.properties`). Vamos ver cada um.

---

## 1. `BolsafamiliaApplication.java` — O interruptor que liga a API 🔌

Toda aplicação Spring Boot começa por aqui. É o equivalente ao `main.dart` do Flutter: o primeiro arquivo a rodar.

```java
@SpringBootApplication
public class BolsafamiliaApplication {
	public static void main(String[] args) {
		SpringApplication.run(BolsafamiliaApplication.class, args);
	}
}
```

O que acontece:

- **`@SpringBootApplication`** → é uma "etiqueta" (chamada de *anotação*) que avisa ao Spring: "esta é a classe principal, prepare tudo automaticamente". O Spring então sai procurando os outros funcionários (controller, repository, etc.) sozinho.
- **`public static void main(...)`** → é a porta de entrada. Quando você roda o projeto, o Java executa esta função primeiro.
- **`SpringApplication.run(...)`** → liga o servidor. A partir daqui, a API fica "de pé", esperando pedidos pela internet (por padrão, na porta 8080).

**Resumo:** este arquivo é o botão de ligar. Sozinho ele não faz nada de útil, mas sem ele nada funciona.

---

## 2. `Bolsafamiliamodel.java` — O molde dos dados (a fôrma de bolo) 🧁

Assim como no Flutter temos um "molde" para os dados, aqui também temos. A diferença é que este molde tem um poder extra: ele **representa uma tabela do banco de dados**.

```java
@Entity
@Table(name = "governo")
@Getter @Setter
public class Bolsafamiliamodel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String competencia;
    private String uf;

    @Column(name = "nome_municipio")
    private String nomeMunicipio;

    @Column(name = "nome_favorecido")
    private String nomeFavorecido;

    @Column(name = "valor_parcela")
    private BigDecimal valorParcela;

    @Column(name = "nis_favorecido")
    private String nisFavorecido;
}
```

Vamos traduzir as "etiquetas" (anotações):

- **`@Entity`** → diz: "esta classe representa uma tabela no banco de dados". Cada objeto desta classe é uma **linha** da tabela.
- **`@Table(name = "governo")`** → diz qual é o nome da tabela no banco: `governo`.
- **`@Getter @Setter`** (do Lombok) → o Lombok é um ajudante que **cria automaticamente** os métodos para ler (`getNome`) e escrever (`setNome`) os campos. Sem ele, você teria que escrever esses métodos na mão, um por um. Ele economiza muita digitação.
- **`@Id`** → marca o campo `id` como a **chave primária** (o número único que identifica cada linha, como um RG).
- **`@GeneratedValue(strategy = GenerationType.IDENTITY)`** → diz que o banco gera o `id` **automaticamente** quando uma linha nova é criada (1, 2, 3...). Você não precisa inventar o número.
- **`@Column(name = "nome_municipio")`** → quando o nome do campo em Java (`nomeMunicipio`) é diferente do nome da coluna no banco (`nome_municipio`), esta etiqueta faz a "ponte" entre os dois.

> **Detalhe importante:** repare que `valorParcela` é do tipo `BigDecimal`, não `double`. Para dinheiro, o `BigDecimal` é mais preciso e evita erros de arredondamento de centavos. É a escolha certa para valores financeiros.

**Resumo:** este arquivo é a planta da tabela `governo`. Ele diz quais colunas existem e como elas se chamam.

---

## 3. `BolsafamiliaRepository.java` — O estoquista da despensa 📦

Este é, talvez, o arquivo mais "mágico" de todos — porque ele quase não tem código, mas faz muita coisa.

```java
@Repository
public interface BolsafamiliaRepository
        extends JpaRepository<Bolsafamiliamodel, Long>,
                JpaSpecificationExecutor<Bolsafamiliamodel> {
}
```

Repare que está vazio por dentro! Como ele funciona então?

- **`@Repository`** → etiqueta que diz: "esta é a classe que conversa com o banco de dados".
- **`interface`** → é só um "contrato", uma lista de promessas. Você não escreve o código; o Spring escreve por você nos bastidores.
- **`extends JpaRepository<Bolsafamiliamodel, Long>`** → ao "herdar" do `JpaRepository`, você **ganha de graça** um monte de métodos prontos: salvar, apagar, buscar por id, listar tudo, contar, paginar... Tudo isso sem escrever uma linha. O `<Bolsafamiliamodel, Long>` diz: "trabalho com a tabela do modelo `Bolsafamiliamodel`, cujo id é do tipo `Long`".
- **`JpaSpecificationExecutor<Bolsafamiliamodel>`** → este dá o superpoder de fazer **buscas com filtros dinâmicos** (filtrar por nome, UF, valor, etc., combinando do jeito que quiser). É exatamente o que o controller usa para a busca avançada.

> Pense assim: em vez de você escrever comandos SQL (`SELECT * FROM governo WHERE ...`) na mão, o Spring "fala SQL" por você. Você só pede em Java e ele traduz.

**Resumo:** este arquivo é o estoquista que sabe entrar na despensa (banco) e pegar/guardar os dados. Você quase não escreve nada, mas ganha um exército de funções prontas.

---

## 4. `Bolsafamiliacontroller.java` — O atendente do balcão 🛎️

Este é o coração da API. É ele quem **recebe os pedidos da internet**, monta os filtros e devolve a resposta. É o arquivo mais longo, então vamos por partes.

### 4a. As etiquetas do topo

```java
@RestController
@RequestMapping("/api/Bolsafamiliamodel")
@CrossOrigin(origins = "*")
public class Bolsafamiliacontroller {

    @Autowired
    private BolsafamiliaRepository repository;
```

- **`@RestController`** → diz: "esta classe atende pedidos HTTP (internet) e devolve dados (JSON)".
- **`@RequestMapping("/api/Bolsafamiliamodel")`** → define o **endereço base**. Todo pedido começa com esse caminho.
- **`@CrossOrigin(origins = "*")`** → autoriza que **qualquer aplicativo** (como o seu app Flutter) chame esta API. Sem isso, o navegador/app poderia bloquear o pedido por segurança. O `*` significa "todos são bem-vindos".
- **`@Autowired private BolsafamiliaRepository repository;`** → aqui o Spring **entrega automaticamente** o estoquista (repository) para o atendente usar. Você não precisa criá-lo na mão; o Spring "injeta" ele pronto. Isso se chama *injeção de dependência*.

### 4b. O endereço da busca e seus parâmetros

```java
@GetMapping("/busca")
public Page<Bolsafamiliamodel> listar(
        @RequestParam(required = false) String nome,
        @RequestParam(required = false) String uf,
        @RequestParam(required = false) String nomeMunicipio,
        @RequestParam(required = false) String competencia,
        @RequestParam(required = false) String nisFavorecido,
        @RequestParam(required = false) BigDecimal valorMinimo,
        @RequestParam(required = false) BigDecimal valorMaximo,
        @RequestParam(defaultValue = "0") int pagina,
        @RequestParam(defaultValue = "20") int tamanho) {
```

- **`@GetMapping("/busca")`** → cria o endereço final: `GET /api/Bolsafamiliamodel/busca`. O `GET` significa "estou só pedindo dados, não vou alterar nada". É exatamente o endereço que o app Flutter chama.
- **`@RequestParam(required = false) String nome`** → cada um destes é um **filtro** que vem na URL (ex.: `...?nome=Maria&uf=SP`). O `required = false` significa "é opcional" — o app pode mandar ou não.
- **`@RequestParam(defaultValue = "0") int pagina`** → `pagina` e `tamanho` controlam a **paginação**. Se o app não mandar, o valor padrão é página `0` e `20` itens. (É o que faz a rolagem infinita do app funcionar!)
- **`Page<Bolsafamiliamodel>`** → o retorno não é uma lista simples, e sim uma **página**: além dos dados, vem informação extra (total de páginas, se há próxima, etc.). Por isso, no app Flutter, os dados vêm dentro do campo `content`.

### 4c. O filtro inteligente (a parte mais esperta)

Aqui está o pulo do gato. Em vez de ter uma busca fixa, o controller monta a busca **dinamicamente**, incluindo só os filtros que o usuário preencheu.

```java
Specification<Bolsafamiliamodel> spec = (root, query, cb) -> {
    List<Predicate> predicates = new ArrayList<>();

    if (nome != null && !nome.isEmpty()) {
        predicates.add(cb.like(cb.lower(root.get("nomeFavorecido")), "%" + nome.toLowerCase() + "%"));
    }
    if (uf != null && !uf.isEmpty()) {
        predicates.add(cb.equal(cb.upper(root.get("uf")), uf.toUpperCase()));
    }
    // ... e assim por diante para município, competência, NIS, valor mín. e máx.

    return cb.and(predicates.toArray(new Predicate[0]));
};

return repository.findAll(spec, PageRequest.of(pagina, tamanho));
```

Vamos traduzir em português comum:

- **`Specification`** → pense nisso como uma **lista de regras** ("a receita do filtro") que será montada na hora.
- **`List<Predicate> predicates`** → uma lista vazia onde vamos jogando cada regrinha (cada `Predicate` é uma condição, tipo "nome parecido com Maria").
- **Os `if`** → para cada filtro, ele verifica: "o usuário mandou isso? Se sim, adiciono a regra; se não, ignoro". Por isso a busca é flexível: você pode filtrar só por nome, só por UF, ou por vários ao mesmo tempo.
- **`cb.like(...)`** → cria uma busca "parecida com" (ex.: digitar "mar" encontra "Maria", "Marcos"). É traduzido para `LIKE '%mar%'` no SQL.
- **`cb.lower(...)` / `cb.upper(...)`** → deixa tudo em minúsculo (ou maiúsculo) antes de comparar, para que "sp", "SP" e "Sp" sejam tratados igual (busca *case-insensitive*).
- **`cb.equal(...)`** → busca exata (ex.: o NIS tem que ser idêntico).
- **`cb.greaterThanOrEqualTo` / `lessThanOrEqualTo`** → comparações de valor (maior/menor ou igual), usadas no filtro de faixa de valor.
- **`cb.and(...)`** → junta todas as regrinhas com "E" (AND). Ou seja: o resultado tem que satisfazer **todas** ao mesmo tempo.
- **`repository.findAll(spec, PageRequest.of(pagina, tamanho))`** → finalmente entrega a receita de filtros + a paginação para o **estoquista**, que vai ao banco e traz os resultados.

> **A grande sacada:** este código nunca muda, mas a busca que ele gera muda conforme o que o usuário preenche. Um filtro vazio simplesmente não entra na lista de regras. Isso é o que torna a busca "escalável" — dá para adicionar novos filtros facilmente.

**Resumo:** o controller é o atendente que recebe o pedido pela internet, monta o filtro só com o que foi pedido, manda o estoquista buscar e devolve a página de resultados.

---

## 5. Os arquivos de configuração (a receita de montagem) 📋

Estes não são código de lógica, mas dizem **como o projeto é montado e configurado**.

### 5a. `pom.xml` — A lista de compras (dependências)

O Maven usa o `pom.xml` para saber **quais ferramentas baixar** da internet. É como uma lista de ingredientes:

- **spring-boot-starter-web** → permite a API receber pedidos HTTP (o balcão de atendimento).
- **spring-boot-starter-data-jpa** → permite conversar com o banco de dados de forma fácil (o JPA/Hibernate).
- **postgresql** → o "tradutor" específico para o banco PostgreSQL.
- **lombok** → o ajudante que cria getters/setters automaticamente.
- **starters de teste** → ferramentas para testar o projeto.

### 5b. `application.properties` — As chaves da despensa

Este arquivo guarda as **configurações**, principalmente o endereço, usuário e senha do banco de dados. É como a chave e o endereço da despensa. Pontos importantes:

- O endereço do banco (URL JDBC), usuário e senha ficam aqui.
- `spring.jpa.hibernate.ddl-auto=validate` → só **confere** se a tabela existe e bate com o modelo; não altera o banco sozinho (mais seguro).
- `spring.jpa.show-sql=true` → mostra no terminal o SQL que está sendo executado (ótimo para aprender e depurar).

> **Cuidado de segurança:** senhas de banco não devem ir para o GitHub. Em projetos reais, usa-se variáveis de ambiente (parecido com o `.env` do app Flutter).

---

## 6. `BolsafamiliaApplicationTests.java` — O teste de "será que liga?" ✅

```java
@SpringBootTest
class BolsafamiliaApplicationTests {
	@Test
	void contextLoads() {
	}
}
```

- **`@SpringBootTest`** → prepara a aplicação inteira para um teste.
- **`@Test void contextLoads()`** → este teste, mesmo vazio, verifica uma coisa importantíssima: "a aplicação consegue **iniciar** sem erros?". Se houver algo errado na configuração, este teste falha. É um "checkup" básico de saúde.

---

## O fluxo completo, do início ao fim 🔄

Vamos juntar tudo numa história. O app Flutter busca beneficiários de "SP":

1. O app faz um pedido: `GET /api/Bolsafamiliamodel/busca?uf=SP&pagina=0&tamanho=20`.
2. O **atendente** (`Bolsafamiliacontroller`) recebe o pedido e lê os parâmetros (`uf = SP`, `pagina = 0`...).
3. Ele monta a `Specification`: como só veio `uf`, a única regra é "uf = SP".
4. Ele entrega essa regra + paginação ao **estoquista** (`repository.findAll`).
5. O estoquista, com a ajuda do JPA, traduz tudo para SQL e busca na tabela `governo` (a despensa).
6. O banco devolve as linhas; cada linha vira um objeto **`Bolsafamiliamodel`** (o molde).
7. O Spring transforma esses objetos em **JSON** e devolve uma `Page` (com os dados em `content`).
8. O app Flutter recebe o JSON, traduz para os seus próprios modelos e mostra na tela.

E é assim que a cozinha (API) atende os pedidos do salão (app)! 🎉

---

## Resumo final para reproduzir

A API segue uma arquitetura em camadas muito comum no Spring Boot:

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| Inicialização | `BolsafamiliaApplication.java` | Ligar a API |
| Controller | `Bolsafamiliacontroller.java` | Receber pedidos HTTP e montar filtros |
| Repository | `BolsafamiliaRepository.java` | Conversar com o banco de dados |
| Model (Entidade) | `Bolsafamiliamodel.java` | Representar a tabela `governo` |
| Configuração | `pom.xml`, `application.properties` | Dependências e conexão com o banco |
| Teste | `BolsafamiliaApplicationTests.java` | Verificar se a API inicia |

**Regra de ouro:** o pedido sempre flui na ordem **Controller → Repository → Banco**, e a resposta volta no caminho inverso. O controller nunca fala direto com o SQL; ele sempre passa pelo repository. Isso mantém o código organizado e fácil de manter.

---

*Documento didático criado para ajudar iniciantes a entender e reproduzir a API Java do Bolsa Família.*
