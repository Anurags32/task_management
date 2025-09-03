import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_task_viewmodel.dart';

class AddTaskPage extends StatefulWidget {
  final int? projectId; // Optional project ID if coming from project details

  const AddTaskPage({super.key, this.projectId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<AddTaskViewModel>();
      await vm.loadInitialData();
      if (widget.projectId != null) {
        vm.setSelectedProject(widget.projectId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// White background
          Container(color: Colors.white),

          /// 🔹 Blurry blobs in background
          Positioned(
            top: -40,
            left: -60,
            child: _buildBlob(const Color(0xFF6C4DE6), 220), // purple
          ),
          Positioned(
            top: 120,
            right: -80,
            child: _buildBlob(const Color(0xFF9C6FE4), 200), // light purple
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _buildBlob(const Color(0xFF00C9A7), 220), // teal/green
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: _buildBlob(const Color(0xFFFFC857), 180), // yellow
          ),

          /// 🔹 Page content
          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(context),

                // Body with form
                Expanded(
                  child: Consumer<AddTaskViewModel>(
                    builder: (context, vm, child) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Assign To
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Assign To"),
                                  const SizedBox(height: 8),
                                  vm.users.isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: vm.selectedAssigneeIds.map((
                                                id,
                                              ) {
                                                final user = vm.users
                                                    .firstWhere(
                                                      (u) => u['id'] == id,
                                                      orElse: () =>
                                                          <String, dynamic>{},
                                                    );
                                                final name =
                                                    (user['name'] ?? 'User $id')
                                                        .toString();
                                                return Chip(
                                                  label: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  deleteIconColor:
                                                      Colors.black54,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  onDeleted: () {
                                                    vm.toggleAssignee(id);
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                            const SizedBox(height: 8),
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.group_add),
                                              label: const Text('Select Users'),
                                              onPressed: () async {
                                                final current =
                                                    vm.selectedAssigneeIds;
                                                final List<int>?
                                                picked = await showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final tempSelected = current
                                                        .toSet();
                                                    return AlertDialog(
                                                      title: const Text(
                                                        'Select Assignees',
                                                      ),
                                                      content: SizedBox(
                                                        width: double.maxFinite,
                                                        child: ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              vm.users.length,
                                                          itemBuilder: (context, index) {
                                                            final user =
                                                                vm.users[index];
                                                            final uid =
                                                                user['id']
                                                                    as int;
                                                            final uname =
                                                                (user['name'] ??
                                                                        'Unknown User')
                                                                    .toString();
                                                            final checked =
                                                                tempSelected
                                                                    .contains(
                                                                      uid,
                                                                    );
                                                            return CheckboxListTile(
                                                              value: checked,
                                                              title: Text(
                                                                uname,
                                                              ),
                                                              onChanged: (val) {
                                                                if (val ==
                                                                    true) {
                                                                  tempSelected
                                                                      .add(uid);
                                                                } else {
                                                                  tempSelected
                                                                      .remove(
                                                                        uid,
                                                                      );
                                                                }
                                                                // Rebuild dialog
                                                                (context
                                                                        as Element)
                                                                    .markNeedsBuild();
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                              null,
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                              tempSelected
                                                                  .toList(),
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (picked != null) {
                                                  vm.setSelectedAssignees(
                                                    picked,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      : const Text("Loading users..."),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Project Name
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Project Name"),
                                  const SizedBox(height: 8),
                                  vm.projects.isNotEmpty
                                      ? DropdownButtonFormField<int>(
                                          value: vm.selectedProjectId,
                                          decoration: _dropdownDecoration(),
                                          hint: const Text("Select Project"),
                                          items: [
                                            const DropdownMenuItem<int>(
                                              value: null,
                                              child: Text("No Project"),
                                            ),
                                            ...vm.projects.map((project) {
                                              return DropdownMenuItem<int>(
                                                value: project['id'] as int,
                                                child: Text(
                                                  project['name'] ??
                                                      'Unnamed Project',
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: (value) =>
                                              vm.setSelectedProject(value),
                                        )
                                      : const Text("Loading projects..."),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Task Title
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Task Title"),
                                  const SizedBox(height: 8),
                                  _inputField(
                                    vm.titleController,
                                    "Enter task title",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Description"),
                                  const SizedBox(height: 8),
                                  _inputField(
                                    vm.descriptionController,
                                    "Enter description",
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Start Date
                            _buildDateCard(
                              label: "Start Date",
                              date:
                                  vm.startDate ??
                                  DateTime.now().add(const Duration(days: 1)),
                              onTap: () async {
                                print(
                                  '🔄 AddTaskPage: Opening Start Date picker...',
                                );
                                print(
                                  '🔄 AddTaskPage: Current start date: ${vm.startDate}',
                                );
                                print(
                                  '🔄 AddTaskPage: Initial date: ${vm.startDate ?? DateTime.now().add(const Duration(days: 1))}',
                                );

                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      vm.startDate ??
                                      DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );

                                if (date != null) {
                                  print(
                                    '✅ AddTaskPage: Start Date selected: ${date.toString()}',
                                  );
                                  print(
                                    '✅ AddTaskPage: Date components - Year: ${date.year}, Month: ${date.month}, Day: ${date.day}',
                                  );
                                  vm.setStartDate(date);
                                } else {
                                  print(
                                    '❌ AddTaskPage: Start Date selection cancelled',
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Start Time
                            _buildTimeCard(
                              label: "Start Time",
                              time: vm.startTime,
                              onTap: () async {
                                print(
                                  '🔄 AddTaskPage: Opening Start Time picker...',
                                );
                                print(
                                  '🔄 AddTaskPage: Current start time: ${vm.startTime}',
                                );
                                print(
                                  '🔄 AddTaskPage: Initial time: ${vm.startTime ?? TimeOfDay.now()}',
                                );

                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: vm.startTime ?? TimeOfDay.now(),
                                );

                                if (time != null) {
                                  print(
                                    '✅ AddTaskPage: Start Time selected: ${time.toString()}',
                                  );
                                  print(
                                    '✅ AddTaskPage: Time components - Hour: ${time.hour}, Minute: ${time.minute}',
                                  );
                                  print(
                                    '✅ AddTaskPage: 12-hour format: ${time.format(context)}',
                                  );
                                  vm.setStartTime(time);
                                } else {
                                  print(
                                    '❌ AddTaskPage: Start Time selection cancelled',
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // End Date
                            _buildDateCard(
                              label: "End Date",
                              date:
                                  vm.deadline ??
                                  DateTime.now().add(const Duration(days: 2)),
                              onTap: () async {
                                print(
                                  '🔄 AddTaskPage: Opening End Date picker...',
                                );
                                print(
                                  '🔄 AddTaskPage: Current deadline: ${vm.deadline}',
                                );
                                print(
                                  '🔄 AddTaskPage: Initial date: ${vm.deadline ?? DateTime.now().add(const Duration(days: 2))}',
                                );

                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      vm.deadline ??
                                      DateTime.now().add(
                                        const Duration(days: 2),
                                      ),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );

                                if (date != null) {
                                  print(
                                    '✅ AddTaskPage: End Date selected: ${date.toString()}',
                                  );
                                  print(
                                    '✅ AddTaskPage: Date components - Year: ${date.year}, Month: ${date.month}, Day: ${date.day}',
                                  );
                                  vm.setDeadline(date);
                                } else {
                                  print(
                                    '❌ AddTaskPage: End Date selection cancelled',
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // End Time
                            _buildTimeCard(
                              label: "End Time",
                              time: vm.endTime,
                              onTap: () async {
                                print(
                                  '🔄 AddTaskPage: Opening End Time picker...',
                                );
                                print(
                                  '🔄 AddTaskPage: Current end time: ${vm.endTime}',
                                );
                                print(
                                  '🔄 AddTaskPage: Initial time: ${vm.endTime ?? TimeOfDay.now()}',
                                );

                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: vm.endTime ?? TimeOfDay.now(),
                                );

                                if (time != null) {
                                  print(
                                    '✅ AddTaskPage: End Time selected: ${time.toString()}',
                                  );
                                  print(
                                    '✅ AddTaskPage: Time components - Hour: ${time.hour}, Minute: ${time.minute}',
                                  );
                                  print(
                                    '✅ AddTaskPage: 12-hour format: ${time.format(context)}',
                                  );
                                  vm.setEndTime(time);
                                } else {
                                  print(
                                    '❌ AddTaskPage: End Time selection cancelled',
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Allotted Time
                            // _buildCard(
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       _label("Allotted Time"),
                            //       const SizedBox(height: 8),
                            //       DropdownButtonFormField<String>(
                            //         value: vm.allottedTime,
                            //         decoration: _dropdownDecoration(),
                            //         hint: const Text("Select Hours"),
                            //         items: const [
                            //           DropdownMenuItem(
                            //             value: "1",
                            //             child: Text("1 Hr"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "2",
                            //             child: Text("2 Hrs"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "4",
                            //             child: Text("4 Hrs"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "8",
                            //             child: Text("8 Hrs"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "9",
                            //             child: Text("9 Hrs"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "16",
                            //             child: Text("16 Hrs"),
                            //           ),
                            //           DropdownMenuItem(
                            //             value: "24",
                            //             child: Text("24 Hrs"),
                            //           ),
                            //         ],
                            //         onChanged: (value) {
                            //           vm.setAllottedTime(value);
                            //         },
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            // const SizedBox(height: 16),

                            // Priority
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Priority"),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: vm.selectedPriority,
                                    decoration: _dropdownDecoration(),
                                    hint: const Text("Select Priority"),
                                    items: const [
                                      DropdownMenuItem(
                                        value: "0",
                                        child: Text("Low"),
                                      ),
                                      DropdownMenuItem(
                                        value: "1",
                                        child: Text("Medium"),
                                      ),
                                      DropdownMenuItem(
                                        value: "2",
                                        child: Text("High"),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        vm.setSelectedPriority(value ?? "0"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            _gradientButton(
                              text: "Create Task",
                              isLoading: vm.isSubmitting,
                              onTap: () async {
                                try {
                                  final success = await vm.submit();
                                  if (success) {
                                    print('Create Task: success');
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    // Log error from ViewModel if available
                                    print(
                                      'Create Task: failed -> ${vm.errorMessage ?? 'Unknown error'}',
                                    );
                                  }
                                } catch (e) {
                                  // Log unexpected exceptions
                                  print('Create Task: exception -> $e');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Helper widget for soft blur circles
  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }

  /// 🔹 Custom AppBar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "Create New Task",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48), // to balance back button space
        ],
      ),
    );
  }

  /// 🔹 Reusable widgets
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFDFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: _buildCard(
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null ? "${date.day}-${date.month}-${date.year}" : label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: _buildCard(
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                time != null ? time.format(context) : label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C4DE6), Color(0xFF9C6FE4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
