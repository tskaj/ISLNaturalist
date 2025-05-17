import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/deepseek_service.dart';

class BirdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detectionResult;
  final XFile imageFile;

  const BirdDetailScreen({
    Key? key,
    required this.detectionResult,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends State<BirdDetailScreen> {
  bool _isLoadingQA = true;
  bool _isLoadingDeepseek = false;
  List<Map<String, dynamic>> _faqData = [];
  String? _selectedQuestion;
  String? _answer;
  String? _deepseekAnswer;

  @override
  void initState() {
    super.initState();
    _loadFaqData();
    // Print the detection result to debug
    print("Bird detection result: ${widget.detectionResult}");
  }

  Future<void> _loadFaqData() async {
    setState(() {
      _isLoadingQA = true;
    });

    try {
      // Load from a local asset file
      final String jsonData = await rootBundle.loadString('assets/data/birds/generic.json');
      final Map<String, dynamic> data = json.decode(jsonData);
      
      setState(() {
        _faqData = List<Map<String, dynamic>>.from(data['questions']);
        _isLoadingQA = false;
      });
    } catch (error) {
      print("Error loading FAQ data: $error");
      setState(() {
        _faqData = [
          {
            "question": "What is this bird's scientific name?",
            "answer": "Scientific name information is not available in our local database."
          },
          {
            "question": "Where is this bird typically found?",
            "answer": "Habitat information is not available in our local database."
          },
          {
            "question": "What does this bird eat?",
            "answer": "Diet information is not available in our local database."
          },
          {
            "question": "Is this bird migratory?",
            "answer": "Migration information is not available in our local database."
          },
          {
            "question": "What sounds does this bird make?",
            "answer": "Call information is not available in our local database."
          }
        ];
        _isLoadingQA = false;
      });
    }
  }

  Future<void> _askDeepseek(String question) async {
    setState(() {
      _isLoadingDeepseek = true;
      _deepseekAnswer = null;
    });

    try {
      final birdName = widget.detectionResult['bird_name'] ?? 'Unknown Bird';
      final prompt = "About $birdName: $question";
      
      final deepseekService = DeepseekService();
      final answer = await deepseekService.getResponse(prompt);
      
      setState(() {
        _deepseekAnswer = answer;
        _isLoadingDeepseek = false;
      });
    } catch (error) {
      print("Error getting AI response: $error");
      setState(() {
        _deepseekAnswer = "Sorry, I couldn't generate a response. Please try again.";
        _isLoadingDeepseek = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final birdName = widget.detectionResult['bird_name'] ?? 'Unknown Bird';
    final confidence = widget.detectionResult['confidence'] ?? 0.0;
    final description = widget.detectionResult['description'] ?? 'No description available';
    final habitat = widget.detectionResult['habitat'] ?? 'Unknown';
    final isMigratory = widget.detectionResult['is_migratory'] ?? false;
    final diet = widget.detectionResult['diet'] ?? 'Unknown';
    final additionalInfo = widget.detectionResult['additional_info'] ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(birdName),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: widget.imageFile.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Center(child: Text('Error loading image'));
                          }
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.file(
                        File(widget.imageFile.path),
                        fit: BoxFit.cover,
                      ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.black.withOpacity(0.6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          birdName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Info Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'About this Bird',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Quick Facts
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fact_check, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Facts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Migration status
                          Row(
                            children: [
                              Icon(
                                isMigratory ? Icons.flight_takeoff : Icons.house,
                                color: isMigratory ? Colors.orange : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isMigratory ? 'Migratory species' : 'Non-migratory species',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Habitat
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.terrain, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Habitat',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      habitat,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Diet info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Diet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      diet,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Additional info
                          if (additionalInfo.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    additionalInfo,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Questions Section
                  if (_isLoadingQA)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Text(
                            'Common Questions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        ..._faqData.map((item) => _buildQuestionCard(item['question'])).toList(),
                      ],
                    ),
                  
                  // AI Answer Section
                  if (_selectedQuestion != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.question_answer, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedQuestion!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Basic Answer:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _answer ?? 'No information available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AI-Generated Response:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_deepseekAnswer == null && !_isLoadingDeepseek)
                                  ElevatedButton(
                                    onPressed: () => _askDeepseek(_selectedQuestion!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Get AI Answer'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingDeepseek)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text('Generating response...'),
                                    ],
                                  ),
                                ),
                              )
                            else if (_deepseekAnswer != null)
                              Text(
                                _deepseekAnswer!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              )
                            else
                              Text(
                                'Click "Get AI Answer" for a more detailed response.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    final isSelected = _selectedQuestion == question;
    
    return Card(
      elevation: isSelected ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Find the answer for this question
          final questionData = _faqData.firstWhere(
            (item) => item['question'] == question,
            orElse: () => {'question': question, 'answer': 'No answer available'},
          );
          
          setState(() {
            _selectedQuestion = question;
            _answer = questionData['answer'];
            _deepseekAnswer = null; // Reset AI answer when selecting a new question
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.blue.shade700 : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}