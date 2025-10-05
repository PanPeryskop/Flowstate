import 'package:flutter/material.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/widgets/brewing_stats_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CoffeeAnalysisScreen extends StatefulWidget {
  final Coffee coffee;

  const CoffeeAnalysisScreen({super.key, required this.coffee});

  @override
  State<CoffeeAnalysisScreen> createState() => _CoffeeAnalysisScreenState();
}

class _CoffeeAnalysisScreenState extends State<CoffeeAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Brewing>> _brewingsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBrewings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBrewings() {
    _brewingsFuture = context.read<DatabaseService>().getBrewingsForCoffee(
      widget.coffee.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.coffee.name} Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Grind Size'),
            Tab(text: 'Temperature'),
            Tab(text: 'Ratio'),
            Tab(text: 'Total Water'),
            Tab(text: 'Brew Time'),
          ],
        ),
      ),
      body: FutureBuilder<List<Brewing>>(
        future: _brewingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          final brewings = snapshot.data ?? [];

          if (brewings.length < 2) {
            return const Center(
              child: Text('You need at least two brewings to see analytics'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              BrewingStatsChart(
                brewings: brewings,
                title: 'Grind Size vs. Rating',
                xAxisLabel: 'Date',
                yAxisLabel: 'Grind Size',
                getValue: (brewing) {
                  final numericValue = RegExp(
                    r'(\d+\.?\d*)',
                  ).firstMatch(brewing.grindSetting)?.group(1);
                  return double.tryParse(numericValue ?? '0') ?? 0;
                },
                getLabel: (brewing) =>
                    DateFormat('MM/dd').format(brewing.brewDate),
              ),

              BrewingStatsChart(
                brewings: brewings,
                title: 'Water Temperature vs. Rating',
                xAxisLabel: 'Date',
                yAxisLabel: 'Temperature (°C)',
                getValue: (brewing) => brewing.waterTemperature,
                getLabel: (brewing) =>
                    DateFormat('MM/dd').format(brewing.brewDate),
              ),

              BrewingStatsChart(
                brewings: brewings,
                title: 'Brew Ratio vs. Rating',
                xAxisLabel: 'Date',
                yAxisLabel: 'Ratio (1:X)',
                getValue: (brewing) => brewing.ratio,
                getLabel: (brewing) =>
                    DateFormat('MM/dd').format(brewing.brewDate),
              ),

              BrewingStatsChart(
                brewings: brewings,
                title: 'Total Water vs. Rating',
                xAxisLabel: 'Date',
                yAxisLabel: 'Water (ml)',
                getValue: (brewing) => brewing.totalWater,
                getLabel: (brewing) =>
                    DateFormat('MM/dd').format(brewing.brewDate),
              ),

              BrewingStatsChart(
                brewings: brewings,
                title: 'Brew Time vs. Rating',
                xAxisLabel: 'Date',
                yAxisLabel: 'Time (sec)',
                getValue: (brewing) =>
                    brewing.totalBrewTime.inSeconds.toDouble(),
                getLabel: (brewing) =>
                    DateFormat('MM/dd').format(brewing.brewDate),
              ),
            ],
          );
        },
      ),
    );
  }
}
