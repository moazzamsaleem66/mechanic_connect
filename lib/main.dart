import 'package:flutter/material.dart';

import 'theme/theme.dart';

void main() {
  runApp(const MechanicConnectApp());
}

class MechanicConnectApp extends StatelessWidget {
  const MechanicConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mechanic Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ThemePreviewPage(),
    );
  }
}

class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mechanic Connect')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Headline Style', style: textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Body text style and neutral content tone.',
              style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          const _ColorTokensCard(),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Primary')),
              FilledButton(onPressed: () {}, child: const Text('Inverted')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ColorTokensCard extends StatelessWidget {
  const _ColorTokensCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color Tokens'),
            SizedBox(height: AppSpacing.md),
            _ColorRow(
                name: 'Primary', hex: '#002E6E', color: AppColors.primary),
            SizedBox(height: AppSpacing.sm),
            _ColorRow(
                name: 'Secondary', hex: '#FF6D00', color: AppColors.secondary),
            SizedBox(height: AppSpacing.sm),
            _ColorRow(
                name: 'Tertiary', hex: '#FFC107', color: AppColors.tertiary),
            SizedBox(height: AppSpacing.sm),
            _ColorRow(
                name: 'Neutral', hex: '#F8F9FA', color: AppColors.neutral),
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.name,
    required this.hex,
    required this.color,
  });

  final String name;
  final String hex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium)),
        Text(hex, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
