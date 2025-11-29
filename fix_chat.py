#!/usr/bin/env python3
"""
Script to fix scan_result_screen.dart with chat improvements
"""
import re

# Read the file
with open(r'c:\Users\Nihil\Desktop\projects\stemly\stemly_app\lib\screens\scan_result_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Add imports after line 4
import_fix = """import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stemly_app/visualiser/kinematics_component.dart';
import 'package:stemly_app/visualiser/optics_component.dart';

import '../services/firebase_auth_service.dart';
import '../visualiser/projectile_motion.dart';"""

content = content.replace(
    """import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stemly_app/visualiser/kinematics_component.dart';
import 'package:stemly_app/visualiser/optics_component.dart';

import '../visualiser/projectile_motion.dart';""",
    import_fix
)

# Fix 2: Replace _sendMessage function - search for the pattern and replace
old_send_message = r'''  Future<void> _sendMessage\(\) async \{[\s\S]*?final res = await http\.post\([\s\S]*?Uri\.parse\("\$serverIp/visualiser/update"\),[\s\S]*?\}\s*\}\s*\}'''

new_send_message = '''  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _isSendingMessage = true;
      _chatController.clear();
    });

    try {
      // Get Firebase auth token
      final authService = Provider.of<FirebaseAuthService>(context, listen: false);
      final token = await authService.getIdToken();

      if (token == null) {
        setState(() {
          _chatMessages.add({'role': 'ai', 'content': 'Authentication error'});
          _isSendingMessage = false;
        });
        return;
      }

      final currentParams = <String, dynamic>{};
      if (visualiserTemplate != null) {
        visualiserTemplate!.parameters.forEach((k, v) => currentParams[k] = v.value);
      }

      print("💬 Sending chat: $text");

      // Call unified chat endpoint
      final res = await http.post(
        Uri.parse("$serverIp/chat/ask"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "user_prompt": text,
          "topic": widget.topic,
          "variables": widget.variables,
          "image_path": widget.imagePath,
          "current_params": currentParams,
          "template_id": visualiserTemplate?.templateId,
        }),
      );

      print("💬 Response status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("💬 Response: ${data['response']}");
        print("💬 Update type: ${data['update_type']}");
        
        // Handle parameter updates if any
        if (data['parameter_updates'] != null && 
            data['parameter_updates'].isNotEmpty) {
          print("💬 Updating parameters: ${data['parameter_updates']}");
          _updateVisualiserWidget(
            visualiserTemplate!.templateId,
            data['parameter_updates']
          );
        }
        
        setState(() {
          _chatMessages.add({'role': 'ai', 'content': data['response']});
          _isSendingMessage = false;
        });
      } else {
        setState(() {
          _chatMessages.add({'role': 'ai', 'content': "Error: ${res.statusCode}"});
          _isSendingMessage = false;
        });
      }
    } catch (e) {
      print("❌ Chat error: $e");
      setState(() {
        _chatMessages.add({'role': 'ai', 'content': "Connection failed: $e"});
        _isSendingMessage = false;
      });
    }
  }'''

# Try to find and replace
content_new = re.sub(old_send_message, new_send_message, content, flags=re.MULTILINE)

if content_new == content:
    print("WARNING: Pattern not found, trying alternative approach...")
    # If regex didn't work, we need to handle it differently
    print("Original file preserved")
else:
    # Write back
    with open(r'c:\Users\Nihil\Desktop\projects\stemly\stemly_app\lib\screens\scan_result_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content_new)
    print("✅ File updated successfully!")
    print("Changes made:")
    print("1. Added Provider and Firebase auth imports")
    print("2. Replaced _sendMessage() to use /chat/ask endpoint")
