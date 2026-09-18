import 'package:flutter/material.dart';

import '../models/gig.dart';
import '../services/studio_sfx.dart';
import '../theme/studio_theme.dart';

/// The writing surface for a gig -- the core creative action the whole
/// design doc is built around (§1, §4.3 "Gigs"), styled as a physical
/// script page pinned to a clapperboard slate rather than a form dialog.
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StudioColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: StudioColors.goldMuted.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _slateHeader(def),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: ${def.likeTarget} likes to go viral',
                    style: const TextStyle(color: StudioColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _paperPage(def),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _slateHeader(GigDef def) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1815),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Row(
            children: List.generate(
              6,
              (i) => Container(
                width: 6,
                height: 16,
                margin: const EdgeInsets.only(right: 3),
                color: i.isEven ? Colors.white : Colors.black,
                transform: Matrix4.skewX(-0.3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Write your ${def.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudioColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paperPage(GigDef def) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6C8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: TextField(
        controller: _controller,
        maxLength: def.charLimit,
        maxLines: 4,
        autofocus: true,
        cursorColor: const Color(0xFF3B2A1C),
        style: const TextStyle(color: Color(0xFF2B1F16), fontSize: 15, height: 1.6),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'Type something worth talking about...',
          hintStyle: TextStyle(color: Color(0xFF9C8B6F)),
          counterStyle: TextStyle(color: Color(0xFF9C8B6F)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
