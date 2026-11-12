import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../services/features_catalog.dart';
import '../services/new_features_service.dart';

class NewFeaturesScreen extends StatefulWidget {
  const NewFeaturesScreen({super.key});

  @override
  State<NewFeaturesScreen> createState() => _NewFeaturesScreenState();
}

class _NewFeaturesScreenState extends State<NewFeaturesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowForNewVersions = false;
  String _appVersion = '1.19.2';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final dontShow = await NewFeaturesService.isDontShowOnUpdateEnabled();
    final ver = await NewFeaturesService.getCurrentAppVersion();
    if (mounted) {
      setState(() {
        _dontShowForNewVersions = dontShow;
        _appVersion = ver;
      });
    }
  }

  @override
  void dispose() {
    NewFeaturesService.isShowing = false;
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _dismissAndMarkSeen() async {
    await NewFeaturesService.markCurrentVersionSeen();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    DataService? ds;
    try {
      ds = context.read<DataService>();
    } catch (_) {
      ds = null;
    }

    final sampleData = FeatureSampleData.fromDataService(ds, l10n);
    final features = FeaturesCatalog.getFeatures();

    final pages = features.map((f) {
      return _buildFeaturePage(
        context: context,
        category: f.category(l10n),
        categoryIcon: f.categoryIcon,
        title: f.title(l10n),
        subtitle: f.subtitle(l10n),
        visualExample: f.visualBuilder(context, sampleData),
        step1Icon: f.step1Icon,
        step1Text: f.step1Text(l10n),
        step2Icon: f.step2Icon,
        step2Text: f.step2Text(l10n),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.newFeaturesTitle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'v$_appVersion',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('new_features_skip_button'),
            onPressed: _dismissAndMarkSeen,
            icon: const Icon(Icons.close, size: 18),
            label: Text(l10n.newFeaturesSkip),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: pages,
              ),
            ),
            _buildBottomControls(context, pages.length),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePage({
    required BuildContext context,
    required String category,
    required IconData categoryIcon,
    required String title,
    required String subtitle,
    required Widget visualExample,
    required IconData step1Icon,
    required String step1Text,
    required IconData step2Icon,
    required String step2Text,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Uniform Category Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 14, color: cs.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2. Uniform Title & Minimal Subtitle
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Central Visual Example Canvas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: visualExample,
              ),
              const SizedBox(height: 14),

              // 4. Uniform 2-Step Guidance Box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStepRow(context, step1Icon, step1Text),
                    Divider(
                      height: 14,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _buildStepRow(context, step2Icon, step2Text),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, int totalPages) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLastPage = _currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Don't show for new versions" checkbox
          InkWell(
            key: const Key('new_features_dont_show_checkbox_tile'),
            onTap: () {
              setState(() {
                _dontShowForNewVersions = !_dontShowForNewVersions;
              });
              NewFeaturesService.setDontShowOnUpdate(_dontShowForNewVersions);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    key: const Key('new_features_dont_show_checkbox'),
                    value: _dontShowForNewVersions,
                    onChanged: (val) {
                      setState(() {
                        _dontShowForNewVersions = val ?? false;
                      });
                      NewFeaturesService.setDontShowOnUpdate(
                          _dontShowForNewVersions);
                    },
                  ),
                  Flexible(
                    child: Text(
                      l10n.newFeaturesDontShowForNewVersions,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Forward / Back / Page Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              if (_currentPage > 0)
                OutlinedButton.icon(
                  key: const Key('new_features_back_button'),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(l10n.newFeaturesBack),
                )
              else
                const SizedBox(width: 85),

              // Page Dots Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPages, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? cs.primary : cs.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),

              // Forward / Done Button
              FilledButton.icon(
                key: const Key('new_features_next_done_button'),
                onPressed: () {
                  if (isLastPage) {
                    _dismissAndMarkSeen();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(isLastPage ? Icons.check : Icons.arrow_forward,
                    size: 16),
                label: Text(
                  isLastPage ? l10n.newFeaturesDone : l10n.newFeaturesNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
