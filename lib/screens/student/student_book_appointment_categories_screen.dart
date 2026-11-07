import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'book_slot_screen.dart';

class StudentBookAppointmentCategoriesScreen extends StatefulWidget {
  const StudentBookAppointmentCategoriesScreen({super.key});

  @override
  State<StudentBookAppointmentCategoriesScreen> createState() => _StudentBookAppointmentCategoriesScreenState();
}

class _StudentBookAppointmentCategoriesScreenState extends State<StudentBookAppointmentCategoriesScreen> {
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      final services = await queueService.getServices().first;
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Service> _buildCategories() {
    // Map service names to the hardcoded categories for display
    final categoryMap = {
      'Advisor Office': Service(
        id: 'advisor_office', // This will be replaced with actual ID
        name: 'Student Advisor Meeting',
        description: 'Meet your academic advisor for guidance.',
        location: 'Advisor Office',
        minutesPerPerson: 15,
      ),
      'Accounts Office': Service(
        id: 'accounts_office', // This will be replaced with actual ID
        name: 'Accounts Office',
        description: 'Fee payments and accounts queries.',
        location: 'Accounts Office',
        minutesPerPerson: 10,
      ),
      'HOD Meeting': Service(
        id: 'hod_meeting', // This will be replaced with actual ID
        name: 'Meeting with HOD',
        description: 'Schedule a meeting with your Head of Department.',
        location: 'Department Office',
        minutesPerPerson: 20,
      ),
      'Crispino': Service(
        id: 'canteen_crispino', // This will be replaced with actual ID
        name: 'Crispino Café',
        description: 'Book a slot at Crispino café.',
        location: 'Crispino',
        minutesPerPerson: 5,
      ),
      'Deans Canteen': Service(
        id: 'canteen_deans', // This will be replaced with actual ID
        name: 'Deans Canteen',
        description: 'Book a slot at Deans canteen.',
        location: 'Deans',
        minutesPerPerson: 5,
      ),
      'Bites and Beans': Service(
        id: 'canteen_bites_beans', // This will be replaced with actual ID
        name: 'Bites and Beans',
        description: 'Book a slot at Bites and Beans.',
        location: 'Student Café',
        minutesPerPerson: 5,
      ),
      'Quetta': Service(
        id: 'canteen_quetta', // This will be replaced with actual ID
        name: 'Quetta Café',
        description: 'Book a slot at Quetta café.',
        location: 'Nescafe',
        minutesPerPerson: 5,
      ),
    };

    // Create list of available services based on actual Firestore services
    final availableServices = <Service>[];
    
    for (final service in _services) {
      if (categoryMap.containsKey(service.name)) {
        // Create service with actual Firestore ID but display info from category map
        final category = categoryMap[service.name]!;
        availableServices.add(Service(
          id: service.id, // Use actual Firestore ID
          name: category.name,
          description: category.description,
          location: category.location,
          minutesPerPerson: category.minutesPerPerson,
        ));
      }
    }
    
    return availableServices;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final categories = _buildCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Service', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = categories[index];
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookSlotScreen(service: service),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: AppTextStyles.heading2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.description,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    service.location,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${service.minutesPerPerson} min',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.accentGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
