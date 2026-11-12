import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/state_views.dart';
import '../../models/testimonial.dart';
import '../../services/profile_service.dart';

/// A recipient can share one story. It shows on the website after admin approval.
class ShareStoryScreen extends StatefulWidget {
  const ShareStoryScreen({super.key});

  @override
  State<ShareStoryScreen> createState() => _ShareStoryScreenState();
}

class _ShareStoryScreenState extends State<ShareStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _content = TextEditingController();
  late Future<Testimonial?> _future = _load();
  bool _saving = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<Testimonial?> _load() => context.read<ProfileService>().testimonial();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final message = await context.read<ProfileService>().submitTestimonial(_content.text.trim());
      if (!mounted) return;
      showSuccess(context, message);
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(tr('story.title'))),
      body: FutureView<Testimonial?>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, story) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.format_quote_rounded, size: 40, color: AppColors.red),
            const SizedBox(height: 8),
            Text(tr('story.heading'), style: AppFonts.heading(size: 24, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(tr('story.subtitle'), style: AppFonts.body(color: AppColors.muted)),
            const SizedBox(height: 20),
            if (story != null) _Submitted(story: story) else _form(),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _content,
            builder: (context, value, _) => AppTextField(
              label: tr('story.field'),
              controller: _content,
              hint: tr('story.hint'),
              maxLines: 7,
              maxLength: 1000,
              helper: '${localizeDigits(value.text.length)} / ${localizeDigits(1000)}',
              validator: (text) => (text?.trim().length ?? 0) < 10 ? tr('story.min') : null,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(label: tr('common.submit'), icon: Icons.send_outlined, loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}

class _Submitted extends StatelessWidget {
  const _Submitted({required this.story});

  final Testimonial story;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          story.isApproved
              ? AppBadge(tr('story.approved'), tone: BadgeTone.green)
              : AppBadge(tr('story.pending'), tone: BadgeTone.amber),
          const SizedBox(height: 10),
          Text(story.content, style: AppFonts.body()),
          if (!story.isApproved) ...[
            const SizedBox(height: 10),
            Text(tr('story.pending_text'), style: AppFonts.body(size: 13.5, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
