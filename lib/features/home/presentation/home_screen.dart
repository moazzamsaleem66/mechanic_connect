import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_surface_card.dart';
import '../../shared/widgets/app_text_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mechanic Connect'),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Track requests and access quick actions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const AppSurfaceCard(
                      child: AppTextField(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (isWide)
                      const Row(
                        children: [
                          Expanded(child: _QuickActionsCard()),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(child: _SignalCard()),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          _QuickActionsCard(),
                          SizedBox(height: AppSpacing.lg),
                          _SignalCard(),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Actions',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          const Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              _ActionCircle(
                                icon: Icons.auto_awesome_outlined,
                                color: AppColors.primary,
                              ),
                              _ActionCircle(
                                icon: Icons.change_history_outlined,
                                color: Color(0xFFA8561B),
                              ),
                              _ActionCircle(
                                icon: Icons.local_offer_outlined,
                                color: Color(0xFF2E2400),
                              ),
                              _ActionCircle(
                                icon: Icons.delete_outline,
                                color: Color(0xFFC63528),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIconButton(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                isSelected: _selectedNavIndex == 0,
                onTap: () => setState(() => _selectedNavIndex = 0),
              ),
              _NavIconButton(
                icon: Icons.search,
                selectedIcon: Icons.search,
                isSelected: _selectedNavIndex == 1,
                onTap: () => setState(() => _selectedNavIndex = 1),
              ),
              _NavIconButton(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                isSelected: _selectedNavIndex == 2,
                onTap: () => setState(() => _selectedNavIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: AppPrimaryButton(label: 'Primary', onPressed: () {})),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child:
                      AppSecondaryButton(label: 'Secondary', onPressed: () {})),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Inverted'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child:
                      AppSecondaryButton(label: 'Outlined', onPressed: () {})),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard();

  @override
  Widget build(BuildContext context) {
    return const AppSurfaceCard(
      child: Column(
        children: [
          _SignalLine(color: AppColors.primary, widthFactor: 0.72),
          SizedBox(height: AppSpacing.md),
          _SignalLine(color: Color(0xFFA8561B), widthFactor: 0.86),
          SizedBox(height: AppSpacing.md),
          _SignalLine(color: Color(0xFF2E2400), widthFactor: 0.56),
        ],
      ),
    );
  }
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({
    required this.color,
    required this.widthFactor,
  });

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 8,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            Container(
              height: 8,
              width: constraints.maxWidth * widthFactor,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          size: 22,
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
