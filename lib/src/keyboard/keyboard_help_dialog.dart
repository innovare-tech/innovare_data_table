import 'package:flutter/material.dart';

class KeyboardHelpDialog extends StatelessWidget {
  final Map<String, List<KeyboardShortcut>> shortcuts;

  const KeyboardHelpDialog({
    super.key,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.keyboard, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Atalhos de Teclado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: shortcuts.entries.map((entry) {
          return _buildShortcutGroup(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildShortcutGroup(String groupName, List<KeyboardShortcut> groupShortcuts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...groupShortcuts.map((shortcut) => _buildShortcutItem(shortcut)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShortcutItem(KeyboardShortcut shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: _buildKeyCombo(shortcut.keys),
          ),
          Expanded(
            child: Text(
              shortcut.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCombo(List<String> keys) {
    return Wrap(
      spacing: 4,
      children: keys.map((key) => _buildKeyChip(key)).toList(),
    );
  }

  Widget _buildKeyChip(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        key,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pressione F1 a qualquer momento para ver esta ajuda',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Map<String, List<KeyboardShortcut>> getDefaultShortcuts() {
    return {
      'Navegação': [
        KeyboardShortcut(['↑'], 'Mover para linha acima'),
        KeyboardShortcut(['↓'], 'Mover para linha abaixo'),
        KeyboardShortcut(['←'], 'Mover para coluna anterior'),
        KeyboardShortcut(['→'], 'Mover para coluna seguinte'),
        KeyboardShortcut(['Home'], 'Ir para primeira coluna'),
        KeyboardShortcut(['End'], 'Ir para última coluna'),
        KeyboardShortcut(['Ctrl', 'Home'], 'Ir para primeira página'),
        KeyboardShortcut(['Ctrl', 'End'], 'Ir para última página'),
      ],
      'Seleção': [
        KeyboardShortcut(['Space'], 'Selecionar/deselecionar item atual'),
        KeyboardShortcut(['Enter'], 'Ativar item atual'),
        KeyboardShortcut(['Ctrl', 'A'], 'Selecionar todos os itens'),
        KeyboardShortcut(['Escape'], 'Limpar seleção'),
      ],
      'Paginação': [
        KeyboardShortcut(['Page Up'], 'Página anterior'),
        KeyboardShortcut(['Page Down'], 'Próxima página'),
      ],
      'Ordenação e Filtros': [
        KeyboardShortcut(['Ctrl', 'S'], 'Ordenar coluna atual'),
        KeyboardShortcut(['Ctrl', 'F'], 'Filtrar coluna atual'),
        KeyboardShortcut(['Ctrl', 'R'], 'Atualizar dados'),
      ],
      'Ações Rápidas': [
        KeyboardShortcut(['Delete'], 'Excluir itens selecionados'),
        KeyboardShortcut(['Ctrl', 'E'], 'Editar item selecionado'),
        KeyboardShortcut(['Ctrl', 'C'], 'Copiar itens selecionados'),
      ],
      'Visualização': [
        KeyboardShortcut(['Ctrl', 'M'], 'Gerenciar colunas'),
        KeyboardShortcut(['Ctrl', 'D'], 'Alterar densidade da tabela'),
      ],
      'Ajuda': [
        KeyboardShortcut(['F1'], 'Mostrar esta ajuda'),
      ],
    };
  }
}

class KeyboardShortcut {
  final List<String> keys;
  final String description;

  const KeyboardShortcut(this.keys, this.description);
}