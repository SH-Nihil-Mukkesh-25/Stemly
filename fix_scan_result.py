import re

# Read the file
with open(r"c:\Users\Nihil\Desktop\projects\stemly\stemly_app\lib\screens\scan_result_screen.dart", 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the problematic section (lines 229-301, 0-indexed: 228-300)
# We need to:
# 1. Keep line 229: "            _visualiser(deepBlue),"
# 2. Keep line 230: "            _notes(cardColor, deepBlue),"
# 3. Delete lines 231-301 (the broken code)
# 4. Add closing brackets for TabBarView, body, Scaffold
# 5. Add the _visualiser method

# Keep lines 0-230 (up to and including "_notes(cardColor, deepBlue),")
new_lines = lines[:230]

# Add the missing closing brackets and the _visualiser method
visualiser_code = """          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // VISUALISER TAB
  // ---------------------------------------------------------
  Widget _visualiser(Color deepBlue) {
    if (loadingVisualiser) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: deepBlue),
            const SizedBox(height: 16),
            Text(
              "Loading Visualiser...",
              style: TextStyle(
                color: deepBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (visualiserWidget == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: deepBlue.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "Visualiser Not Available",
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Unable to load visualisation for this topic",
                style: TextStyle(color: deepBlue.withOpacity(0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Display the visualiser widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: deepBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: visualiserWidget!,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

"""

new_lines.append(visualiser_code)

# Add the rest of the file (from line 302 onwards, 0-indexed: 301)
new_lines.extend(lines[301:])

# Write the fixed file
with open(r"c:\Users\Nihil\Desktop\projects\stemly\stemly_app\lib\screens\scan_result_screen.dart", 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ File fixed successfully!")
print(f"✅ Removed {301 - 230} lines of broken chat code")
print("✅ Added _visualiser widget method")
