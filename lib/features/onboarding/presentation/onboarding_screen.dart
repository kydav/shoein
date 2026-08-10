import 'package:flutter/material.dart';
import 'package:shoein/core/config/revenue_cat_config.dart';
import 'package:shoein/core/services/notification_service.dart';
import 'package:shoein/core/theme/app_theme.dart';

/// First-run intro carousel: what Shoein' is → notifications permission ask →
/// the free trial + subscription. Shown once, gated by `onboardingSeenProvider`.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({required this.onDone, super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _requesting = false;

  static const _lastPage = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _lastPage) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _enableReminders() async {
    setState(() => _requesting = true);
    try {
      await NotificationService.instance.requestPermission();
    } catch (_) {
      // Permission flow can't hard-fail onboarding — just move on.
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _page == _lastPage ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _page == _lastPage ? null : widget.onDone,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomePage(),
                  const _InfoPage(
                    icon: Icons.event_available_outlined,
                    title: 'Never miss a trim',
                    body:
                        'Set each horse’s cycle and Shoein’ tells you who’s due, '
                        'reschedules automatically when you log a visit, and keeps '
                        'your whole day organized.',
                  ),
                  _NotificationsPage(
                    busy: _requesting,
                    onEnable: _enableReminders,
                    onSkip: _next,
                  ),
                  const _InfoPage(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Try it free for $kTrialDays days',
                    body:
                        'Start with full access for $kTrialDays days — no card '
                        'required. After that it’s \$6.99/month or \$49.99/year. '
                        'Your data always stays safe and viewable.',
                  ),
                ],
              ),
            ),
            _Dots(count: _lastPage + 1, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: FilledButton(
                onPressed: _page == 2 ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(switch (_page) {
                  _lastPage => 'Start my free trial',
                  2 => 'Choose an option above',
                  _ => 'Next',
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/shoein_mark.png',
            width: 120,
            height: 120,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Shoein’',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'The simplest way to manage your farrier clients, horses, and trim '
            'schedule — all in one place.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconBadge(icon: icon),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;
  const _NotificationsPage({
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _IconBadge(icon: Icons.notifications_active_outlined),
          const SizedBox(height: 24),
          Text(
            'Stay ahead of every trim',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Turn on reminders and Shoein’ will nudge you the morning a horse is '
            'due — so clients never fall through the cracks.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: busy ? null : onEnable,
            icon: busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.notifications_active_outlined),
            label: const Text('Enable reminders'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          TextButton(
            onPressed: busy ? null : onSkip,
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: kForge.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 46, color: kForge),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? kForge : context.colors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
