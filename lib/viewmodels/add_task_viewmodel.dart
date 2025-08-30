import 'package:flutter/material.dart';
import 'package:task_management/services/task_service.dart';

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? _dueDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _stages = [];
  List<int> _selectedUserIds = [];
  int? _selectedStageId;

  DateTime? get dueDate => _dueDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get stages => _stages;
  List<int> get selectedUserIds => _selectedUserIds;
  int? get selectedStageId => _selectedStageId;

  AddTaskViewModel() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final usersResult = await TaskService().getUsers();
      if (usersResult['success'] == true) {
        _users = List<Map<String, dynamic>>.from(usersResult['data'] ?? []);
      }

      final stagesResult = await TaskService().getTaskStages();
      if (stagesResult['success'] == true) {
        _stages = List<Map<String, dynamic>>.from(stagesResult['data'] ?? []);
        // Set default stage if available
        if (_stages.isNotEmpty) {
          _selectedStageId = _stages.first['id'];
        }
      }
      notifyListeners();
    } catch (e) {
      // Ignore errors for now
    }
  }

  void setDueDate(DateTime? date) {
    _dueDate = date;
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void setSelectedUserIds(List<int> userIds) {
    _selectedUserIds = userIds;
    notifyListeners();
  }

  void setSelectedStageId(int? stageId) {
    _selectedStageId = stageId;
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    _errorMessage = null;
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      _errorMessage = 'Title is required.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await TaskService().createTask(
        name: title,
        description: description.isEmpty ? 'No description' : description,
        userIds: _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
        stageId: _selectedStageId,
      );

      if (result['success'] == true) {
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to create task.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create task. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
