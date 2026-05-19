import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _utrController = TextEditingController();
  final _pageController = PageController();
  int _currentQRIndex = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _utrController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = int.parse(_amountController.text.trim());
      final utr = _utrController.text.trim();

      // Check if this is the first deposit
      final pastDeposits = await FirebaseFirestore.instance
          .collection('deposits')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final isFirstDeposit = pastDeposits.docs.isEmpty;

      // Add to deposits collection
      await FirebaseFirestore.instance.collection('deposits').add({
        'userId': user.uid,
        'amount': amount,
        'utr': utr,
        'status': 'pending',
        'isFirstDeposit': isFirstDeposit,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit request submitted! Waiting for approval.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _amountController.clear();
        _utrController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  void _copyUPI() {
    Clipboard.setData(const ClipboardData(text: '7427019465@ibl'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.gift, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Time Bonus!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add ₹100 for the first time and get ₹120 in your wallet!',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // QR Code Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Scan to Pay',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setLocalState) {
                          return Column(
                            children: [
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setLocalState(() {
                                      _currentQRIndex = index;
                                    });
                                  },
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(8),
                                        child: Image.asset(
                                          'assets/upi1.jpeg',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(8),
                                        child: Image.asset(
                                          'assets/upi2.jpeg',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(2, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 8,
                                    width: _currentQRIndex == index ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: _currentQRIndex == index
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '7427019465@ibl',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            InkWell(
                              onTap: _copyUPI,
                              child: const Icon(LucideIcons.copy, color: AppTheme.primary, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Deposit Form
              const Text('Submit Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid (₹)',
                        prefixIcon: Icon(LucideIcons.indianRupee),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _utrController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'UTR / Transaction ID',
                        prefixIcon: Icon(LucideIcons.hash),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter UTR number';
                        }
                        if (value.length < 12) {
                          return 'UTR usually contains 12 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitDeposit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit for Approval'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Deposit History
              const Text('Deposit History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('deposits')
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
                        child: Text('No deposit requests yet.', style: TextStyle(color: AppTheme.textSecondary)),
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
                      final utr = data['utr'] ?? '';
                      
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
                          subtitle: Text('UTR: $utr\nStatus: ${status.toUpperCase()}'),
                          isThreeLine: true,
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
