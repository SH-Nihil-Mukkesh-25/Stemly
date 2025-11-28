// lib/visualiser/controllers/visualiser_controller.dart
import 'package:flutter/foundation.dart';
import 'visualiser_models.dart';
import 'visualiser_api.dart';

class VisualiserController extends ChangeNotifier {
  final VisualiserApi api;
  VisualTemplate? template;
  bool loading = false;
  String? error;

  VisualiserController({required this.api});

  Future<void> loadTemplate(String topic, {List<String>? variables, String? userId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final t = await api.generateTemplate(topic: topic, variables: variables, userId: userId);
      template = t;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> applyAiUpdate(String userPrompt, {String? userId}) async {
    if (template == null) return;
    loading = true;
    notifyListeners();

    final params = <String, dynamic>{};
    template!.parameters.forEach((k, v) => params[k] = v.value);

    try {
      final resp = await api.updateParameters(
        templateId: template!.templateId,
        parameters: params,
        userPrompt: userPrompt,
        userId: userId,
      );

      final merged = resp['parameters'] as Map<String, dynamic>? ?? {};
      // update local template parameters
      merged.forEach((k, v) {
        if (template!.parameters.containsKey(k)) {
          template!.parameters[k]!.value = (v as num).toDouble();
        }
      });
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void updateLocalParameter(String name, double val) {
    if (template == null) return;
    if (!template!.parameters.containsKey(name)) return;
    template!.parameters[name]!.value = val;
    notifyListeners();
  }

  Map<String, double> currentParameters() {
    final map = <String, double>{};
    if (template == null) return map;
    template!.parameters.forEach((k, v) => map[k] = v.value);
    return map;
  }
}