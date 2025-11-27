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
      HistoryStore.setHistory(list.sublist(list.length - 20));
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

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Scan History",
          style: TextStyle(
            color: deepBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        elevation: 0.4,

        actions: [
          if (history.isNotEmpty)
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
          ? _emptyState(theme)
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
                    final removed = h;
                    final removedIndex = index;

                    HistoryStore.remove(removed);
                    setState(() {});

                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("Deleted '${removed.topic}'"),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: "UNDO",
                          textColor: deepBlue,
                          onPressed: () {
                            HistoryStore.history.insert(removedIndex, removed);
                            HistoryStore.setHistory(HistoryStore.history);
                            setState(() {});
                          },
                        ),
                      ),
                    );
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
                    child: _historyCard(h, deepBlue, theme),
                  ),
                );
              },
            ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          "No scan history yet.\nScan something to get started!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.4,
            color: theme.colorScheme.onBackground.withOpacity(0.65),
          ),
        ),
      ),
    );
  }

  // ---------------- DELETE BACKGROUND ----------------
  Widget _deleteBg({required bool left}) {
    return Container(
      color: Colors.redAccent,
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: left ? 20 : 0, right: left ? 0 : 20),
      child: const Icon(Icons.delete, color: Colors.white, size: 26),
    );
  }

  // ---------------- HISTORY CARD ----------------
  Widget _historyCard(h, Color deepBlue, ThemeData theme) {
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: h.imagePath,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: deepBlue,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.file(
                  File(h.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // TEXTS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: deepBlue,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Variables: ${h.variables.join(', ')}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // STAR
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
