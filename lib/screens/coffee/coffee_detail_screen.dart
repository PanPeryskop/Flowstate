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

class _CoffeeDetailScreenState extends State<CoffeeDetailScreen> {
  late Future<List<Brewing>> _brewingsFuture;
  bool _sortByDateDesc = true; 

  @override
  void initState() {
    super.initState();
    _loadBrewings();
  }

  Future<void> _loadBrewings() async {
    _brewingsFuture = context.read<DatabaseService>()
        .getBrewingsForCoffee(widget.coffee.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: widget.coffee.imageUrl != null ? 220.0 : 180.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.coffee.name),
                background: widget.coffee.imageUrl != null
                  ? widget.coffee.imageUrl!.startsWith('http')
                    ? Image.network(
                      widget.coffee.imageUrl!,
                      fit: BoxFit.cover,
                    )
                    : Image.file(
                      File(widget.coffee.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
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
                        coffee: widget.coffee,
                      ),
                    ),
                  );
                  setState(() {
                    _loadBrewings();
                  });
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
                        coffee: widget.coffee,
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
                        content: const Text(
                            'Are you sure you want to delete this coffee? All brewing records will also be deleted.'),
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
                      await context
                          .read<DatabaseService>()
                          .deleteCoffee(widget.coffee.id);
                      if (mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.coffee.roaster.isNotEmpty)
                        _buildInfoRow('Roaster', widget.coffee.roaster),
                      if (widget.coffee.origin.isNotEmpty)
                        _buildInfoRow('Origin', widget.coffee.origin),
                      if (widget.coffee.flavorProfile.isNotEmpty)
                        _buildInfoRow('Flavor Profile', widget.coffee.flavorProfile),
                      if (widget.coffee.roastDate != null)
                        _buildInfoRow('Roast Date',
                            DateFormat('MMMM d, y').format(widget.coffee.roastDate!)),
                      _buildInfoRow('Added',
                          DateFormat('MMMM d, y').format(widget.coffee.createdAt)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Brewing History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(_sortByDateDesc ? Icons.arrow_downward : Icons.arrow_upward),
                    onPressed: () {
                      setState(() {
                        _sortByDateDesc = !_sortByDateDesc;
                      });
                    },
                    tooltip: _sortByDateDesc ? 'Newest first' : 'Oldest first',
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Brewing>>(
            future: _brewingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No brewing records yet.\nAdd your first brew!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              } else {
                final brewings = snapshot.data!;
                
                brewings.sort((a, b) {
                  if (_sortByDateDesc) {
                    return b.brewDate.compareTo(a.brewDate);
                  } else {
                    return a.brewDate.compareTo(b.brewDate);
                  }
                });
                
                return SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final brewing = brewings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: BrewingCard(
                            brewing: brewing,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BrewingFormScreen(
                                    coffee: widget.coffee,
                                    brewing: brewing,
                                  ),
                                ),
                              ).then((_) {
                                setState(() {
                                  _loadBrewings();
                                });
                              });
                            },
                          ),
                        );
                      },
                      childCount: brewings.length,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrewingFormScreen(
                coffee: widget.coffee,
              ),
            ),
          ).then((_) {
            setState(() {
              _loadBrewings();
            });
          });
        },
        label: const Text('Add Brewing'),
        icon: const Icon(Icons.add),
        backgroundColor: FlowstateTheme.secondaryColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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