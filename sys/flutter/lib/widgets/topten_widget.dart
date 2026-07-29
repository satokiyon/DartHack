import 'package:flutter/material.dart';
import '../models/topten_entry.dart';

class TopTenWidget extends StatelessWidget {
  final List<TopTenEntry> entries;

  const TopTenWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                "スコアボード",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[200],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrent = entry.isCurrent;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                color: isCurrent ? const Color(0xFF2C2214) : const Color(0xFF1E222B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isCurrent ? const Color(0xFFFFB300) : Colors.white12,
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                ),
                elevation: isCurrent ? 6 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 順位表示
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${entry.rank}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // スコアとプレイヤー名
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${entry.score} 点",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.nameAndProfile,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isCurrent ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (entry.details.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            ...entry.details.map((detail) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCurrent ? Colors.white.withValues(alpha: 0.87) : Colors.grey[400],
                                      height: 1.3,
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                      if (isCurrent)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "今回の記録",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
