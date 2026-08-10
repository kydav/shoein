import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(earningsProvider);
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final hasData = e.lifetimePaid > 0 || e.outstanding > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: !hasData
          ? const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No earnings yet',
              message:
                  'Log visits with a cost and mark them paid — your income and '
                  'trends will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'This month',
                        value: money.format(e.thisMonthPaid),
                        sub:
                            '${e.visitsThisMonth} ${e.visitsThisMonth == 1 ? 'visit' : 'visits'} paid',
                        accent: kForge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Outstanding',
                        value: money.format(e.outstanding),
                        sub: 'unpaid',
                        accent: e.outstanding > 0 ? kOverdueRed : kForge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'This year',
                        value: money.format(e.ytdPaid),
                        sub: '${DateTime.now().year}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'All time',
                        value: money.format(e.lifetimePaid),
                        sub: 'paid to date',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Last 6 months',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SoftCard(
                  child: SizedBox(
                    height: 200,
                    child: _EarningsChart(months: e.monthly),
                  ),
                ),
                if (e.topClients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Top clients',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (final c in e.topClients)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  money.format(c.total),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kForge),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? accent;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<MonthEarning> months;
  const _EarningsChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final maxPaid = months.fold<double>(0, (m, e) => e.paid > m ? e.paid : m);
    final maxY = maxPaid <= 0 ? 100.0 : maxPaid * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => kAnvil,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              money.format(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.MMM().format(months[i].month),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: months[i].paid,
                  color: kForge,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
