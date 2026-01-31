
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final List<Map<String, dynamic>> selectedPackages;
  final double totalAmount;

  const PaymentPage({
    Key? key,
    required this.bookingData,
    required this.selectedPackages,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'Cash';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 1,
        backgroundColor: Colors.purple[100],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalAmountCard(),
            SizedBox(height: 24),
            _buildPaymentMethodCard(),
            SizedBox(height: 32),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text('Total Amount',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('RM ${widget.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          SizedBox(height: 20),
          _buildPaymentMethodOption(
              method: 'Cash',
              title: 'Cash Payment',
              subtitle: 'Pay in cash on event day',
              icon: Icons.money,
              color: Colors.green),
          SizedBox(height: 16),
          _buildPaymentMethodOption(
              method: 'Transfer',
              title: 'Bank Transfer',
              subtitle: 'Transfer to bank account',
              icon: Icons.account_balance,
              color: Colors.blue),
          if (_selectedPaymentMethod == 'Transfer') ...[
            SizedBox(height: 20),
            _buildTransferDetails(),
          ],
        ]),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
      {required String method,
      required String title,
      required String subtitle,
      required IconData icon,
      required Color color}) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(children: [
          Container(
              padding: EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 28)),
          SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ])),
          Radio<String>(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
              activeColor: color),
        ]),
      ),
    );
  }

  Widget _buildTransferDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          SizedBox(width: 8),
          Text('Bank Transfer Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
        ]),
        Divider(height: 24, color: Colors.blue[200]),
        _buildTransferRow('Bank Name', 'Maybank'),
        SizedBox(height: 12),
        _buildTransferRow('Account Name', 'Food Truck Booking Sdn Bhd'),
        SizedBox(height: 12),
        _buildTransferRow('Account Number', '1234 5678 9012'),
        SizedBox(height: 12),
        _buildTransferRow('Reference', 'FTB${DateTime.now().millisecondsSinceEpoch}'),
      ]),
    );
  }

  Widget _buildTransferRow(String label, String value) {
    return Row(children: [
      SizedBox(width: 120, child: Text(label)),
      Text(': '),
      Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        child: _isProcessing ? CircularProgressIndicator() : Text('Confirm Payment'),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => _isProcessing = false);
    Navigator.pop(context, true);
  }
}
