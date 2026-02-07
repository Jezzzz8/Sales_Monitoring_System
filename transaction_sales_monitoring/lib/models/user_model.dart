// lib/models/user_model.dart - FIXED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserRole {
  owner,
  admin,
  cashier,
  clerk,
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
      'name': fullName,
      'email': email,
      'role': role.name,
      'active': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'phone': phone,
      'address': address,
    };
  }

  static User fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.clerk,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      phone: data['phone'],
      address: data['address'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email.toLowerCase(),
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : FieldValue.serverTimestamp(),
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
      updatedAt: updatedAt ?? this.updatedAt,
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
      case UserRole.clerk:
        return 'Clerk';
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
      case UserRole.clerk:
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
      case UserRole.clerk:
        return Icons.people;
    }
  }

  // FIXED: Add missing displayName getter
  String get displayName => fullName.isNotEmpty ? fullName : username;
}