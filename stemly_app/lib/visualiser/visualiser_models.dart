// lib/visualiser/models/visualiser_models.dart
import 'dart:convert';

class TemplateParameter {
  String name;
  double value;
  double min;
  double max;
  String unit;
  String label;

  TemplateParameter({
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    this.unit = '',
    this.label = '',
  });

  factory TemplateParameter.fromJson(String name, Map<String, dynamic> j) {
    double safeDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return TemplateParameter(
      name: name,
      value: safeDouble(j['value']),
      min: safeDouble(j['min']),
      max: safeDouble(j['max'] ?? 100),
      unit: j['unit'] ?? '',
      label: j['label'] ?? name,
    );
  }

  Map<String, dynamic> toJson() => {
        name: {
          'value': value,
          'min': min,
          'max': max,
          'unit': unit,
          'label': label,
        }
      };
}

class VisualTemplate {
  String templateId;
  String title;
  String animationType;
  String description;
  Map<String, TemplateParameter> parameters;
  Map<String, dynamic> metadata;

  VisualTemplate({
    required this.templateId,
    required this.title,
    required this.animationType,
    required this.description,
    required this.parameters,
    this.metadata = const {},
  });

  factory VisualTemplate.fromJson(Map<String, dynamic> json) {
    final params = <String, TemplateParameter>{};
    final rawParams = json['parameters'] as Map<String, dynamic>? ?? {};
    rawParams.forEach((k, v) {
      params[k] = TemplateParameter.fromJson(k, v);
    });

    return VisualTemplate(
      templateId: json['template_id'] ?? json['templateId'] ?? 'unknown',
      title: json['title'] ?? '',
      animationType: json['animation_type'] ?? json['animationType'] ?? '',
      description: json['description'] ?? '',
      parameters: params,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    final p = <String, dynamic>{};
    parameters.forEach((k, v) => p[k] = {
          'value': v.value,
          'min': v.min,
          'max': v.max,
          'unit': v.unit,
          'label': v.label
        });
    return {
      'template_id': templateId,
      'title': title,
      'animation_type': animationType,
      'description': description,
      'parameters': p,
      'metadata': metadata,
    };
  }
}
