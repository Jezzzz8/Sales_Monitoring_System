import 'package:flutter/material.dart';

enum UserRole {
  owner,
  admin,
  cashier,
  staff,
}

class User {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? phone;
  final String? address;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'phone': phone,
      'address': address,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullName: map['fullName'],
      email: map['email'],
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      phone: map['phone'],
      address: map['address'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phone,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.staff:
        return 'Staff';
    }
  }

  Color get roleColor {
    switch (role) {
      case UserRole.owner:
        return Colors.deepOrange;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.cashier:
        return Colors.blue;
      case UserRole.staff:
        return Colors.green;
    }
  }

  IconData get roleIcon {
    switch (role) {
      case UserRole.owner:
        return Icons.business;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.cashier:
        return Icons.point_of_sale;
      case UserRole.staff:
        return Icons.people;
    }
  }
}