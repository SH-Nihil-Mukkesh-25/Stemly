// lib/visualiser/visualiser_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'visualiser_controller.dart';
import 'visualiser_models.dart';
import 'parameter_slider.dart';

// Import CustomPainter widgets
import 'projectile_motion.dart';
import 'free_fall_component.dart';
import 'shm_component.dart';
import 'kinematics_component.dart';
import 'optics_component.dart';

class VisualiserScreen extends StatefulWidget {
  final String topic;
  final String? userId;

  const VisualiserScreen({
    super.key,
    required this.topic,
    this.userId,
  });

  @override
  State<VisualiserScreen> createState() => _VisualiserScreenState();
}

class _VisualiserScreenState extends State<VisualiserScreen> {
  late VisualiserController controller;
  Widget? visualiserWidget;

  @override
  void initState() {
    super.initState();
    controller = Provider.of<VisualiserController>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    await controller.loadTemplate(widget.topic, userId: widget.userId);
    _updateWidgetFromTemplate();
  }

  void _updateWidgetFromTemplate() {
    final template = controller.template;
    if (template == null) return;

    final p = template.parameters;
    double getVal(String key) => p[key]?.value ?? 0.0;
    
    Widget? newWidget;
    final id = template.templateId.toLowerCase();

    if (id.contains('projectile')) {
      newWidget = ProjectileMotionWidget(
        U: getVal('U'),
        theta: getVal('theta'),
        g: getVal('g'),
      );
    } else if (id.contains('free') || id.contains('fall')) {
      newWidget = FreeFallWidget(
        h: getVal('h'),
        g: getVal('g'),
      );
    } else if (id.contains('shm')) {
      newWidget = SHMWidget(
        A: getVal('A'),
        m: getVal('m'),
        k: getVal('k'),
      );
    } else if (id.contains('kinematics')) {
      newWidget = KinematicsWidget(
        u: getVal('u'),
        a: getVal('a'),
        tMax: getVal('t_max'),
      );
    } else if (id.contains('optics')) {
      newWidget = OpticsWidget(
        f: getVal('f'),
        u: getVal('u'),
        h_o: getVal('h_o'),
      );
    }

    if (mounted) {
      setState(() {
        visualiserWidget = newWidget;
      });
    }
  }

  Widget _buildSliders(VisualTemplate template) {
    return Column(
      children: template.parameters.entries.map((entry) {
        final name = entry.key;
        final param = entry.value;

        return ParameterSlider(
          label: param.label,
          value: param.value,
          min: param.min,
          max: param.max,
          unit: param.unit,
          onChanged: (v) {
            controller.updateLocalParameter(name, v);
            _updateWidgetFromTemplate(); // Rebuild widget with new params
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisualiserController>(
      builder: (context, ctl, _) {
        if (ctl.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (ctl.error != null) {
          return Scaffold(
            body: Center(child: Text("Error: ${ctl.error}")),
          );
        }

        final template = ctl.template;

        if (template == null) {
          return Scaffold(
            body: Center(
              child: Text('No template found for "${widget.topic}"'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(template.title)),
          body: Row(
            children: [
              // Animation Area
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.black12,
                  height: double.infinity,
                  child: visualiserWidget ?? const Center(child: Text("Select a topic")),
                ),
              ),
              
              // Controls Area
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        template.description,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildSliders(template),
                      const SizedBox(height: 20),
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Ask AI to Adjust"),
                        onPressed: () => _showAiDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAiDialog(BuildContext context) async {
    final promptController = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ask AI (Natural Language)'),
        content: TextField(
          controller: promptController,
          decoration: const InputDecoration(
            hintText: "e.g., 'Make it go higher' or 'Increase gravity'",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, promptController.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (res != null && res.trim().isNotEmpty) {
      await controller.applyAiUpdate(res, userId: widget.userId);
      _updateWidgetFromTemplate();
    }
  }
}