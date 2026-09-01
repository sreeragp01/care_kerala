import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
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
  late final List<Map<String, String>> _messages;

  @override
  void initState() {
    super.initState();
    final user = widget.state.currentUser;
    final isPatient = user.role.isPatientOrFamily;

    _messages = [
      {
        'sender': 'ai',
        'text': isPatient
            ? 'Namaskaram ${user.name}! I am your personal CareLink Kerala health companion. I can assist you with your upcoming OPD appointment tokens, daily medication schedule, home palliative care guidance, or emergency support.'
            : 'Namaskaram ${user.name}! I am your CareLink Kerala clinical decision assistant. I can summarize patient profiles, triage high-risk vitals, monitor pharmacy stock levels, and review palliative protocols.'
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.state.currentUser;
    final isPatient = user.role.isPatientOrFamily;

    final presetChips = isPatient
        ? [
            'My Appointment & Token 🎫',
            'My Medication Schedule 💊',
            'How to Relieve Pain at Home? 🏠',
            'Request Nurse Home Visit 🩺',
            'Emergency Ambulance 🚑',
          ]
        : [
            'Show Critical Patients 🚨',
            'Check Low Stock Medicines ⚠️',
            'Summarize Patient PAT-101 📋',
            'Category A Bedridden Count 🛏️',
            'Palliative Pain Protocols 💊',
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isPatient ? 'Personal Health Assistant' : 'AI Clinical Decision Assistant'),
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
                children: presetChips.map((prompt) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.surface,
                        onPressed: () {
                          _queryCtrl.text = prompt.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim();
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
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
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
                        fontSize: 13.5,
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
                    decoration: InputDecoration(
                      hintText: isPatient ? 'Ask about your token, medicine, home care...' : 'Ask clinical query in English or Malayalam...',
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
      _messages.add({'sender': 'ai', 'text': 'Thinking with CareLink AI...'});
    });

    final aiResponse = await AiHealthcareService.processNaturalLanguageQueryAsync(
      query: text,
      patients: widget.state.patients,
      medicines: widget.state.medicines,
      currentUser: widget.state.currentUser,
      appointments: widget.state.appointments,
      medicationPlans: widget.state.medicationPlans,
    );

    if (mounted) {
      setState(() {
        _messages.removeLast(); // Remove loading bubble
        _messages.add({'sender': 'ai', 'text': aiResponse});
      });
    }
  }
}
