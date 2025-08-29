import 'package:flutter/material.dart';

class AddTaskViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? _dueDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  DateTime? get dueDate => _dueDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

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

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    _errorMessage = null;
    final title = titleController.text.trim();

    if (title.isEmpty) {
      _errorMessage = 'Title is required.';
      notifyListeners();
      return false;
    }
    if (_startDate == null) {
      _errorMessage = 'Please select a start date.';
      notifyListeners();
      return false;
    }
    if (_endDate == null) {
      _errorMessage = 'Please select an end date.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _isSubmitting = false;
    notifyListeners();
    return true;
  }
}
