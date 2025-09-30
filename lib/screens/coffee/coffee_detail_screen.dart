import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/screens/coffee_form/coffee_form_screen.dart';
import 'package:flowstate/screens/brewing_form/brewing_form_screen.dart';
import 'package:flowstate/screens/coffee/brewing_card.dart';
import 'package:flowstate/theme/flowstate_theme.dart';
import 'coffee_analysis_screen.dart';

class CoffeeDetailScreen extends StatefulWidget {
  final Coffee coffee;

  const CoffeeDetailScreen({
    super.key,
    required this.coffee,
  });

  @override
  State<CoffeeDetailScreen> createState() => _CoffeeDetailScreenState();
}

class _CoffeeDetailScreenState extends State<CoffeeDetailScreen> with AutomaticKeepAliveClientMixin<CoffeeDetailScreen> {
  final DateFormat _dateFormatter = DateFormat('MMMM d, y');
  List<Brewing> _brewings = [];
  bool _isLoading = true;
  Object? _error;
  bool _sortByDateDesc = true;

  @override
  void initState() {
    super.initState();
    _loadBrewings();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadBrewings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final brewings = await context.read<DatabaseService>().getBrewingsForCoffee(widget.coffee.id);
      if (!mounted) return;
      setState(() {
        _brewings = _applySort(brewings);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  List<Brewing> _applySort(List<Brewing> brewings) {
    final sorted = List<Brewing>.from(brewings);
    sorted.sort((a, b) {
      if (_sortByDateDesc) {
        return b.brewDate.compareTo(a.brewDate);
      }
      return a.brewDate.compareTo(b.brewDate);
    });
    return sorted;
  }

  void _toggleSort() {
    setState(() {
      _sortByDateDesc = !_sortByDateDesc;
      _brewings = _applySort(_brewings);
    });
  }

  Future<void> _openBrewingForm({Brewing? brewing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewingFormScreen(
          coffee: widget.coffee,
          brewing: brewing,
        ),
      ),
    );
    if (!mounted) return;
    await _loadBrewings();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final coffee = widget.coffee;
    final media = coffee.imageUrl;
    final hasImage = media != null;
    final sliverContent = _buildBrewingsSliver(theme);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 220 : 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(coffee.name),
              background: hasImage
                  ? media!.startsWith('http')
                      ? Image.network(media, fit: BoxFit.cover)
                      : Image.file(File(media), fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoffeeFormScreen(
                        coffee: coffee,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  await _loadBrewings();
                },
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoffeeAnalysisScreen(
                        coffee: coffee,
                      ),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Coffee'),
                        content: const Text('Are you sure you want to delete this coffee? All brewing records will also be deleted.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    );
                    if (confirm ?? false) {
                      await context.read<DatabaseService>().deleteCoffee(coffee.id);
                      if (mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coffee.roaster.isNotEmpty) _buildInfoRow(context, 'Roaster', coffee.roaster),
                      if (coffee.origin.isNotEmpty) _buildInfoRow(context, 'Origin', coffee.origin),
                      if (coffee.flavorProfile.isNotEmpty) _buildInfoRow(context, 'Flavor Profile', coffee.flavorProfile),
                      if (coffee.roastDate != null) _buildInfoRow(context, 'Roast Date', _dateFormatter.format(coffee.roastDate!)),
                      _buildInfoRow(context, 'Added', _dateFormatter.format(coffee.createdAt)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Brewing History',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(_sortByDateDesc ? Icons.arrow_downward : Icons.arrow_upward),
                    onPressed: _toggleSort,
                    tooltip: _sortByDateDesc ? 'Newest first' : 'Oldest first',
                  ),
                ],
              ),
            ),
          ),
          sliverContent,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBrewingForm(),
        label: const Text('Add Brewing'),
        icon: const Icon(Icons.add),
        backgroundColor: FlowstateTheme.secondaryColor,
      ),
    );
  }

  Widget _buildBrewingsSliver(ThemeData theme) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'Error: $_error',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    if (_brewings.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No brewing records yet.\nAdd your first brew!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final brewing = _brewings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BrewingCard(
                brewing: brewing,
                onTap: () => _openBrewingForm(brewing: brewing),
              ),
            );
          },
          childCount: _brewings.length,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}