import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/theme/flowstate_theme.dart';

class CoffeeCard extends StatefulWidget {
  final Coffee coffee;
  final VoidCallback onTap;

  const CoffeeCard({super.key, required this.coffee, required this.onTap});

  @override
  State<CoffeeCard> createState() => _CoffeeCardState();
}

class _CoffeeCardState extends State<CoffeeCard> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _statsFuture = context.read<DatabaseService>().getCoffeeStats(
      widget.coffee.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.coffee.imageUrl != null)
              _buildCoffeeImage(widget.coffee.imageUrl!)
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FlowstateTheme.primaryColor.withOpacity(0.8),
                      FlowstateTheme.accentColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.coffee,
                    size: 48,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.coffee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.coffee.roaster.isNotEmpty)
                    Text(
                      widget.coffee.roaster,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.coffee.origin.isNotEmpty)
                        Chip(
                          padding: EdgeInsets.zero,
                          backgroundColor: FlowstateTheme.accentColor
                              .withOpacity(0.2),
                          label: Text(
                            widget.coffee.origin,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const Spacer(),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();

                          final stats = snapshot.data!;
                          final brewCount = stats['brewCount'] as int;
                          final maxRating = stats['maxRating'] as int;

                          return Row(
                            children: [
                              Text(
                                '$brewCount brews',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              if (brewCount > 0) ...[
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: FlowstateTheme.secondaryColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$maxRating',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(imageUrl),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.grey),
          );
        },
      );
    }
  }
}
