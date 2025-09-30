import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/widgets/star_rating.dart';

class BrewingCard extends StatelessWidget {
  final Brewing brewing;
  final VoidCallback onTap;

  const BrewingCard({
    super.key,
    required this.brewing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = brewing.totalBrewTime.inMinutes;
    final seconds = brewing.totalBrewTime.inSeconds % 60;
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMd().format(brewing.brewDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  StarRating(
                    rating: brewing.rating,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    context,
                    Icons.coffee,
                    '${brewing.coffeeDose}g',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.grain, 
                    brewing.grindSetting,
                  ),
                  _buildInfoChip(
                    context,
                    Icons.thermostat,
                    '${brewing.waterTemperature.round()}°C',
                  ),
                  _buildInfoChip(
                    context,
                    Icons.timer,
                    timeString,
                  ),
                ],
              ),
              if (brewing.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes:',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  brewing.notes,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}