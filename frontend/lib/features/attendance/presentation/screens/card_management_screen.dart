import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:openapi/api.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';

class CardManagementScreen extends ConsumerStatefulWidget {
  final int employeeId;
  final String employeeName;

  const CardManagementScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  ConsumerState<CardManagementScreen> createState() =>
      _CardManagementScreenState();
}

class _CardManagementScreenState extends ConsumerState<CardManagementScreen> {
  List<dynamic>? _cards;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(cardsApiProvider);
      // Use WithHttpInfo because the generated method returns void
      final response = await api.cardControllerListCardsWithHttpInfo(
        widget.employeeId,
      );

      if (response.statusCode == 200) {
        final List<dynamic> cards = json.decode(response.body) as List<dynamic>;
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      } else {
        throw ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cards: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCard(int cardId) async {
    try {
      final api = ref.read(cardsApiProvider);
      await api.cardControllerDeleteCard(widget.employeeId, cardId);
      _loadCards();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete card: $e')));
    }
  }

  Future<void> _toggleCardStatus(int cardId, bool currentStatus) async {
    try {
      final api = ref.read(cardsApiProvider);
      final dto = UpdateCardDto(isActive: !currentStatus);
      await api.cardControllerUpdateCard(widget.employeeId, cardId, dto);
      _loadCards();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update card: $e')));
    }
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddCardDialog(employeeId: widget.employeeId, onCardAdded: _loadCards),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カード管理',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.employeeName,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              )
            : _cards == null || _cards!.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'カードが登録されていません',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                itemCount: _cards!.length,
                itemBuilder: (context, index) {
                  final card = _cards![index];
                  return CardListItem(
                    card: card,
                    onDelete: () => _deleteCard(card['id']),
                    onToggleStatus: () =>
                        _toggleCardStatus(card['id'], card['is_active']),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('カード追加'),
      ).animate().scale(delay: 500.ms),
    );
  }
}

class CardListItem extends StatelessWidget {
  final dynamic card;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const CardListItem({
    super.key,
    required this.card,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = card['is_active'] as bool;
    final cardName = card['name'] as String?;
    final cardId = card['card_id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.credit_card : Icons.credit_card_off,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardName ?? '名前なしカード',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardId,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? '有効' : '無効',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textPrimary,
                  ),
                  onSelected: (value) {
                    if (value == 'toggle') {
                      onToggleStatus();
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(isActive ? '無効化' : '有効化'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('削除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * 0).ms).slideX();
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('カードを削除'),
        content: const Text('本当にこのカードを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text(
              '削除',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AddCardDialog extends ConsumerStatefulWidget {
  final int employeeId;
  final VoidCallback onCardAdded;

  const AddCardDialog({
    super.key,
    required this.employeeId,
    required this.onCardAdded,
  });

  @override
  ConsumerState<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends ConsumerState<AddCardDialog> {
  final _nameController = TextEditingController();
  final _cardIdController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cardIdController.dispose();
    super.dispose();
  }

  Future<void> _scanCard() async {
    setState(() => _isScanning = true);

    try {
      final nfcReader = ref.read(nfcReaderProvider);
      await nfcReader.initialize();

      // Listen for card reads
      nfcReader.cardStream.listen((cardId) {
        if (mounted) {
          setState(() {
            _cardIdController.text = cardId;
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to scan card: $e')));
      }
    } finally {
      // Note: We don't set _isScanning to false here because we're waiting for the stream
      // But if initialization fails, we should reset it
      if (_cardIdController.text.isEmpty) {
        // setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _addCard() async {
    if (_cardIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan a card ID')),
      );
      return;
    }

    try {
      final api = ref.read(cardsApiProvider);
      final dto = CreateCardDto(
        cardId: _cardIdController.text,
        name: _nameController.text.isEmpty ? null : _nameController.text,
      );

      await api.cardControllerCreateCard(widget.employeeId, dto);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCardAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add card: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('新しいカードを追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'カード名 (任意)',
              hintText: '例: メインカード、予備カード',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardIdController,
            decoration: const InputDecoration(
              labelText: 'カードID',
              hintText: 'スキャンまたは手動入力',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.nfc),
            label: Text(_isScanning ? 'スキャン中...' : 'NFCカードをスキャン'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _addCard, child: const Text('追加')),
      ],
    );
  }
}
