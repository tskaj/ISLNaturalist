import 'package:flutter/material.dart';
import '../services/deepseek_service.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final String speciesName;
  final double confidence;
  final String detectionType;
  final Map<String, dynamic> detectionData;

  const SpeciesDetailScreen({
    Key? key,
    required this.speciesName,
    required this.confidence,
    required this.detectionType,
    required this.detectionData,
  }) : super(key: key);

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _speciesInfo;

  @override
  void initState() {
    super.initState();
    _loadSpeciesInfo();
  }

  Future<void> _loadSpeciesInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use DeepseekService to get information about the species
      final info = await DeepseekService.getSpeciesInformation(
        widget.speciesName,
        widget.detectionType,
      );

      setState(() {
        _speciesInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading species info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.detectionType.capitalize()} Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.speciesName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(widget.confidence * 100).toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (_speciesInfo != null) ..._buildSpeciesInfo(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSpeciesInfo() {
    final List<Widget> widgets = [];

    if (_speciesInfo!.containsKey('description')) {
      widgets.addAll([
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_speciesInfo!['description']),
        const SizedBox(height: 16),
      ]);
    }

    if (_speciesInfo!.containsKey('habitat')) {
      widgets.addAll([
        Text(
          'Habitat',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_speciesInfo!['habitat']),
        const SizedBox(height: 16),
      ]);
    }

    if (_speciesInfo!.containsKey('behavior')) {
      widgets.addAll([
        Text(
          'Behavior',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_speciesInfo!['behavior']),
        const SizedBox(height: 16),
      ]);
    }

    if (_speciesInfo!.containsKey('conservation')) {
      widgets.addAll([
        Text(
          'Conservation Status',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_speciesInfo!['conservation']),
        const SizedBox(height: 16),
      ]);
    }

    return widgets;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}