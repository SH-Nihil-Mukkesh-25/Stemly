// lib/visualiser/visualiser_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'projectile_motion.dart';
import 'visualiser_controller.dart';
import 'visualiser_models.dart';
import 'parameter_slider.dart';

class VisualiserScreen extends StatefulWidget {
  final String topic;
  final String? userId;
  const VisualiserScreen({super.key, required this.topic, this.userId});

  @override
  State<VisualiserScreen> createState() => _VisualiserScreenState();
}

class _VisualiserScreenState extends State<VisualiserScreen> {
  late VisualiserController controller;
  ProjectileComponent? projectile;
  late GameWidget gameWidget;
  late Game game;

  @override
  void initState() {
    super.initState();
    controller = Provider.of<VisualiserController>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    await controller.loadTemplate(widget.topic, userId: widget.userId);
    final template = controller.template;
    if (template == null) return;

    // create game + component based on template
    if (template.animationType.contains('projectile')) {
      final p = template.parameters;
      final U = p['U']!.value;
      final theta = p['theta']!.value;
      final g = p['g']!.value;

      final comp = ProjectileComponent(U: U, theta: theta, g: g, position: Vector2(50, 350));
      projectile = comp;
      
      // Create a custom FlameGame that loads the component
      game = _VisualiserGame(comp);
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSliders(VisualTemplate template) {
    final widgets = <Widget>[];
    template.parameters.forEach((name, param) {
      widgets.add(ParameterSlider(
        label: param.label,
        value: param.value,
        min: param.min,
        max: param.max,
        unit: param.unit,
        onChanged: (v) {
          controller.updateLocalParameter(name, v);
          // update flame component param if exists
          if (projectile != null) {
            if (name == 'U') projectile!.updateParams(U: v);
            if (name == 'theta') projectile!.updateParams(theta: v);
            if (name == 'g') projectile!.updateParams(g: v);
          }
        },
      ));
    });
    return Column(children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisualiserController>(builder: (context, ctl, _) {
      if (ctl.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (ctl.error != null) {
        return Scaffold(body: Center(child: Text('Error: ${ctl.error}')));
      }

      final template = ctl.template;
      if (template == null) {
        return Scaffold(body: Center(child: Text('No template for ${widget.topic}')));
      }

      return Scaffold(
        appBar: AppBar(title: Text(template.title)),
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black12,
                child: (game != null)
                    ? GameWidget(game: game)
                    : Center(child: Text('Loading animation...')),
                height: 500,
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(template.description),
                    const SizedBox(height: 12),
                    _buildSliders(template),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Example: ask AI to change params
                        final promptController = TextEditingController();
                        final res = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Ask visualiser (natural language)'),
                            content: TextField(controller: promptController),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, null),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, promptController.text),
                                  child: const Text('Apply')),
                            ],
                          ),
                        );
                        if (res != null && res.trim().isNotEmpty) {
                          await controller.applyAiUpdate(res, userId: widget.userId);
                          // apply merged params to projectile
                          final params = controller.template!.parameters;
                          if (projectile != null) {
                            projectile!.updateParams(
                              U: params['U']!.value,
                              theta: params['theta']!.value,
                              g: params['g']!.value,
                            );
                          }
                        }
                      },
                      child: const Text('Ask AI to update'),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}

// Custom FlameGame class for the visualiser
class _VisualiserGame extends FlameGame {
  final ProjectileComponent projectile;
  
  _VisualiserGame(this.projectile);
  
  @override
  Future<void> onLoad() async {
    await add(projectile);
    return super.onLoad();
  }
}
