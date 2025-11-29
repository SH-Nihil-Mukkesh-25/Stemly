import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stemly_app/visualiser/kinematics_component.dart';
import 'package:stemly_app/visualiser/optics_component.dart';

import '../visualiser/projectile_motion.dart';
import '../visualiser/free_fall_component.dart';
import '../visualiser/shm_component.dart';
import '../visualiser/visualiser_models.dart';

class ScanResultScreen extends StatefulWidget {
  final String topic;
  final List<String> variables;
  final Map<String, dynamic> notesJson;
  final String imagePath;

  const ScanResultScreen({
    super.key,
    required this.topic,
    required this.variables,
    required this.notesJson,
    required this.imagePath,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final Map<String, bool> expanded = {};
  
  VisualTemplate? visualiserTemplate;
  Widget? visualiserWidget;
  bool loadingVisualiser = true;
  
  final String serverIp = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    
    // Debug logging
    print("🔍 ScanResultScreen initialized");
    print("🔍 Topic: ${widget.topic}");
    print("🔍 Variables: ${widget.variables}");
    print("🔍 Image Path: ${widget.imagePath}");
    print("🔍 Notes JSON type: ${widget.notesJson.runtimeType}");
    print("🔍 Notes JSON keys: ${widget.notesJson.keys.toList()}");
    print("🔍 Notes JSON isEmpty: ${widget.notesJson.isEmpty}");
    
    for (var key in widget.notesJson.keys) {
      expanded[key] = false;
      print("🔍 Notes key '$key' has value type: ${widget.notesJson[key].runtimeType}");
    }
    
    _loadVisualiser();
  }
  
  Future<void> _loadVisualiser() async {
    setState(() => loadingVisualiser = true);
    
    try {
      final url = Uri.parse('$serverIp/visualiser/generate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': widget.topic,
          'variables': widget.variables,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final templateJson = data['template'] as Map<String, dynamic>;
        final template = VisualTemplate.fromJson(templateJson);

        final templateId = template.templateId.toLowerCase();
        Widget? newWidget;

        final p = template.parameters;
        double getVal(String key) => p[key]?.value ?? 0.0;

        if (templateId.contains('projectile')) {
          newWidget = ProjectileMotionWidget(
            U: getVal('U'),
            theta: getVal('theta'),
            g: getVal('g'),
          );
        } else if (templateId.contains('free') || templateId.contains('fall')) {
          newWidget = FreeFallWidget(
            h: getVal('h'),
            g: getVal('g'),
          );
        } else if (templateId.contains('shm')) {
          newWidget = SHMWidget(
            A: getVal('A'),
            m: getVal('m'),
            k: getVal('k'),
          );
        } else if (templateId.contains('kinematics')) {
          newWidget = KinematicsWidget(
            u: getVal('u'),
            a: getVal('a'),
            tMax: getVal('t_max'),
          );
        } else if (templateId.contains('optics')) {
          newWidget = OpticsWidget(
            f: getVal('f'),
            u: getVal('u'),
            h_o: getVal('h_o'),
          );
        }

        if (mounted) {
          setState(() {
            visualiserTemplate = template;
            visualiserWidget = newWidget;
            loadingVisualiser = false;
          });
        }
      } else {
        setState(() => loadingVisualiser = false);
      }
    } catch (e) {
      setState(() => loadingVisualiser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final deepBlue = cs.primary;
    final primaryColor = cs.primaryContainer;
    final cardColor = theme.cardColor;
    final background = theme.scaffoldBackgroundColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,

        // ---------------------------------------------------------
        // NEW POLISHED APP BAR
        // ---------------------------------------------------------
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          iconTheme: IconThemeData(color: deepBlue),

          title: Text(
            "Scan Result",
            style: TextStyle(
              color: deepBlue,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,

          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(26),
            ),
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: deepBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: deepBlue.withOpacity(0.7),

                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        deepBlue,
                        deepBlue.withOpacity(0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deepBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),

                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),

                  tabs: const [
                    Tab(text: "AI Visualiser"),
                    Tab(text: "AI Notes"),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ---------------------------------------------------------
        // BODY
        // ---------------------------------------------------------
        body: TabBarView(
          children: [
            _visualiser(deepBlue),
            _notes(cardColor, deepBlue),

    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _isSendingMessage = true;
      _chatController.clear();
    });

    try {
      final currentParams = <String, dynamic>{};
      if (visualiserTemplate != null) {
        visualiserTemplate!.parameters.forEach((k, v) => currentParams[k] = v.value);
      }

      final res = await http.post(
        Uri.parse("$serverIp/visualiser/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "template_id": visualiserTemplate?.templateId ?? "",
          "parameters": currentParams,
          "user_prompt": text,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final params = data['parameters'] as Map<String, dynamic>;
        final aiResponse = data['ai_response'];

        _updateVisualiserWidget(visualiserTemplate!.templateId, params);

        setState(() {
          _chatMessages.add({'role': 'ai', 'content': aiResponse});
          _isSendingMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({'role': 'ai', 'content': "Connection failed"});
        _isSendingMessage = false;
      });
    }
  }

  void _updateVisualiserWidget(String templateId, Map<String, dynamic> params) {
    double getVal(String k) =>
        (params[k] is num) ? (params[k] as num).toDouble() : 0.0;

    Widget? newWidget;
    final id = templateId.toLowerCase();

    if (id.contains("projectile")) {
      newWidget = ProjectileMotionWidget(
        U: getVal("U"),
        theta: getVal("theta"),
        g: getVal("g"),
      );
    } else if (id.contains("free")) {
      newWidget = FreeFallWidget(
        h: getVal("h"),
        g: getVal("g"),
      );
    } else if (id.contains("shm")) {
      newWidget = SHMWidget(
        A: getVal("A"),
        m: getVal("m"),
        k: getVal("k"),
      );
    }

    setState(() => visualiserWidget = newWidget);
  }

  // ---------------------------------------------------------
  // NOTES
  // ---------------------------------------------------------
  Widget _notes(Color cardColor, Color deepBlue) {
    // Debug logging
    print("📝 Building notes UI");
    print("📝 Notes JSON keys: ${widget.notesJson.keys.toList()}");
    print("📝 Notes JSON: ${widget.notesJson}");
    
    // Check for error in response
    if (widget.notesJson.containsKey("error")) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: deepBlue.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "Failed to load notes",
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.notesJson["error"].toString(),
                style: TextStyle(color: deepBlue.withOpacity(0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Check for empty notes
    if (widget.notesJson.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_outlined, size: 64, color: deepBlue.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "No notes available",
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Notes generation may have failed",
                style: TextStyle(color: deepBlue.withOpacity(0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.notesJson.entries.map((entry) {
          final key = entry.key;

          return _expandableCard(
            title: _formatKey(key),
            expanded: expanded[key]!,
            onTap: () => setState(() => expanded[key] = !expanded[key]!),
            child: _buildContent(entry.value, deepBlue),
            cardColor: cardColor,
            deepBlue: deepBlue,
          );
        }).toList(),
      ),
    );
  }

  Widget _expandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget child,
    required Color cardColor,
    required Color deepBlue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 30,
                    color: deepBlue,
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild:
                Padding(padding: const EdgeInsets.all(14), child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic value, Color deepBlue) {
    if (value is String) {
      return Text(value, style: TextStyle(fontSize: 15, color: deepBlue));
    }

    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value
            .map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("• $v",
                      style: TextStyle(fontSize: 15, color: deepBlue)),
                ))
            .toList(),
      );
    }

    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("${e.key}: ${e.value}",
                      style: TextStyle(fontSize: 15, color: deepBlue)),
                ))
            .toList(),
      );
    }

    return const Text("Unsupported format");
  }

  Widget _title(String text, Color deepBlue) => Text(
        text,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: deepBlue,
        ),
      );

  Widget _value(String text, Color deepBlue) =>
      Text(text, style: TextStyle(fontSize: 17, color: deepBlue));

  String _formatKey(String raw) {
    if (raw.isEmpty) return "";
    return raw
        .replaceAll("_", " ")
        .trim()
        .replaceFirst(raw[0], raw[0].toUpperCase());
  }
}