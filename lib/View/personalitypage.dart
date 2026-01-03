import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/viewmodels/personality_viewmodel.dart';
import 'package:to_do_list/util/tittlegradient.dart';

class PersonalityPage extends ConsumerStatefulWidget {
  const PersonalityPage({super.key});

  @override
  ConsumerState<PersonalityPage> createState() => _PersonalityPageState();
}

class _PersonalityPageState extends ConsumerState<PersonalityPage> {
  final TextEditingController _personalityController = TextEditingController();

  @override
  void dispose() {
    _personalityController.dispose();
    super.dispose();
  }

  void _addPersonality() {
    print('[PersonalityPage] ===== ADDING PERSONALITY TRAIT =====');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Personality Trait'),
        content: TextField(
          controller: _personalityController,
          decoration: const InputDecoration(hintText: 'Enter personality trait'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _personalityController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_personalityController.text.isNotEmpty) {
                print('[PersonalityPage] Adding trait: ${_personalityController.text}');
                await ref.read(personalityPageViewModelProvider.notifier).addTrait(_personalityController.text);
                _personalityController.clear();
                Navigator.pop(context);
                print('[PersonalityPage] Trait added successfully');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editPersonality(String id, String currentText) {
    print('[PersonalityPage] ===== EDITING PERSONALITY TRAIT =====');
    print('[PersonalityPage] Trait ID: $id, Current text: $currentText');
    _personalityController.text = currentText;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Personality Trait'),
        content: TextField(
          controller: _personalityController,
          decoration: const InputDecoration(hintText: 'Edit personality trait'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _personalityController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_personalityController.text.isNotEmpty) {
                print('[PersonalityPage] Updating trait to: ${_personalityController.text}');
                await ref.read(personalityPageViewModelProvider.notifier).updateTrait(id, _personalityController.text);
                _personalityController.clear();
                Navigator.pop(context);
                print('[PersonalityPage] Trait updated successfully');
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
    final state = ref.watch(personalityPageViewModelProvider);
    final traits = state.traits;
    final appTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.background,
        title: Tittlegradient(text: 'Personality'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPersonality,
          ),
        ],
      ),
      body: traits.isEmpty
          ? const Center(child: Text("No personality traits yet"))
          : ListView.builder(
              itemCount: traits.length,
              itemBuilder: (context, index) {
                final trait = traits[index];
                return ListTile(
                  title: Text(trait.trait),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editPersonality(trait.id!, trait.trait),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          print('[PersonalityPage] ===== DELETING PERSONALITY TRAIT =====');
                          print('[PersonalityPage] Trait ID: ${trait.id}, Text: ${trait.trait}');
                          await ref.read(personalityPageViewModelProvider.notifier).deleteTrait(trait.id!);
                          print('[PersonalityPage] Trait deleted successfully');
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
