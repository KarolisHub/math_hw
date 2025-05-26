import 'package:flutter/material.dart';
import '../services/class_service.dart';

class CreateClassForm extends StatefulWidget {
  final Function(String) onSuccess;
  final Function(String) onError;

  const CreateClassForm({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  _CreateClassFormState createState() => _CreateClassFormState();
}

class _CreateClassFormState extends State<CreateClassForm> {
  final TextEditingController _classNameController = TextEditingController();
  final ClassService _classService = ClassService();
  bool _isLoading = false;

  Future<void> _createClass() async {
    if (_classNameController.text.trim().isEmpty) {
      widget.onError("Klasės pavadinimas negali būti tuščias");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String joinCode = await _classService.createClass(_classNameController.text.trim());
      _classNameController.clear();
      widget.onSuccess(joinCode);
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sukurti naują klasę',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Klasės pavadinimas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createClass,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sukurti klasę'),
            ),
          ],
        ),
      ),
    );
  }
} 