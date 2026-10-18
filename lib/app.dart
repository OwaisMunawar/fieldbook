import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'core/design.dart';
import 'features/notebook/application/notebook_controller.dart';
import 'features/notebook/data/report_share.dart';
import 'features/notebook/domain/models.dart';
import 'features/notebook/presentation/actions_page.dart';
import 'features/notebook/presentation/notebook_page.dart';
import 'features/notebook/presentation/report_page.dart';
import 'features/notebook/presentation/review_screen.dart';
import 'features/notebook/presentation/search_page.dart';

class FieldbookApp extends StatelessWidget {
  const FieldbookApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fieldbook',
    debugShowCheckedModeBanner: false,
    theme: notebookTheme(),
    home: const _NotebookLoader(),
  );
}

class _NotebookLoader extends ConsumerWidget {
  const _NotebookLoader();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(notebookProvider)
      .when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Opening notebook',
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not open the notebook. Your saved data has not been reset.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(notebookProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        data: (controller) => NotebookShell(controller: controller),
      );
}

class NotebookShell extends StatefulWidget {
  const NotebookShell({
    super.key,
    required this.controller,
    this.share = shareNotebookReport,
  });
  final NotebookController controller;
  final Future<void> Function(NotebookSnapshot, Rect) share;
  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  int index = 0;
  void open(Evidence evidence) {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReviewScreen(controller: widget.controller, evidence: evidence),
      ),
    );
  }

  Future<void> capture() async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final evidence = await widget.controller.importPhoto(camera: source);
    if (evidence != null) open(evidence);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.layers_outlined, color: Palette.accent),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Fieldbook',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reload notebook',
              onPressed: controller.busy ? null : controller.reload,
              icon: const Icon(Icons.refresh),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Tag(
                  controller.demo ? 'DEMO' : 'ON DEVICE',
                  active: true,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (controller.error != null)
                FailureBanner(
                  message: controller.error!.message,
                  dismiss: controller.clearError,
                ),
              if (controller.busy)
                const LinearProgressIndicator(
                  semanticsLabel: 'Processing on device',
                ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('page-$index'),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: switch (index) {
                        0 => NotebookPage(
                          controller: controller,
                          open: open,
                          capture: capture,
                        ),
                        1 => ActionsPage(controller: controller),
                        2 => SearchPage(
                          evidence: controller.snapshot.evidence,
                          open: open,
                        ),
                        _ => ReportPage(
                          snapshot: controller.snapshot,
                          share: widget.share,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Notebook',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              label: 'Actions',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Find'),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Report',
            ),
          ],
        ),
      );
    },
  );
}
