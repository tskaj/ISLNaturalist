import 'package:flutter/material.dart';
import '../services/deepseek_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final String diseaseName;
  final String cropType;
  final Map<String, dynamic>? diseaseInfo;

  const DiseaseDetailScreen({
    Key? key,
    required this.diseaseName,
    required this.cropType,
    this.diseaseInfo,
  }) : super(key: key);

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  bool _isLoading = false;
  String? _treatmentRecommendation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTreatmentRecommendation();
  }

  Future<void> _loadTreatmentRecommendation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the mock service for now to avoid API costs during development
      final result = await DeepSeekService.getMockTreatmentRecommendation(
        widget.diseaseName,
        widget.cropType,
      );

      if (result['success']) {
        setState(() {
          _treatmentRecommendation = result['recommendation'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diseaseName),
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disease Information Section
            if (widget.diseaseInfo != null) _buildDiseaseInfoSection(widget.diseaseInfo!),
            
            // AI Treatment Recommendation Section
            _buildTreatmentRecommendationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseInfoSection(Map<String, dynamic> diseaseInfo) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and gradient background
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.eco, color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Disease Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Description with styled text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Disease',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  diseaseInfo['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Treatments section with cards
          if ((diseaseInfo['treatments'] as List).isNotEmpty) ...[  
            const SizedBox(height: 20),
            _buildSectionHeader('Treatments', Icons.healing),
            const SizedBox(height: 12),
            ...List.generate(
              (diseaseInfo['treatments'] as List).length,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diseaseInfo['treatments'][index],
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Prevention section with cards
          if ((diseaseInfo['prevention'] as List).isNotEmpty) ...[  
            const SizedBox(height: 20),
            _buildSectionHeader('Prevention', Icons.shield),
            const SizedBox(height: 12),
            ...List.generate(
              (diseaseInfo['prevention'] as List).length,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diseaseInfo['prevention'][index],
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentRecommendationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and gradient background
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.smart_toy, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Treatment Recommendation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading recommendations...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Could not load recommendation: $_errorMessage',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            )
          else if (_treatmentRecommendation != null)
            _parseAndDisplayRecommendation(_treatmentRecommendation!)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'No recommendation available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to parse and display the recommendation in a more structured way
  Widget _parseAndDisplayRecommendation(String recommendation) {
    // Parse the recommendation into sections
    Map<String, dynamic> sections = _parseRecommendationSections(recommendation);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disease Information Section
        if (sections['description'] != null && sections['description'].isNotEmpty)
          _buildRecommendationSection(
            'About this Disease',
            sections['description'],
            Colors.blue.shade700,
            Colors.blue.shade50,
            Icons.info_outline,
          ),
          
        const SizedBox(height: 16),
        
        // Treatment Section
        if (sections['treatments'] != null && sections['treatments'].isNotEmpty)
          _buildRecommendationSection(
            'Treatment Recommendations',
            sections['treatments'],
            Colors.green.shade700,
            Colors.green.shade50,
            Icons.healing,
            isListItems: true,
          ),
          
        const SizedBox(height: 16),
        
        // Prevention Section
        if (sections['prevention'] != null && sections['prevention'].isNotEmpty)
          _buildRecommendationSection(
            'Prevention Measures',
            sections['prevention'],
            Colors.orange.shade700,
            Colors.orange.shade50,
            Icons.shield,
            isListItems: true,
          ),
      ],
    );
  }
  
  // Parse recommendation text into structured sections
  Map<String, dynamic> _parseRecommendationSections(String recommendation) {
    final lines = recommendation.split('\n');
    String description = '';
    List<String> treatments = [];
    List<String> prevention = [];
    
    String currentSection = 'none';
    
    for (var line in lines) {
      final lineLower = line.toLowerCase().trim();
      if (line.trim().isEmpty) continue;
      
      // Detect sections
      if (lineLower.contains('disease information:')) {
        currentSection = 'description';
        continue;
      } else if (lineLower.contains('treatment recommendations:') || 
                lineLower.contains('treatment:')) {
        currentSection = 'treatments';
        continue;
      } else if (lineLower.contains('prevention measures:') || 
                lineLower.contains('prevention:')) {
        currentSection = 'prevention';
        continue;
      } else if (lineLower.contains('organic treatments:') || 
                lineLower.contains('chemical options:')) {
        // These are subsections of treatments
        continue;
      }
      
      // Process line based on section
      if (currentSection == 'description') {
        description += line.trim() + ' ';
      } else if (currentSection == 'treatments') {
        if (line.trim().startsWith('1.') || line.trim().startsWith('2.') || 
            line.trim().startsWith('3.') || line.trim().startsWith('4.') ||
            line.trim().startsWith('5.') || line.trim().startsWith('6.') ||
            line.trim().startsWith('7.') || line.trim().startsWith('8.') ||
            line.trim().startsWith('9.') || line.trim().startsWith('-')) {
          treatments.add(line.trim());
        }
      } else if (currentSection == 'prevention') {
        if (line.trim().startsWith('1.') || line.trim().startsWith('2.') || 
            line.trim().startsWith('3.') || line.trim().startsWith('4.') ||
            line.trim().startsWith('5.') || line.trim().startsWith('6.') ||
            line.trim().startsWith('7.') || line.trim().startsWith('8.') ||
            line.trim().startsWith('9.') || line.trim().startsWith('-')) {
          prevention.add(line.trim());
        }
      }
    }
    
    return {
      'description': description.trim(),
      'treatments': treatments,
      'prevention': prevention,
    };
  }
  
  // Build a recommendation section with consistent styling
  Widget _buildRecommendationSection(String title, dynamic content, Color primaryColor, 
      Color backgroundColor, IconData icon, {bool isListItems = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Section content
          if (!isListItems)
            // For description text
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            )
          else
            // For list items (treatments or prevention)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < (content as List).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numbered bullet
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // List item text
                        Expanded(
                          child: Text(
                            // Remove any leading numbers or bullets
                            content[i].replaceAll(RegExp(r'^[0-9]+\.\s*|-\s*'), ''),
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}