import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TransactionType { bet, win, deposit, reset }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String description;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}

class WalletProvider extends ChangeNotifier {
  double _balance = 10000.0;
  double _totalWagered = 0.0;
  int _totalWins = 0;
  double _biggestWin = 0.0;
  int _gamesPlayed = 0;
  List<Transaction> _transactions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WalletProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserData();
      } else {
        _resetLocalData();
      }
    });
  }

  double get balance => _balance;
  double get totalWagered => _totalWagered;
  int get totalWins => _totalWins;
  double get biggestWin => _biggestWin;
  int get gamesPlayed => _gamesPlayed;
  List<Transaction> get transactions => List.unmodifiable(_transactions.reversed);

  void _resetLocalData() {
    _balance = 10000.0;
    _totalWagered = 0.0;
    _totalWins = 0;
    _biggestWin = 0.0;
    _gamesPlayed = 0;
    _transactions = [];
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _balance = (data['balance'] as num?)?.toDouble() ?? 10000.0;
      _totalWagered = (data['totalWagered'] as num?)?.toDouble() ?? 0.0;
      _totalWins = (data['totalWins'] as num?)?.toInt() ?? 0;
      _biggestWin = (data['biggestWin'] as num?)?.toDouble() ?? 0.0;
      _gamesPlayed = (data['gamesPlayed'] as num?)?.toInt() ?? 0;
    }

    final txSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: false)
        .limitToLast(50)
        .get();

    _transactions = txSnapshot.docs
        .map((doc) => Transaction.fromMap(doc.data()))
        .toList();

    notifyListeners();
  }

  Future<void> _updateFirestoreStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'balance': _balance,
      'totalWagered': _totalWagered,
      'totalWins': _totalWins,
      'biggestWin': _biggestWin,
      'gamesPlayed': _gamesPlayed,
    }, SetOptions(merge: true));
  }

  bool placeBet(double amount, {String game = 'Game'}) {
    if (amount <= 0 || amount > _balance) {
      return false;
    }
    _balance -= amount;
    _totalWagered += amount;
    _gamesPlayed++;
    
    _addTransaction(
      amount: -amount,
      type: TransactionType.bet,
      description: 'Bet on $game',
    );
    
    _updateFirestoreStats();
    notifyListeners();
    return true;
  }

  void addWinnings(double amount, {String game = 'Game'}) {
    if (amount > 0) {
      _balance += amount;
      _totalWins++;
      if (amount > _biggestWin) {
        _biggestWin = amount;
      }
      
      _addTransaction(
        amount: amount,
        type: TransactionType.win,
        description: 'Win from $game',
      );
      
      _updateFirestoreStats();
      notifyListeners();
    }
  }

  void deposit(double amount) {
    if (amount > 0) {
      _balance += amount;
      _addTransaction(
        amount: amount,
        type: TransactionType.deposit,
        description: 'Deposit via Gateway',
      );
      _updateFirestoreStats();
      notifyListeners();
    }
  }

  void resetDemoMoney() {
    _balance = 10000.0;
    _totalWagered = 0.0;
    _totalWins = 0;
    _biggestWin = 0.0;
    _gamesPlayed = 0;
    
    _addTransaction(
      amount: 10000.0,
      type: TransactionType.reset,
      description: 'Wallet Reset',
    );
    
    _updateFirestoreStats();
    notifyListeners();
  }

  void _addTransaction({
    required double amount,
    required TransactionType type,
    required String description,
  }) {
    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: type,
      date: DateTime.now(),
      description: description,
    );

    _transactions.add(tx);
    if (_transactions.length > 50) {
      _transactions.removeAt(0);
    }

    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(tx.id)
          .set(tx.toMap());
    }
  }
}
