import 'package:emplbee_mob/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  final _userService = UserService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  Set<String> _expandedCards = {}; // Track expanded cards by task ID

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    _loadTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = await _userService.getCurrentUser();
      if (currentUser.memberId == null) {
        setState(() => _tasks = []);
        return;
      }

      final details =
          await _userService.getMemberDetails(currentUser.memberId!);
      final activeTasks = details['activeTasks'] as List?;
      if (activeTasks != null) {
        setState(() {
          _tasks = activeTasks.map((task) => TaskModel.fromJson(task)).toList();
          _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String category) {
    switch (category.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'ordinary':
        return Colors.orange;
      default:
        return const Color.fromARGB(255, 126, 126, 126);
    }
  }

  Widget _buildTaskCard(TaskModel task) {
    final statusColor = _getStatusColor(task.status.category);
    final isOverdue = task.isOverdue();
    final isExpanded = _expandedCards.contains(task.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
              Colors.blue.shade50.withOpacity(0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCards.remove(task.id);
              } else {
                _expandedCards.add(task.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.task_alt,
                              size: 20,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  task.code,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        const Color.fromARGB(255, 37, 134, 237),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCards.remove(task.id);
                          } else {
                            _expandedCards.add(task.id);
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTimeInfo(
                      'Start',
                      task.getFormattedStartDate(),
                      Icons.play_circle_outline,
                      Colors.blue,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade200,
                    ),
                    _buildTimeInfo(
                      'Due',
                      task.getFormattedDeadline(),
                      Icons.event,
                      isOverdue ? Colors.red : Colors.orange,
                      isOverdue ? 'Overdue' : null,
                    ),
                  ],
                ),
                // Expanded drop down content
                if (isExpanded) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.radio_button_checked,
                                size: 16,
                                color: const Color.fromARGB(255, 37, 134, 237),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).status,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      const Color.fromARGB(255, 37, 134, 237),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              task.status.name.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // TAGS
                      if (task.tags.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 16,
                                    color:
                                        const Color.fromARGB(255, 37, 134, 237),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context).tags,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                          255, 37, 134, 237),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: task.tags
                                      .map((tag) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.blue[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                tag.name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // DESCRIPTION
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: const Color.fromARGB(255, 37, 134, 237),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 37, 134, 237),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        task.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 16,
                          color: const Color.fromARGB(255, 37, 134, 237),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).subtasks,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 37, 134, 237),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${task.subtasks.where((st) => st.completed).length}/${task.subtasks.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...task.subtasks
                        .map((subtask) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: subtask.completed,
                                      onChanged: (bool? value) {
                                        // TODO: Implement subtask update
                                      },
                                      activeColor: const Color.fromARGB(
                                          255, 37, 134, 237),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subtask.label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        decoration: subtask.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: Colors.grey,
                                        decorationThickness: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String time,
    IconData icon,
    Color color, [
    String? subtitle,
  ]) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).myTasks,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color.fromARGB(255, 37, 134, 237),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).loadingTasks,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: _tasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _tasks.length,
                                  itemBuilder: (context, index) =>
                                      _buildTaskCard(_tasks[index]),
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
