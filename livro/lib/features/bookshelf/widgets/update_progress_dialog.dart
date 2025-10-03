import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livro/core/models/book_model.dart';

class UpdateProgressDialog extends StatefulWidget {
  final Book book;

  const UpdateProgressDialog({super.key, required this.book});

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  late final TextEditingController _progressController;
  late final TextEditingController _totalPagesController;
  bool _isPercentageMode = false; // Inicia no modo página por padrão

  @override
  void initState() {
    super.initState();
    _progressController = TextEditingController(text: widget.book.currentPage?.toString() ?? '0');
    _totalPagesController = TextEditingController(text: widget.book.pageCount?.toString() ?? '');
  }

  @override
  void dispose() {
    _progressController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atualizar Progresso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Pág.'), icon: Icon(Icons.menu_book)),
                ButtonSegment(value: true, label: Text('%'), icon: Icon(Icons.percent)),
              ],
              selected: {_isPercentageMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _isPercentageMode = newSelection.first;
                  _progressController.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _progressController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: _isPercentageMode ? 'Progresso em %' : 'Página atual',
                hintText: _isPercentageMode ? 'Ex: 50' : 'Ex: 125',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalPagesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total de páginas',
                hintText: 'Ex: 350',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final progressValue = int.tryParse(_progressController.text);
            final totalPages = int.tryParse(_totalPagesController.text);
            int? newCurrentPage;

            if (progressValue != null && totalPages != null && totalPages > 0) {
              if (_isPercentageMode) {
                newCurrentPage = (progressValue / 100 * totalPages).round().clamp(0, totalPages);
              } else {
                newCurrentPage = progressValue.clamp(0, totalPages);
              }
            } else if (progressValue != null && !_isPercentageMode) {
                newCurrentPage = progressValue;
            }
            
            // Retorna os dados atualizados para a tela que o chamou
            Navigator.pop(context, {
              'currentPage': newCurrentPage,
              'pageCount': totalPages,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}