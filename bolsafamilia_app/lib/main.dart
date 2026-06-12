import 'package:flutter/material.dart'; // Importa os widgets base do Flutter.
import 'package:provider/provider.dart'; // Importa o Provider para injeção de estado global.
import 'providers/bolsa_provider.dart'; // Importa o provider principal da busca.
import 'views/page_one.dart'; // Importa a tela inicial do aplicativo.
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa leitura de variáveis de ambiente.

void main() async {
  await dotenv.load(fileName: ".env"); // Carrega variáveis do arquivo .env antes de iniciar o app.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BolsaProvider()), // Disponibiliza o provider para toda a árvore de widgets.
      ],
      child: const MyApp(), // Widget raiz da aplicação.
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Construtor padrão do app.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a faixa de debug da UI.
      theme: ThemeData(primarySwatch: Colors.blue), // Define tema base com paleta azul.
      home: const PageOne(), // Define a primeira tela exibida ao usuário.
    );
  }
}