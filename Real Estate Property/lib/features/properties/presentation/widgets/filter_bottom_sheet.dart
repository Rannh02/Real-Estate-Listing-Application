import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/property.dart';
import '../../bloc/properties_bloc.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  PropertyType? _selectedType;
  double _maxPrice = 2000000;

  @override
  void initState() {
    super.initState();
    final state = context.read<PropertiesBloc>().state;
    _selectedType = state.selectedType;
    _maxPrice = state.maxPrice ?? 2000000;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Property Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: PropertyType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
                selectedColor: Colors.redAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Max Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_maxPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxPrice,
            min: 100000,
            max: 2000000,
            divisions: 19,
            activeColor: Colors.redAccent,
            onChanged: (value) {
              setState(() {
                _maxPrice = value;
              });
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context.read<PropertiesBloc>().add(
                    PropertiesFilterChanged(
                      type: _selectedType,
                      maxPrice: _maxPrice,
                    ),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              context.read<PropertiesBloc>().add(
                    const PropertiesFilterChanged(type: null, maxPrice: null),
                  );
              Navigator.pop(context);
            },
            child: const Text('Reset All', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
