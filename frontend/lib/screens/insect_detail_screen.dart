import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/deepseek_service.dart';

class InsectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detectionResult;
  final XFile imageFile;

  const InsectDetailScreen({
    Key? key,
    required this.detectionResult,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<InsectDetailScreen> createState() => _InsectDetailScreenState();
}

class _InsectDetailScreenState extends State<InsectDetailScreen> {
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
    print("Insect detection result: ${widget.detectionResult}");
  }

  Future<void> _loadFaqData() async {
    setState(() {
      _isLoadingQA = true;
    });

    try {
      // In a real application, you would load this from a real database or API
      // For this example, we're loading from a local asset file
      final String insectName = widget.detectionResult['insect_name'].toLowerCase();
      
      // Try to load insect-specific FAQ data
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/data/insects/$insectName.json');
      } catch (e) {
        // If no specific data is found, load generic insect FAQ data
        jsonString = await rootBundle.loadString('assets/data/insects/generic.json');
      }
      
      final data = json.decode(jsonString);
      
      setState(() {
        _faqData = List<Map<String, dynamic>>.from(data['questions']);
        _isLoadingQA = false;
      });
    } catch (error) {
      print('Error loading FAQ data: $error');
      // If loading fails, provide some default questions
      setState(() {
        _faqData = [
          {
            "question": "What is this insect's scientific name?",
            "answer": "The scientific name information is not available in our local database."
          },
          {
            "question": "Where is this insect typically found?",
            "answer": "Habitat information is not available in our local database."
          },
          {
            "question": "Is this insect harmful or beneficial?",
            "answer": "Information about whether this insect is harmful or beneficial is not available in our local database."
          },
          {
            "question": "What does this insect eat?",
            "answer": "Diet information is not available in our local database."
          },
          {
            "question": "What is the lifecycle of this insect?",
            "answer": "Lifecycle information is not available in our local database."
          }
        ];
        _isLoadingQA = false;
      });
    }
  }

  Future<void> _askDeepseek(String question) async {
    setState(() {
      _isLoadingDeepseek = true;
      _selectedQuestion = question;
      _answer = _faqData.firstWhere(
        (q) => q['question'] == question,
        orElse: () => {"answer": "No local answer available."},
      )['answer'];
      _deepseekAnswer = null;
    });

    try {
      final DeepseekService deepseekService = DeepseekService();
      final insectName = widget.detectionResult['insect_name'];
      final prompt = 'About the insect "$insectName": $question';
      
      final response = await deepseekService.getResponse(prompt);
      
      setState(() {
        _deepseekAnswer = response;
        _isLoadingDeepseek = false;
      });
    } catch (error) {
      print('Error getting Deepseek response: $error');
      setState(() {
        _deepseekAnswer = "Error connecting to AI service. Please try again later.";
        _isLoadingDeepseek = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final insectName = widget.detectionResult['insect_name'];
    final confidence = widget.detectionResult['confidence'];
    final description = widget.detectionResult['description'] ?? 'No description available';
    final isHarmful = widget.detectionResult['is_harmful'] ?? false;
    final commonLocations = widget.detectionResult['common_locations'] ?? 'Unknown';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Insect Details'),
        backgroundColor: Colors.amber.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image and basic info section
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber.shade800,
                    width: 2,
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  kIsWeb
                      ? FutureBuilder<List<int>>(
                          future: widget.imageFile.readAsBytes().then((value) => value.toList()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(child: Text('Error loading image'));
                            }
                            return Image.memory(
                              Uint8List.fromList(snapshot.data!),
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.file(
                          File(widget.imageFile.path),
                          fit: BoxFit.cover,
                        ),
                  
                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Text overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isHarmful ? Colors.red.shade700 : Colors.green.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isHarmful ? 'Harmful' : 'Beneficial',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Description Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 16),
                  
                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Common Locations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(commonLocations),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // FAQ Header
                  Text(
                    'Learn More',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // FAQ Questions
                  if (_isLoadingQA)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        ..._faqData.map((faq) => _buildQuestionCard(faq['question'])),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Selected question and answers
                  if (_selectedQuestion != null) ...[
                    Text(
                      'Question: $_selectedQuestion',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Local database answer
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Our Database:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_answer ?? 'No answer available'),
                          ],
                        ),
                      ),
                    ),
                    
                    // DeepSeek AI answer
                    Card(
                      elevation: 3,
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.smart_toy, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Assistant Response:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (_isLoadingDeepseek)
                              const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('Generating response...'),
                                  ],
                                ),
                              )
                            else if (_deepseekAnswer != null)
                              Text(_deepseekAnswer!)
                            else
                              const Text('Ask a question to see AI response'),
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
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Colors.amber.shade100 : null,
      child: InkWell(
        onTap: () => _askDeepseek(question),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.amber.shade800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeepseekService {
  Future<String> getResponse(String prompt) async {
    // Simulate an API call to get a response
    await Future.delayed(Duration(seconds: 2));
    return "This is a simulated response for the prompt: $prompt";
  }
}