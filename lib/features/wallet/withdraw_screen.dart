import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:insta_in/features/profile/edit_profile_screen.dart';

class WithdrawScreen extends StatefulWidget {
  final int currentBalance;
  
  const WithdrawScreen({super.key, required this.currentBalance});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  String _upiId = '';
  String _upiNumber = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Pre-fill the amount with the current balance
    if (widget.currentBalance > 0) {
      _amountController.text = widget.currentBalance.toString();
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _upiId = doc.data()!['upiId'] ?? '';
            _upiNumber = doc.data()!['upiNumber'] ?? '';
            _isLoadingProfile = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_upiId.isEmpty && _upiNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please update your UPI ID or Number in Edit Profile first.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough balance!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final withdrawalRef = FirebaseFirestore.instance.collection('withdrawals').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('User profile not found.');
        }

        final int currentCoins = userSnapshot.data()?['coins'] ?? 0;
        if (amount > currentCoins) {
          throw Exception('Not enough balance!');
        }

        // Add to withdrawals collection
        transaction.set(withdrawalRef, {
          'userId': user.uid,
          'amount': amount,
          'status': 'pending',
          'upiId': _upiId,
          'upiNumber': _upiNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context); // Go back to wallet screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Money', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D28D9), AppTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.indianRupee, color: Colors.amber, size: 36),
                              const SizedBox(width: 12),
                              Text(
                                '${widget.currentBalance}',
                                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // UPI Info Warning (if missing)
                    if (_upiId.isEmpty && _upiNumber.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: AppTheme.error, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Missing UPI Details',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please update your UPI ID or Number in the Edit Profile screen before withdrawing.',
                                    style: TextStyle(color: AppTheme.error, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                        );
                                        _loadUserProfile();
                                      },
                                      icon: const Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                                      label: const Text(
                                        'Add UPI Details',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Withdrawal Form
                    const Text('Withdrawal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount to Withdraw (₹)',
                              prefixIcon: Icon(LucideIcons.indianRupee),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = int.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid positive amount';
                              }
                              if (amount > widget.currentBalance) {
                                return 'Not enough balance';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isSubmitting || (_upiId.isEmpty && _upiNumber.isEmpty) || widget.currentBalance <= 0)
                                  ? null
                                  : _submitWithdrawal,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Request Withdrawal'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Withdrawal History
                    const Text('Withdrawal History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('withdrawals')
                          .where('userId', isEqualTo: user?.uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No withdrawal requests yet.', style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            
                            final amount = data['amount'] ?? 0;
                            final status = data['status'] ?? 'pending';
                            
                            Color statusColor;
                            IconData statusIcon;
                            if (status == 'approved') {
                              statusColor = AppTheme.success;
                              statusIcon = LucideIcons.checkCircle2;
                            } else if (status == 'rejected') {
                              statusColor = AppTheme.error;
                              statusIcon = LucideIcons.xCircle;
                            } else {
                              statusColor = Colors.amber;
                              statusIcon = LucideIcons.clock;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(statusIcon, color: statusColor),
                                title: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Status: ${status.toUpperCase()}'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
