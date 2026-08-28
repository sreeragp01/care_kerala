import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_healthcare_service.dart';
import '../../../core/state/app_state_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  final AppStateProvider state;

  const AiAssistantScreen({super.key, required this.state});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _queryCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Namaskaram! I am your CareLink Kerala AI Assistant. I can summarize patient profiles, convert voice notes into clinical drafts, evaluate patient risk scores, or search dashboard records in natural Malayalam/English.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Healthcare Assistant'),
      ),
      body: Column(
        children: [
          // Quick Action Chip Presets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.lightSand,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Show Critical Patients',
                  'Check Low Stock Medicines',
                  'Summarize Patient PAT-101',
                  'Category A Bedridden Count',
                ].map((prompt) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(prompt, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.surface,
                        onPressed: () {
                          _queryCtrl.text = prompt;
                          _handleSendQuery();
                        },
                      ),
                    )).toList(),
              ),
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final isUser = _messages[i]['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryGreen : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: isUser ? null : Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _messages[i]['text']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Query Input Box
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask in English or Malayalam...',
                    ),
                    onSubmitted: (_) => _handleSendQuery(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primaryGreen),
                  onPressed: _handleSendQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendQuery() async {
    final text = _queryCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _queryCtrl.clear();
      _messages.add({'sender': 'ai', 'text': 'Thinking with Gemini AI...'});
    });

    final aiResponse = await AiHealthcareService.processNaturalLanguageQueryAsync(
      text,
      widget.state.patients,
      widget.state.medicines,
    );

    if (mounted) {
      setState(() {
        _messages.removeLast(); // Remove loading bubble
        _messages.add({'sender': 'ai', 'text': aiResponse});
      });
    }
  }
}
