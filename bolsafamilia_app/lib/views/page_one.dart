import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bolsa_provider.dart';
import '../models/buscas.dart';

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

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GetBuscas _tipoBuscaSelecionado = GetBuscas.nomeFavorecido;

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
        title: const Row(
          children:[
            Icon(Icons.savings_outlined, color: _AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text(
              "Bolsa Família",
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<GetBuscas>(
                    initialValue: _tipoBuscaSelecionado,
                    dropdownColor: _AppColors.surface,
                    style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: _AppColors.accent,
                    decoration: _inputDecoration(label: "Tipo de Busca"),
                    items: GetBuscas.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.label),
                      );
                    }).toList(),
                    onChanged: (novoGetBusca) {
                      if (novoGetBusca != null) {
                        setState(() => _tipoBuscaSelecionado = novoGetBusca);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
                    cursorColor: _AppColors.accent,
                    decoration: _inputDecoration(
                      label: "Escreva aqui...",
                      suffix: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_AppColors.accent, _AppColors.accentDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white, size: 20),
                          onPressed: () => provider.novaBusca(
                            _textController.text,
                            _tipoBuscaSelecionado,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contador de resultados
          if (provider.lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 14, color: _AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    "${provider.lista.length} resultado(s) encontrado(s)",
                    style: const TextStyle(
                      color: _AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de resultados
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: provider.lista.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < provider.lista.length) {
                  return _BeneficiarioCard(item: provider.lista[index]);
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _AppColors.accent,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

class _BeneficiarioCard extends StatelessWidget {
  final dynamic item;

  const _BeneficiarioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_AppColors.accent, _AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              item.uf ?? "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          item.nomeFavorecido ?? "",
          style: const TextStyle(
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            "${item.nomeMunicipio ?? ""} · NIS: ${item.nisFavorecido ?? ""}",
            style: const TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _AppColors.accentMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _AppColors.accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            "R\$ ${item.valorParcela ?? "0"}",
            style: const TextStyle(
              color: _AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
