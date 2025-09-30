import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/widgets/star_rating.dart';

class BrewingCard extends StatelessWidget {
  final Brewing brewing;
  final VoidCallback onTap;
  
  final String formattedDate;
  final String timeString;
  final String temperatureString;
  final String doseString;

  BrewingCard({
    super.key,
    required this.brewing,
    required this.onTap,
  }) : formattedDate = DateFormat.yMMMd().format(brewing.brewDate),
       timeString = '${brewing.totalBrewTime.inMinutes}:${(brewing.totalBrewTime.inSeconds % 60).toString().padLeft(2, '0')}',
       temperatureString = '${brewing.waterTemperature.round()}°C',
       doseString = '${brewing.coffeeDose}g';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const Divider(height: 24),
                _buildInfoRow(context),
                if (brewing.notes.isNotEmpty)
                  _buildNotes(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formattedDate,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        StarRating(
          rating: brewing.rating,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = theme.textTheme.bodyMedium;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoChip(context, Icons.coffee, doseString, primaryColor, textStyle),
        _buildInfoChip(context, Icons.grain, brewing.grindSetting, primaryColor, textStyle),
        _buildInfoChip(context, Icons.thermostat, temperatureString, primaryColor, textStyle),
        _buildInfoChip(context, Icons.timer, timeString, primaryColor, textStyle),
      ],
    );
  }

  Widget _buildNotes(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Notes:',
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          brewing.notes,
          style: theme.textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text, Color color, TextStyle? style) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(text, style: style),
      ],
    );
  }
}