import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/echo_colors.dart';
import '../../data/podcast_model.dart';
import '../../providers/app_strings_provider.dart';
import '../../providers/podcasts_provider.dart';
import '../widgets/locale_toggle_text_button.dart';
import 'widgets/edit_podcast_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final podcastsAsync = ref.watch(creatorPodcastsProvider);

    return Scaffold(
      body: podcastsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${s.loadFailedPrefix}$e',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(creatorPodcastsProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
        data: (podcasts) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      s.dashboardBreadcrumbList,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EchoColors.textSecondary,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LocaleToggleTextButton(),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) context.go('/');
                          },
                          tooltip: s.logoutTooltip,
                          style: IconButton.styleFrom(
                            foregroundColor: EchoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (podcasts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(child: Text(s.noPodcastsYet)),
                  )
                else
                  ...podcasts.map((p) => _PodcastCard(
                        podcast: p,
                        onTap: () =>
                            context.push('/dashboard/podcasts/${p.id}'),
                        onEdit: () => _showEditDialog(context, ref, p),
                        onDelete: () => _showDeleteConfirm(context, ref, p),
                      )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: podcastsAsync.whenOrNull(
        data: (podcasts) => FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, ref),
          backgroundColor: EchoColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(s.createPodcast),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreatePodcastDialog(
        onCreated: () {
          ref.invalidate(creatorPodcastsProvider);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Podcast podcast) {
    showDialog(
      context: context,
      builder: (_) => EditPodcastDialog(
        podcast: podcast,
        onUpdated: () {
          ref.invalidate(creatorPodcastsProvider);
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Podcast podcast) {
    final s = ref.read(appStringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deletePodcast),
        content: Text(s.deletePodcastConfirm(podcast.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('podcasts')
                  .delete()
                  .eq('id', podcast.id);
              ref.invalidate(creatorPodcastsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) context.go('/dashboard');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  const _PodcastCard({
    required this.podcast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Podcast podcast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFF0F0F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.slug,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EchoColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => onEdit(),
                color: EchoColors.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(),
                color: EchoColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePodcastDialog extends ConsumerStatefulWidget {
  const _CreatePodcastDialog({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreatePodcastDialog> createState() =>
      _CreatePodcastDialogState();
}

class _CreatePodcastDialogState extends ConsumerState<_CreatePodcastDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rssUrlController = TextEditingController();
  final _slugController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String _generateSlug(String name) {
    final s = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return s.isNotEmpty ? s : 'podcast_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rssUrlController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = ref.read(appStringsProvider);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception(s.notLoggedIn);

      final slug = _slugController.text.trim().isNotEmpty
          ? _slugController.text.trim().toLowerCase().replaceAll(' ', '_')
          : _generateSlug(_nameController.text);
      final rssUrl = _rssUrlController.text.trim();
      await Supabase.instance.client.from('podcasts').insert({
        'slug': slug,
        'name': _nameController.text.trim(),
        'rss_url': rssUrl.isEmpty ? null : rssUrl,
        'creator_id': user.id,
      });
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        final msg = e is PostgrestException && e.code == '23505'
            ? s.slugInUse
            : e.toString();
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return AlertDialog(
      title: Text(s.createPodcastTitle),
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
                  labelText: s.rssUrl,
                  hintText: 'https://...',
                  helperText: s.rssUrlHelper,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slugController,
                decoration: InputDecoration(
                  labelText: s.slugOptional,
                  hintText: s.slugHint,
                  helperText: s.slugHelper,
                ),
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      !RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim())) {
                    return s.slugInvalid;
                  }
                  return null;
                },
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
          style: FilledButton.styleFrom(backgroundColor: EchoColors.primary),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.create),
        ),
      ],
    );
  }
}
