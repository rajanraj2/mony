import 'package:flutter/material.dart';

class IconItem {
  final String id;
  final String name;
  final String category;
  final IconData iconData;
  final List<String> tags;

  const IconItem({
    required this.id,
    required this.name,
    required this.category,
    required this.iconData,
    required this.tags,
  });
}

class IconRegistry {
  IconRegistry._();

  static const List<IconItem> allIcons = [
    // Finance & Banking
    IconItem(id: 'account_balance', name: 'Bank Vault', category: 'Finance', iconData: Icons.account_balance, tags: ['bank', 'vault', 'savings', 'branch']),
    IconItem(id: 'account_balance_wallet', name: 'Wallet', category: 'Finance', iconData: Icons.account_balance_wallet, tags: ['wallet', 'cash', 'money', 'purse']),
    IconItem(id: 'credit_card', name: 'Credit Card', category: 'Finance', iconData: Icons.credit_card, tags: ['card', 'visa', 'mastercard', 'debit', 'plastic']),
    IconItem(id: 'payments', name: 'Cash Cashier', category: 'Finance', iconData: Icons.payments, tags: ['notes', 'cash', 'bills', 'currency', 'rupee', 'dollar']),
    IconItem(id: 'savings', name: 'Piggy Bank', category: 'Finance', iconData: Icons.savings, tags: ['piggy', 'save', 'goal', 'deposit']),
    IconItem(id: 'monetization_on', name: 'Gold Coin', category: 'Finance', iconData: Icons.monetization_on, tags: ['coin', 'gold', 'income', 'wealth']),
    IconItem(id: 'trending_up', name: 'Stock Growth', category: 'Finance', iconData: Icons.trending_up, tags: ['stocks', 'invest', 'shares', 'equity', 'cagr', 'profit']),
    IconItem(id: 'show_chart', name: 'Market Chart', category: 'Finance', iconData: Icons.show_chart, tags: ['crypto', 'market', 'bitcoin', 'etf', 'index', 'nifty']),
    IconItem(id: 'receipt_long', name: 'Receipt Bill', category: 'Finance', iconData: Icons.receipt_long, tags: ['bill', 'receipt', 'invoice', 'statement', 'tax']),
    IconItem(id: 'price_check', name: 'Price Tag', category: 'Finance', iconData: Icons.price_check, tags: ['price', 'discount', 'cost', 'sale']),
    
    // Living & Household
    IconItem(id: 'home', name: 'Home & Rent', category: 'Living', iconData: Icons.home, tags: ['house', 'rent', 'flat', 'mortgage', 'apartment']),
    IconItem(id: 'electrical_services', name: 'Electricity', category: 'Living', iconData: Icons.electrical_services, tags: ['electricity', 'power', 'bills', 'energy']),
    IconItem(id: 'water_drop', name: 'Water & Utilities', category: 'Living', iconData: Icons.water_drop, tags: ['water', 'utility', 'pipeline']),
    IconItem(id: 'wifi', name: 'Internet & WiFi', category: 'Living', iconData: Icons.wifi, tags: ['internet', 'broadband', 'wifi', 'data', 'fiber']),
    IconItem(id: 'cleaning_services', name: 'Cleaning & Maid', category: 'Living', iconData: Icons.cleaning_services, tags: ['clean', 'maid', 'maintenance', 'laundry']),
    
    // Food & Dining
    IconItem(id: 'restaurant', name: 'Restaurant Dining', category: 'Food', iconData: Icons.restaurant, tags: ['food', 'dine', 'dinner', 'lunch', 'zomato', 'swiggy']),
    IconItem(id: 'local_cafe', name: 'Coffee & Drinks', category: 'Food', iconData: Icons.local_cafe, tags: ['coffee', 'tea', 'cafe', 'chai', 'starbucks', 'beverage']),
    IconItem(id: 'local_grocery_store', name: 'Groceries Supermarket', category: 'Food', iconData: Icons.local_grocery_store, tags: ['groceries', 'market', 'vegetables', 'supermarket']),
    IconItem(id: 'fastfood', name: 'Fast Food', category: 'Food', iconData: Icons.fastfood, tags: ['burger', 'pizza', 'snacks', 'takeout']),
    IconItem(id: 'local_bar', name: 'Bar & Nightlife', category: 'Food', iconData: Icons.local_bar, tags: ['beer', 'wine', 'bar', 'party', 'drinks']),

    // Transport & Vehicles
    IconItem(id: 'directions_car', name: 'Car & Taxi', category: 'Transport', iconData: Icons.directions_car, tags: ['car', 'uber', 'ola', 'taxi', 'drive']),
    IconItem(id: 'local_gas_station', name: 'Fuel & Gas', category: 'Transport', iconData: Icons.local_gas_station, tags: ['fuel', 'petrol', 'diesel', 'gas', 'cng']),
    IconItem(id: 'two_wheeler', name: 'Motorcycle & Scooter', category: 'Transport', iconData: Icons.two_wheeler, tags: ['bike', 'scooter', 'motorcycle']),
    IconItem(id: 'flight', name: 'Flight & Travel', category: 'Transport', iconData: Icons.flight, tags: ['plane', 'flight', 'airline', 'vacation', 'holiday', 'trip']),
    IconItem(id: 'train', name: 'Train & Metro', category: 'Transport', iconData: Icons.train, tags: ['metro', 'train', 'rail', 'commute']),

    // Shopping & Entertainment
    IconItem(id: 'shopping_bag', name: 'Shopping & Clothes', category: 'Leisure', iconData: Icons.shopping_bag, tags: ['shopping', 'clothes', 'fashion', 'mall', 'amazon']),
    IconItem(id: 'movie', name: 'Movies & Cinema', category: 'Leisure', iconData: Icons.movie, tags: ['movie', 'cinema', 'theatre', 'netflix', 'hotstar']),
    IconItem(id: 'sports_esports', name: 'Gaming', category: 'Leisure', iconData: Icons.sports_esports, tags: ['games', 'playstation', 'xbox', 'steam']),
    IconItem(id: 'fitness_center', name: 'Gym & Fitness', category: 'Health', iconData: Icons.fitness_center, tags: ['gym', 'workout', 'fitness', 'sports', 'trainer']),
    IconItem(id: 'medical_services', name: 'Doctor & Hospital', category: 'Health', iconData: Icons.medical_services, tags: ['health', 'medical', 'hospital', 'doctor', 'clinic', 'medicine']),
    IconItem(id: 'school', name: 'Education & Courses', category: 'Education', iconData: Icons.school, tags: ['college', 'course', 'books', 'school', 'tuition', 'fee']),
  ];

  static List<IconItem> search(String query) {
    if (query.trim().isEmpty) return allIcons;
    final q = query.toLowerCase().trim();
    return allIcons.where((item) {
      if (item.name.toLowerCase().contains(q)) return true;
      if (item.category.toLowerCase().contains(q)) return true;
      return item.tags.any((t) => t.contains(q));
    }).toList();
  }

  static IconData getIconOrDefault(String id, [IconData fallback = Icons.category]) {
    final match = allIcons.firstWhere((i) => i.id == id, orElse: () => allIcons.first);
    return match.id == id ? match.iconData : fallback;
  }
}
