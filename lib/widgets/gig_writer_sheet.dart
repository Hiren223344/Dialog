import 'package:flutter/material.dart';

import '../models/gig.dart';
import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

/// The writing surface for a gig -- the core creative action the whole
/// design doc is built around (§1, §4.3 "Gigs").
class GigWriterSheet extends StatefulWidget {
  final GigDef def;
  final void Function(String text) onPost;

  const GigWriterSheet({super.key, required this.def, required this.onPost});

  @override
  State<GigWriterSheet> createState() => _GigWriterSheetState();
}

class _GigWriterSheetState extends State<GigWriterSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your ${def.name}',
            style: const TextStyle(
              color: StudioColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${def.likeTarget} likes to go viral',
            style: const TextStyle(color: StudioColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLength: def.charLimit,
            maxLines: 4,
            autofocus: true,
            style: const TextStyle(color: StudioColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black26,
              hintText: 'Type something worth talking about...',
              hintStyle: const TextStyle(color: StudioColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () {
                      StudioSfx.play(SfxCue.tap);
                      widget.onPost(_controller.text.trim());
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: StudioColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
