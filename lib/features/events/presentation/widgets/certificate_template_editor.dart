import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uems/app/theme.dart';

class CertificateTemplateEditor extends StatefulWidget {
  final File templateImage;
  final Function(Map<String, dynamic>) onConfigChanged;

  const CertificateTemplateEditor({
    super.key,
    required this.templateImage,
    required this.onConfigChanged,
  });

  @override
  State<CertificateTemplateEditor> createState() => _CertificateTemplateEditorState();
}

class _CertificateTemplateEditorState extends State<CertificateTemplateEditor> {
  // Config state
  double _nameX = 0.5; // Center
  double _nameY = 0.4;
  double _rollX = 0.5;
  double _rollY = 0.5;
  
  // Layout state
  final GlobalKey _imageKey = GlobalKey();
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Initialize with default config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateConfig();
    });
  }

  void _updateConfig() {
    widget.onConfigChanged({
      'studentName': {'x': _nameX, 'y': _nameY, 'fontSize': 24, 'color': '#000000'},
      'rollNumber': {'x': _rollX, 'y': _rollY, 'fontSize': 18, 'color': '#000000'},
    });
  }

  void _onLayout(Size size) {
    if (_imageSize != size) {
      setState(() {
        _imageSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor Area
        Container(
          width: double.infinity,
          height: 300, // Fixed height for preview
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[200],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                   // Background Image
                   Image.file(
                     widget.templateImage,
                     fit: BoxFit.contain, // Maintain aspect ratio
                     key: _imageKey,
                   ),
                   
                   // Student Name
                   _buildSmoothDraggableItem(
                     label: '[Student Name]',
                     x: _nameX,
                     y: _nameY,
                     constraints: constraints,
                     onDragUpdate: (dx, dy) {
                       setState(() {
                         _nameX = (_nameX + dx).clamp(0.0, 1.0);
                         _nameY = (_nameY + dy).clamp(0.0, 1.0);
                       });
                       _updateConfig();
                     },
                     style: const TextStyle(
                       fontSize: 16, 
                       fontWeight: FontWeight.bold,
                       color: Colors.black,
                       backgroundColor: Colors.white54,
                     ),
                   ),

                   // Roll No
                   _buildSmoothDraggableItem(
                     label: '[Roll No]',
                     x: _rollX,
                     y: _rollY,
                     constraints: constraints,
                     onDragUpdate: (dx, dy) {
                       setState(() {
                         _rollX = (_rollX + dx).clamp(0.0, 1.0);
                         _rollY = (_rollY + dy).clamp(0.0, 1.0);
                       });
                       _updateConfig();
                     },
                     style: const TextStyle(
                       fontSize: 12, 
                       color: Colors.black,
                       backgroundColor: Colors.white54,
                     ),
                   ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        const Text(
          '💡 Drag the text boxes to position them precisely.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSmoothDraggableItem({
    required String label,
    required double x,
    required double y,
    required BoxConstraints constraints,
    required Function(double dx, double dy) onDragUpdate,
    required TextStyle style,
  }) {
    // Convert percentage (0-1) to pixels
    final double left = x * constraints.maxWidth;
    final double top = y * constraints.maxHeight;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Convert pixel delta to percentage delta
          final double dx = details.delta.dx / constraints.maxWidth;
          final double dy = details.delta.dy / constraints.maxHeight;
          onDragUpdate(dx, dy);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.drag_indicator, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

