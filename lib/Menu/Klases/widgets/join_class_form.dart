import 'package:flutter/material.dart';
import '../services/class_service.dart';

class JoinClassForm extends StatefulWidget {
  final Function(String) onSuccess;
  final Function(String) onError;

  const JoinClassForm({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  _JoinClassFormState createState() => _JoinClassFormState();
}

class _JoinClassFormState extends State<JoinClassForm> {
  final TextEditingController _joinCodeController = TextEditingController();
  final ClassService _classService = ClassService();
  bool _isLoading = false;

  Future<void> _joinClass() async {
    if (_joinCodeController.text.trim().isEmpty) {
      widget.onError("Prisijungimo kodo laukas negali būti tuščias");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String className = await _classService.joinClass(_joinCodeController.text.trim());
      _joinCodeController.clear();
      widget.onSuccess(className);
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
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prisijungti prie klasės',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _joinCodeController,
              decoration: const InputDecoration(
                labelText: 'Įveskite prisijungimo kodą',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinClass,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Prisijungti'),
            ),
          ],
        ),
      ),
    );
  }
} 