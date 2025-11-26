import 'dart:io';
import 'package:flutter/material.dart';
import '../storage/history_store.dart';
import '../screens/history_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _cleanupOldHistory();
  }

  void _cleanupOldHistory() {
    final list = HistoryStore.history;
    if (list.length > 20) {
      HistoryStore.setHistory(
        list.sublist(list.length - 20),
      );
    }
  }

  void _clearNonStarred() {
    HistoryStore.setHistory(
      HistoryStore.history.where((h) => h.isStarred).toList(),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final history = HistoryStore.history;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Scan History"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _clearNonStarred,
            child: const Text(
              "Clear",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                "No scan history yet",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];

                return Dismissible(
                  key: ValueKey(h.timestamp.toString()),
                  direction: DismissDirection.horizontal,
                  background: _deleteBg(left: true),
                  secondaryBackground: _deleteBg(left: false),

                  confirmDismiss: (direction) async {
                    if (h.isStarred) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot delete starred item"),
                        ),
                      );
                      return false;
                    }
                    return true;
                  },

                  onDismissed: (_) {
                    HistoryStore.remove(h);
                    setState(() {});
                  },

                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryDetailScreen(history: h),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: _historyCard(h),
                  ),
                );
              },
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _deleteBg({required bool left}) {
    return Container(
      color: Colors.red,
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: left ? 20 : 0, right: left ? 0 : 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _historyCard(h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail 
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF003A70),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.file(
                File(h.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003A70),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Variables: ${h.variables.join(', ')}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B6378),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              h.isStarred ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                h.isStarred = !h.isStarred;
              });
            },
          ),
        ],
      ),
    );
  }
}
