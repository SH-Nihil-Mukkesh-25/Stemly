import 'package:flutter/material.dart';
import 'visualiser_models.dart';

// Components
import 'atom_component.dart';
import 'free_fall_component.dart';
import 'graph_component.dart';
import 'kinematics_component.dart';
import 'optics_component.dart';
import 'projectile_motion.dart';
import 'shm_component.dart';
import 'equation_plotter.dart';
import 'generic_diagram.dart';

class VisualiserFactory {
  /// Creates the appropriate visualiser widget based on the template ID.
  static Widget create(VisualTemplate template) {
    final id = (template.templateId).toLowerCase().replaceAll("-", "_");
    final p = template.parameters;

    // Helper to safely get values
    double getVal(String key) {
      if (p.containsKey(key)) return p[key]!.value;
      return 0.0;
    }

    if (id.contains("projectile")) {
      return ProjectileMotionWidget(
        U: getVal("U"),
        theta: getVal("theta"),
        g: getVal("g"),
      );
    }

    if (id.contains("freefall") || id.contains("fall") || id.contains("free")) {
      return FreeFallWidget(h: getVal("h"), g: getVal("g"));
    }

    if (id.contains("shm") || id.contains("harmonic")) {
      return SHMWidget(A: getVal("A"), m: getVal("m"), k: getVal("k"));
    }
    
    if (id.contains("atom") || id.contains("chemistry")) {
      return AtomWidget(
        protons: getVal("protons"),
        neutrons: getVal("neutrons"),
      );
    }

    if (id.contains("math") || id.contains("graph") || id.contains("quadratic")) {
      return GraphWidget(
        a: getVal("a"),
        b: getVal("b"),
        c: getVal("c"),
      );
    }

    if (id.contains("kinematics")) {
      return KinematicsWidget(
        u: getVal("u"),
        a: getVal("a"),
        tMax: getVal("t_max"),
      );
    }

    if (id.contains("optics") || id.contains("lens")) {
      return OpticsWidget(f: getVal("f"), u: getVal("u"), h_o: getVal("h_o"));
    }

    // Dynamic Equation Plotter
    if (id.contains("plot") || id.contains("equation")) {
      String equation = "x^2"; // Default
      
      if (template.metadata.containsKey("equation")) {
        equation = template.metadata["equation"].toString();
      }

      return EquationPlotterWidget(
        equation: equation,
        minX: getVal("min_x") == 0 ? -10 : getVal("min_x"),
        maxX: getVal("max_x") == 0 ? 10 : getVal("max_x"),
        minY: getVal("min_y") == 0 ? -10 : getVal("min_y"),
        maxY: getVal("max_y") == 0 ? 10 : getVal("max_y"),
      );
    }

    // Generic Diagram
    if (id.contains("diagram")) {
      List<Map<String, dynamic>> primitives = [];
      if (template.metadata.containsKey("primitives") && template.metadata["primitives"] is List) {
        primitives = List<Map<String, dynamic>>.from(template.metadata["primitives"]);
      }
      return GenericDiagramWidget(primitives: primitives);
    }

    // Default Fallback
    return const Center(
      child: Text(
        "No interactive visualiser available for this topic",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
