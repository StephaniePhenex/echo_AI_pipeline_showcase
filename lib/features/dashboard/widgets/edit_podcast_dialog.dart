import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/podcast_model.dart';
import '../../../providers/app_strings_provider.dart';

class EditPodcastDialog extends ConsumerStatefulWidget {
  const EditPodcastDialog({
    super.key,
    required this.podcast,
    required this.onUpdated,
  });

  final Podcast podcast;
  final VoidCallback onUpdated;

  @override
  ConsumerState<EditPodcastDialog> createState() => _EditPodcastDialogState();
}

class _EditPodcastDialogState extends ConsumerState<EditPodcastDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rssUrlController;
  late bool _enableEnTts;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.podcast.name);
    _rssUrlController = TextEditingController(text: widget.podcast.rssUrl ?? '');
    _enableEnTts = widget.podcast.enableEnTts;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rssUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('podcasts').update({
        'name': _nameController.text.trim(),
        'rss_url': _rssUrlController.text.trim().isEmpty
            ? null
            : _rssUrlController.text.trim(),
        'enable_en_tts': _enableEnTts,
      }).eq('id', widget.podcast.id);
      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return AlertDialog(
      title: Text(s.editPodcast),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: s.podcastName),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.enterName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rssUrlController,
                decoration: InputDecoration(
                  labelText: s.rssUrlLabel,
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _enableEnTts,
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _enableEnTts = v ?? false),
                title: Text(s.enableEnglishTts),
                subtitle: Text(s.enableEnglishTtsHint),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.save),
        ),
      ],
    );
  }
}
