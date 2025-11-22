import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:openapi/api.dart';
import 'package:frontend/features/attendance/data/providers.dart';
import 'package:frontend/features/attendance/presentation/screens/card_management_screen.dart';
import 'package:frontend/features/attendance/data/nfc_reader_interface.dart';

// Mock Classes
class MockCardsApi implements CardsApi {
  @override
  ApiClient get apiClient => ApiClient();

  @override
  Future<Response> cardControllerListCardsWithHttpInfo(num employeeId) async {
    final cards = [
      {'id': 1, 'card_id': 'card1', 'name': 'Main Card', 'is_active': true},
      {'id': 2, 'card_id': 'card2', 'name': 'Backup Card', 'is_active': false},
    ];
    return Response(json.encode(cards), 200);
  }

  @override
  Future<void> cardControllerCreateCard(
    num employeeId,
    CreateCardDto createCardDto,
  ) async {
    return Future.value();
  }

  @override
  Future<void> cardControllerDeleteCard(num employeeId, num cardId) async {
    return Future.value();
  }

  @override
  Future<void> cardControllerUpdateCard(
    num employeeId,
    num cardId,
    UpdateCardDto updateCardDto,
  ) async {
    return Future.value();
  }

  // Unused methods required by interface
  @override
  Future<Response> cardControllerCreateCardWithHttpInfo(
    num employeeId,
    CreateCardDto createCardDto,
  ) async {
    return Response('', 201);
  }

  @override
  Future<Response> cardControllerDeleteCardWithHttpInfo(
    num employeeId,
    num cardId,
  ) async {
    return Response('', 200);
  }

  @override
  Future<void> cardControllerListCards(num employeeId) async {
    // This one is void in generated code but we use WithHttpInfo in the app
    return Future.value();
  }

  @override
  Future<Response> cardControllerUpdateCardWithHttpInfo(
    num employeeId,
    num cardId,
    UpdateCardDto updateCardDto,
  ) async {
    return Response('', 200);
  }
}

class MockNfcReader implements NfcReaderInterface {
  final StreamController<String> _cardController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get cardStream => _cardController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> dispose() async {
    await _cardController.close();
  }

  @override
  bool get isConnected => true;

  void simulateTap(String cardId) {
    _cardController.add(cardId);
  }
}

void main() {
  testWidgets('CardManagementScreen loads and displays cards', (
    WidgetTester tester,
  ) async {
    final mockApi = MockCardsApi();
    final mockNfc = MockNfcReader();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cardsApiProvider.overrideWithValue(mockApi),
          nfcReaderProvider.overrideWithValue(mockNfc),
        ],
        child: const MaterialApp(
          home: CardManagementScreen(
            employeeId: 1,
            employeeName: 'Test Employee',
          ),
        ),
      ),
    );

    // Initial load
    await tester.pump(); // Start future
    await tester.pump(); // Finish future

    // Verify cards are displayed
    expect(find.text('Main Card'), findsOneWidget);
    expect(find.text('card1'), findsOneWidget);
    expect(find.text('Backup Card'), findsOneWidget);
    expect(find.text('card2'), findsOneWidget);
  });

  testWidgets('AddCardDialog scans NFC card', (WidgetTester tester) async {
    final mockApi = MockCardsApi();
    final mockNfc = MockNfcReader();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cardsApiProvider.overrideWithValue(mockApi),
          nfcReaderProvider.overrideWithValue(mockNfc),
        ],
        child: const MaterialApp(
          home: CardManagementScreen(
            employeeId: 1,
            employeeName: 'Test Employee',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open Add Card Dialog
    await tester.tap(find.text('Add Card'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Card'), findsOneWidget);

    // Tap Scan button
    await tester.tap(find.text('Scan NFC Card'));
    await tester.pump();

    // Simulate NFC tap
    mockNfc.simulateTap('new-card-id');
    await tester.pump();

    // Verify card ID is filled
    expect(find.text('new-card-id'), findsOneWidget);
  });
}
