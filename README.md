<div align="center">

# 💸 Bolsa Família — API + App

### Plataforma full-stack para consulta de beneficiários do programa Bolsa Família

API REST em **Java / Spring Boot** + aplicativo móvel em **Flutter**, com busca avançada, filtros dinâmicos e paginação infinita.

<br/>

![Java](https://img.shields.io/badge/Java-21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-4-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.10-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-DB-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow?style=flat-square)
![Licença](https://img.shields.io/badge/licença-acadêmica-blue?style=flat-square)
![Plataforma](https://img.shields.io/badge/plataforma-Android-3DDC84?style=flat-square&logo=android&logoColor=white)

</div>

---

## 📋 Índice

- [Sobre o projeto](#-sobre-o-projeto)
- [Arquitetura](#-arquitetura)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias](#-tecnologias)
- [Demonstração](#-demonstração)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Pré-requisitos](#-pré-requisitos)
- [Como executar](#-como-executar)
- [Documentação da API](#-documentação-da-api)
- [Modelo de dados](#-modelo-de-dados)
- [Documentação didática](#-documentação-didática)
- [Autores](#-autores)
- [Licença](#-licença)

---

## 📖 Sobre o projeto

O **Bolsa Família** é uma aplicação full-stack desenvolvida como trabalho acadêmico (ADS) que permite **consultar beneficiários** do programa social a partir de uma base de dados pública.

O sistema é dividido em dois componentes que conversam entre si:

| Componente | Descrição |
|------------|-----------|
| 🟢 **`bolsafamilia`** | API REST em Java com Spring Boot, JPA e PostgreSQL. Expõe um endpoint de busca com **filtros dinâmicos** e **paginação**. |
| 🔵 **`bolsafamilia_app`** | App Flutter (Android) com interface moderna (tema *dark*), que consome a API e permite filtrar por nome, UF, município, competência, NIS e faixa de valor. |

---

## 🏗 Arquitetura

```text
┌─────────────────────────┐        HTTP GET (JSON)        ┌──────────────────────────┐
│   bolsafamilia_app      │  ─────────────────────────►   │   bolsafamilia (API)     │
│   (Flutter / Dart)      │   /api/Bolsafamiliamodel/     │   (Spring Boot / Java)   │
│                         │   busca?uf=SP&pagina=0...      │                          │
│   • Provider (estado)   │  ◄─────────────────────────   │   • Controller           │
│   • Dio (HTTP)          │        Page<JSON>             │   • Repository (JPA)     │
└─────────────────────────┘                               └────────────┬─────────────┘
                                                                        │
                                                                        ▼
                                                            ┌──────────────────────────┐
                                                            │       PostgreSQL         │
                                                            │     (tabela: governo)    │
                                                            └──────────────────────────┘
```

A aplicação segue uma **arquitetura em camadas** em ambos os lados:

- **API:** `Controller` → `Repository` → `Banco de dados`
- **App:** `View` → `Provider` → `Service` → `API`

> A camada de tela nunca fala direto com o banco/internet — sempre passa pelas camadas intermediárias, mantendo o código organizado e testável.

---

## ✨ Funcionalidades

### 🟢 API (Java / Spring Boot)

- 🔍 Busca de beneficiários com **filtros combináveis** (todos opcionais):
  - Nome do favorecido *(busca parcial, ignora maiúsculas/minúsculas)*
  - UF, Município, Competência e NIS
  - Faixa de valor da parcela (mínimo e máximo)
- 📄 **Paginação** configurável (`pagina`, `tamanho`)
- 🔗 Filtros dinâmicos via **JPA Specification** (só aplica o que foi enviado)
- 🌐 **CORS** habilitado para consumo pelo app

### 🔵 App (Flutter)

- ⚡ **Busca rápida** por nome direto na barra superior
- 🎛 **Painel de filtros avançados** (UF via dropdown, faixa de valor, etc.) com validação
- 🏷 **Chips de filtros ativos** — remova filtros individualmente com um toque
- ♾ **Paginação infinita** — carrega mais resultados automaticamente ao rolar
- 🎨 **Interface moderna** com tema *GitHub Dark* e acentos em laranja
- 🧭 **Estados visuais claros**: carregando, tela inicial, sem resultados e lista
- 🔐 URL da API gerenciada via **arquivo `.env`** (não fica fixa no código)

---

## 🛠 Tecnologias

<div align="center">

| Camada | Stack |
|--------|-------|
| **Back-end** | Java 21 · Spring Boot 4 · Spring Data JPA · Hibernate · Lombok · Maven |
| **Banco** | PostgreSQL |
| **Front-end** | Flutter · Dart 3.10 · Provider · Dio · flutter_dotenv |

</div>

---

## 📱 Demonstração

> 💡 Adicione aqui capturas de tela ou um GIF do app em funcionamento para deixar o repositório ainda mais atraente.

<div align="center">

| Tela inicial | Resultados | Filtros avançados |
|:---:|:---:|:---:|
| _(screenshot)_ | _(screenshot)_ | _(screenshot)_ |

</div>

<details>
<summary>📸 Como adicionar suas capturas de tela</summary>

1. Crie uma pasta `docs/screenshots/` na raiz do repositório.
2. Salve suas imagens (ex.: `home.png`, `resultados.png`, `filtros.png`).
3. Substitua os `_(screenshot)_` acima por: `![Tela inicial](docs/screenshots/home.png)`

</details>

---

## 📂 Estrutura do repositório

```text
ProjetoA3/
├── bolsafamilia/                      # 🟢 API Java (Spring Boot)
│   ├── src/main/java/com/projeto/bolsafamilia/
│   │   ├── BolsafamiliaApplication.java   # Ponto de entrada
│   │   ├── controller/                    # Bolsafamiliacontroller (endpoints REST)
│   │   ├── model/                         # Bolsafamiliamodel (entidade JPA)
│   │   └── repository/                    # BolsafamiliaRepository (acesso a dados)
│   ├── src/main/resources/
│   │   └── application.properties         # Configuração (banco, JPA)
│   └── pom.xml                            # Dependências Maven
│
├── bolsafamilia_app/                  # 🔵 App Flutter
│   ├── lib/
│   │   ├── main.dart                      # Ponto de entrada + Provider
│   │   ├── models/                        # bolsafamilia_model, filtro_busca
│   │   ├── providers/                     # bolsa_provider (estado + lógica)
│   │   ├── services/                      # api_services (Dio)
│   │   └── views/                         # page_one (tela de busca)
│   ├── .env                               # URL da API (não versionar valores reais)
│   └── pubspec.yaml                       # Dependências Flutter
│
├── HelpForUs/                         # 📚 Documentação didática do projeto
└── README.md                          # Este arquivo
```

---

## ✅ Pré-requisitos

- **Java 21** e **Maven** (a API já inclui o wrapper `mvnw`)
- **PostgreSQL** com a tabela `governo` populada
- **Flutter SDK** (Dart ≥ 3.10)
- **Android Studio** ou **VS Code** + emulador/dispositivo Android

---

## 🚀 Como executar

### 1️⃣ Banco de dados

Crie um banco PostgreSQL e a tabela `governo` com as colunas: `id`, `competencia`, `uf`, `nome_municipio`, `nome_favorecido`, `valor_parcela`, `nis_favorecido`.

### 2️⃣ API (`bolsafamilia`)

Configure suas credenciais do banco. O projeto já importa, de forma opcional, um arquivo de configuração **local** — ideal para manter senhas fora do controle de versão:

```properties
# bolsafamilia/src/main/resources/application-local.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/postgres
spring.datasource.username=SEU_USUARIO
spring.datasource.password=SUA_SENHA
```

Em seguida, rode a API:

```bash
cd bolsafamilia
./mvnw spring-boot:run
```

A API sobe em **http://localhost:8080**.

> ⚠️ **Segurança:** evite versionar senhas reais em `application.properties`. Prefira `application-local.properties` (já ignorado pelo import opcional) ou variáveis de ambiente.

### 3️⃣ App (`bolsafamilia_app`)

Configure a URL da API no arquivo `.env`. Em emulador/dispositivo Android, **use o IP da sua máquina** na rede local (não `localhost`):

```env
# bolsafamilia_app/.env
_url=http://192.168.x.x:8080/api/Bolsafamiliamodel/busca
```

Depois, instale as dependências e rode:

```bash
cd bolsafamilia_app
flutter pub get
flutter run
```

---

## 🔌 Documentação da API

### `GET /api/Bolsafamiliamodel/busca`

Retorna uma página de beneficiários. **Todos os parâmetros são opcionais.**

| Parâmetro       | Tipo    | Descrição                                   |
|-----------------|---------|---------------------------------------------|
| `nome`          | string  | Nome do favorecido (busca parcial / `LIKE`) |
| `uf`            | string  | Sigla da UF (ex.: `SP`)                     |
| `nomeMunicipio` | string  | Nome do município (busca parcial / `LIKE`)  |
| `competencia`   | string  | Competência no formato `AAAAMM` (ex.: `202401`) |
| `nisFavorecido` | string  | NIS do favorecido (igualdade exata)         |
| `valorMinimo`   | number  | Valor mínimo da parcela (`>=`)              |
| `valorMaximo`   | number  | Valor máximo da parcela (`<=`)              |
| `pagina`        | int     | Número da página (padrão: `0`)              |
| `tamanho`       | int     | Itens por página (padrão: `20`)             |

**Exemplo de requisição:**

```http
GET /api/Bolsafamiliamodel/busca?uf=SP&valorMinimo=100&pagina=0&tamanho=20
```

**Exemplo de resposta (resumida):**

```json
{
  "content": [
    {
      "id": 1,
      "competencia": "202401",
      "uf": "SP",
      "nomeMunicipio": "São Paulo",
      "nomeFavorecido": "Maria da Silva",
      "valorParcela": 600.00,
      "nisFavorecido": "12345678901"
    }
  ],
  "totalElements": 1,
  "totalPages": 1,
  "number": 0,
  "size": 20
}
```

---

## 🗃 Modelo de dados

Entidade `Bolsafamiliamodel`, mapeada para a tabela **`governo`**:

| Campo (Java)     | Coluna (DB)       | Tipo         |
|------------------|-------------------|--------------|
| `id`             | `id` (PK)         | `Long`       |
| `competencia`    | `competencia`     | `String`     |
| `uf`             | `uf`              | `String`     |
| `nomeMunicipio`  | `nome_municipio`  | `String`     |
| `nomeFavorecido` | `nome_favorecido` | `String`     |
| `valorParcela`   | `valor_parcela`   | `BigDecimal` |
| `nisFavorecido`  | `nis_favorecido`  | `String`     |

---

## 📚 Documentação didática

Na pasta [`HelpForUs/`](HelpForUs/) há explicações **passo a passo e para iniciantes** de todo o código:

- 📄 **`Explicação_API_Java.md`** — como funciona cada arquivo da API Java
- 📄 **`Explicação_App_Flutter.md`** — como funciona cada arquivo `.dart` do app
- 📄 **`ContextoGeral.md`** e **`ContextoAPI.md`** — documentos de referência técnica

---

## 👥 Autores

Projeto desenvolvido como trabalho de final de semestre do curso de **Análise e Desenvolvimento de Sistemas (ADS)**.

> 💡 @AndreMch2001

---

## 📄 Licença

Projeto de uso **acadêmico**, desenvolvido como trabalho de final de semestre da faculdade de ADS. Sinta-se à vontade para estudar e adaptar.
