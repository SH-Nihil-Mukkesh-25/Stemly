// // lib/visualiser/visualiser_screen.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flame/game.dart';
// import 'package:flame/components.dart';

// import 'projectile_motion.dart';
// import 'visualiser_controller.dart';
// import 'visualiser_models.dart';
// import 'parameter_slider.dart';

// class VisualiserScreen extends StatefulWidget {
//   final String topic;
//   final String? userId;

//   const VisualiserScreen({
//     super.key,
//     required this.topic,
//     this.userId,
//   });

//   @override
//   State<VisualiserScreen> createState() => _VisualiserScreenState();
// }

// class _VisualiserScreenState extends State<VisualiserScreen> {
//   late VisualiserController controller;

//   ProjectileComponent? projectile;
//   FlameGame? game;

//   @override
//   void initState() {
//     super.initState();
//     controller = Provider.of<VisualiserController>(context, listen: false);
//     _load();
//   }

//   Future<void> _load() async {
//     await controller.loadTemplate(widget.topic, userId: widget.userId);

//     final template = controller.template;
//     if (template == null) return;

//     if (template.animationType.contains('projectile')) {
//       final p = template.parameters;

//       final U = p['U']!.value;
//       final theta = p['theta']!.value;
//       final g = p['g']!.value;

//       final comp = ProjectileComponent(
//         U: U,
//         theta: theta,
//         g: g,
//         position: Vector2(50, 350),
//       );

//       projectile = comp;
//       game = _VisualiserGame(comp);

//       setState(() {});
//     }
//   }

//   Widget _buildSliders(VisualTemplate template) {
//     return Column(
//       children: template.parameters.entries.map((entry) {
//         final name = entry.key;
//         final param = entry.value;

//         return ParameterSlider(
//           label: param.label,
//           value: param.value,
//           min: param.min,
//           max: param.max,
//           unit: param.unit,
//           onChanged: (v) {
//             controller.updateLocalParameter(name, v);

//             if (projectile != null) {
//               projectile!.updateParams(
//                 U: name == 'U' ? v : null,
//                 theta: name == 'theta' ? v : null,
//                 g: name == 'g' ? v : null,
//               );
//             }
//           },
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<VisualiserController>(
//       builder: (context, ctl, _) {
//         if (ctl.loading) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (ctl.error != null) {
//           return Scaffold(
//             body: Center(child: Text("Error: ${ctl.error}")),
//           );
//         }

//         final template = ctl.template;

//         if (template == null) {
//           return Scaffold(
//             body: Center(
//               child: Text('No template found for "${widget.topic}"'),
//             ),
//           );
//         }

//         return Scaffold(
//           appBar: AppBar(title: Text(template.title)),
//           body: Row(
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   color: Colors.black12,
//                   height: 500,
//                   child: game != null
//                       ? GameWidget(game: game!)
//                       : const Center(child: Text("Loading animation...")),
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     children: [
//                       Text(template.description),
//                       const SizedBox(height: 12),
//                       _buildSliders(template),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // ------------ GENERIC GAME WRAPPER (SUPPORTS ALL ANIMATIONS) ------------
// class _VisualiserGame extends FlameGame {
//   final Component component;

//   _VisualiserGame(this.component);

//   @override
//   Future<void> onLoad() async {
//     await add(component);
//     super.onLoad();
//   }
// }
