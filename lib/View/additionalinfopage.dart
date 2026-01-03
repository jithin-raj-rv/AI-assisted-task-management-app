import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/viewmodels/additional_info_viewmodel.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class AdditionalInfoPage extends ConsumerStatefulWidget {
  const AdditionalInfoPage({super.key});

  @override
  ConsumerState<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends ConsumerState<AdditionalInfoPage> {
  final TextEditingController _additionalInfoController = TextEditingController();

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _addAdditionalInfo() {
    print('[AdditionalInfoPage] ===== ADDING ADDITIONAL INFO =====');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Additional Information'),
        content: TextField(
          controller: _additionalInfoController,
          decoration: const InputDecoration(hintText: 'Enter additional information'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _additionalInfoController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_additionalInfoController.text.isNotEmpty) {
                print('[AdditionalInfoPage] Adding info: ${_additionalInfoController.text}');
                await ref.read(additionalInfoPageViewModelProvider.notifier).addInfo(_additionalInfoController.text);
                _additionalInfoController.clear();
                Navigator.pop(context);
                print('[AdditionalInfoPage] Info added successfully');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editAdditionalInfo(String id, String currentText) {
    print('[AdditionalInfoPage] ===== EDITING ADDITIONAL INFO =====');
    print('[AdditionalInfoPage] Info ID: $id, Current text: $currentText');
    _additionalInfoController.text = currentText;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Additional Information'),
        content: TextField(
          controller: _additionalInfoController,
          decoration: const InputDecoration(hintText: 'Edit additional information'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _additionalInfoController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_additionalInfoController.text.isNotEmpty) {
                print('[AdditionalInfoPage] Updating info to: ${_additionalInfoController.text}');
                await ref.read(additionalInfoPageViewModelProvider.notifier).updateInfo(id, _additionalInfoController.text);
                _additionalInfoController.clear();
                Navigator.pop(context);
                print('[AdditionalInfoPage] Info updated successfully');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(additionalInfoPageViewModelProvider);
    final infoItems = state.infoItems;
    final appTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'Additional Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAdditionalInfo,
          ),
        ],
      ),
      body: infoItems.isEmpty
          ? const Center(child: Text("No additional information yet"))
          : ListView.builder(
              itemCount: infoItems.length,
              itemBuilder: (context, index) {
                final info = infoItems[index];
                return ListTile(
                  title: Text(info.info),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAdditionalInfo(info.id!, info.info),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          print('[AdditionalInfoPage] ===== DELETING ADDITIONAL INFO =====');
                          print('[AdditionalInfoPage] Info ID: ${info.id}, Text: ${info.info}');
                          await ref.read(additionalInfoPageViewModelProvider.notifier).deleteInfo(info.id!);
                          print('[AdditionalInfoPage] Info deleted successfully');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
