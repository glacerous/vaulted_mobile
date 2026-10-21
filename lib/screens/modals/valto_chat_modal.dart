import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/widgets/valto_mascot.dart';

/// Clean bottom sheet modal for interactive Valto Sentinel chat thread.
class ValtoChatModal {
  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> chatHistory,
    required ValtoMood valtoMood,
    required bool isAiProcessing,
    required Future<void> Function(String prompt) onSubmitPrompt,
    required void Function(void Function(void Function()) registerSetState) onRegisterModalState,
    required VoidCallback onDismiss,
  }) {
    final chatInputCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          onRegisterModalState(setModalState);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollCtrl.hasClients) {
              scrollCtrl.animateTo(
                scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: VaultColors.card,
                    border: Border(bottom: BorderSide(color: VaultColors.hairline)),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ValtoMascot(size: 32, mood: valtoMood),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Valto Sentinel', style: VaultTypography.sans(fontSize: 14.5, fontWeight: FontWeight.w700, color: VaultColors.ink)),
                              Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: VaultColors.pos, shape: BoxShape.circle)),
                                  const SizedBox(width: 5),
                                  Text('Online · Vault Sentinel', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: VaultColors.ink2, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Bubbles List
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, idx) {
                      final msg = chatHistory[idx];
                      final isUser = msg['isUser'] == true;
                      final text = msg['text'] as String? ?? '';
                      final time = msg['time'] as String? ?? '';
                      final isAction = msg['isAction'] == true;
                      final amount = (msg['amount'] as num?)?.toDouble() ?? 0.0;
                      final currency = msg['currency'] as String? ?? 'IDR';
                      final suggestions = (msg['suggestions'] as List<dynamic>?)?.cast<String>() ?? [];

                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12, left: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              color: VaultColors.accent,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(text, style: VaultTypography.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: VaultColors.background)),
                                const SizedBox(height: 3),
                                Text(time, style: VaultTypography.mono(fontSize: 9, color: VaultColors.background.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14, right: 36),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ValtoMascot(size: 26, mood: ValtoMood.vigilant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: VaultColors.card,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4), topRight: Radius.circular(16),
                                          bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                                        ),
                                        border: Border.all(color: VaultColors.hairline),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(text, style: VaultTypography.sans(fontSize: 13, height: 1.45, color: VaultColors.ink)),
                                          if (isAction && amount > 0) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: VaultColors.badgeBg,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: VaultColors.hairline),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.check_circle_rounded, size: 14, color: VaultColors.pos),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    currency == 'IDR'
                                                        ? 'Rp ${amount.toStringAsFixed(0)} Logged'
                                                        : '\$${amount.toStringAsFixed(2)} Logged',
                                                    style: VaultTypography.mono(fontSize: 11, fontWeight: FontWeight.w700, color: VaultColors.accent),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(time, style: VaultTypography.mono(fontSize: 9, color: VaultColors.ink3)),
                                    ),
                                    if (suggestions.isNotEmpty && idx == chatHistory.length - 1) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6, runSpacing: 6,
                                        children: suggestions.map((sug) => InkWell(
                                          onTap: () {
                                            onSubmitPrompt(sug.replaceAll('"', ''));
                                            setModalState(() {});
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: VaultColors.cardHover,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: VaultColors.hairline),
                                            ),
                                            child: Text(sug, style: VaultTypography.sans(fontSize: 11, color: VaultColors.accent)),
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (isAiProcessing)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Row(
                      children: [
                        const ValtoMascot(size: 20, mood: ValtoMood.detective),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: VaultColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: VaultColors.hairline)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: VaultColors.accent)),
                              const SizedBox(width: 8),
                              Text('Valto is thinking...', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input Dock
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: VaultColors.card,
                    border: Border(top: BorderSide(color: VaultColors.hairline)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: VaultColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: VaultColors.hairline),
                            ),
                            child: TextField(
                              controller: chatInputCtrl,
                              style: VaultTypography.sans(fontSize: 13, color: VaultColors.ink),
                              cursorColor: VaultColors.accent,
                              decoration: InputDecoration(
                                hintText: 'Message Valto or log asset...',
                                hintStyle: VaultTypography.sans(fontSize: 12, color: VaultColors.ink3),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  final q = val.trim();
                                  chatInputCtrl.clear();
                                  onSubmitPrompt(q);
                                  setModalState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final q = chatInputCtrl.text.trim();
                            if (q.isNotEmpty) {
                              chatInputCtrl.clear();
                              onSubmitPrompt(q);
                              setModalState(() {});
                            }
                          },
                          child: Container(
                            width: 38, height: 38,
                            decoration: const BoxDecoration(color: VaultColors.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_upward_rounded, size: 18, color: VaultColors.background),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(onDismiss);
  }
}
