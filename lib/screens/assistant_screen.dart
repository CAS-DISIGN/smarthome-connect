import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appareil.dart';

class AssistantScreen extends StatefulWidget {
  final List<Appareil> appareils;
  final double unitesSeeg;

  const AssistantScreen({
    super.key,
    required this.appareils,
    required this.unitesSeeg,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controleur = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _enChargement = false;

  static const String _apiKey = 'GROQ_API_KEY_ICI';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _modele = 'llama3-8b-8192';

  String get _contexte {
    final allumes = widget.appareils.where((a) => a.estAllume).toList();
    final eteints = widget.appareils.where((a) => !a.estAllume).toList();
    final consoTotale = allumes.fold(0.0, (s, a) => s + a.watts);
    final top = [...widget.appareils]..sort((a, b) => b.watts.compareTo(a.watts));

    return """
Tu es un assistant énergétique intelligent pour une application domotique SmartHome Connect utilisée au Gabon (Libreville).
Tu aides l'utilisateur à gérer sa consommation électrique SEEG (société d'électricité du Gabon).
Réponds toujours en français, de façon concise et pratique.

Voici l'état actuel de l'installation :
- Unités SEEG restantes : ${widget.unitesSeeg.toStringAsFixed(1)} kWh
- Appareils allumés (${allumes.length}) : ${allumes.map((a) => '${a.nom} (${a.watts.toInt()}W)').join(', ')}
- Appareils éteints (${eteints.length}) : ${eteints.map((a) => '${a.nom} (${a.watts.toInt()}W)').join(', ')}
- Consommation actuelle totale : ${consoTotale.toInt()} W
- Top consommateur : ${top.isNotEmpty ? '${top.first.nom} (${top.first.watts.toInt()}W)' : 'aucun'}
- Autonomie estimée (6h/jour d'utilisation) : ${consoTotale > 0 ? (widget.unitesSeeg / (consoTotale * 6 / 1000)).toStringAsFixed(1) : '∞'} jours

Donne des conseils personnalisés basés sur ces données réelles.
""";
  }

  Future<void> _envoyerMessage(String texte) async {
    if (texte.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': texte});
      _enChargement = true;
    });
    _controleur.clear();
    _scrollerEnBas();

    try {
      // Construction de l'historique avec le system prompt
      final messagesApi = <Map<String, String>>[
        {'role': 'system', 'content': _contexte},
      ];

      for (final m in _messages) {
        messagesApi.add({'role': m['role']!, 'content': m['content']!});
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modele,
          'max_tokens': 1000,
          'messages': messagesApi,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reponse = data['choices'][0]['message']['content'] as String;
        setState(() {
          _messages.add({'role': 'assistant', 'content': reponse});
          _enChargement = false;
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ Erreur ${response.statusCode} : ${response.body}',
          });
          _enChargement = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ Pas de connexion internet.',
        });
        _enChargement = false;
      });
    }

    _scrollerEnBas();
  }

  void _scrollerEnBas() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final List<String> _suggestions = [
    '⚡ Combien de jours me restent-il ?',
    '💡 Quel appareil consomme le plus ?',
    '🌿 Comment économiser mes unités ?',
    '🔌 Que dois-je éteindre en priorité ?',
    '📅 Coupure ce soir, que faire ?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '🤖 Assistant énergétique SmartHome',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _envoyerMessage(s),
                    )).toList(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Pose-moi une question sur\nta consommation électrique',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final estUser = msg['role'] == 'user';
                      return Align(
                        alignment: estUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: estUser
                                ? const Color(0xFF1565C0)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(estUser ? 16 : 4),
                              bottomRight: Radius.circular(estUser ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(
                              color: estUser ? Colors.white : null,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_enChargement)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, size: 20, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text("L'assistant réfléchit...",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controleur,
                    decoration: InputDecoration(
                      hintText: 'Pose ta question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _envoyerMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _envoyerMessage(_controleur.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controleur.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}