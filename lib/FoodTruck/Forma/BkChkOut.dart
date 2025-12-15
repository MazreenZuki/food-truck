import 'package:fdb/FoodTruck/Forma/FormaDat/_FTPDat.dart';
import 'package:fdb/User/userProv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'FormaDat/_FormaPDat.dart';
import '../../db/database_helper.dart';

class BkChkOut extends StatefulWidget {
  final VoidCallback? onBookingSaved;
  const BkChkOut({super.key, this.onBookingSaved});

  @override
  BkChkOutState createState() => BkChkOutState();
}

class BkChkOutState extends State<BkChkOut> {
  final TextEditingController dscountCtrl = TextEditingController();
  double finProis = 0.0;
  bool _isSaving = false;
  bool _discountApplied = false;

  double dscountProis(double SelPaxProis, String? dscountKod) {
    if (dscountKod == null || dscountKod.isEmpty) {
      return SelPaxProis;
    } else if (dscountKod == "FT10") {
      return (SelPaxProis * 0.9);
    } else if (dscountKod == "NEWME25") {
      return (SelPaxProis * 0.75);
    } else if (dscountKod == "RAHMAHB40") {
      return (SelPaxProis * 0.6);
    } else {
      return SelPaxProis;
    }
  }

  void appDscount(double SelPaxProis) {
    String dscountKod = dscountCtrl.text.trim();
    double calcProis = dscountProis(SelPaxProis, dscountKod);

    if (calcProis == SelPaxProis) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid discount code'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _discountApplied = false;
      });
    } else {
      setState(() {
        finProis = calcProis;
        _discountApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount applied successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> saveBooking() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final ftpProvider = Provider.of<FTPDat>(context, listen: false);
    final formaProvider = Provider.of<FormaPDat>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (ftpProvider.selPax.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one package!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final bookingData = {
      'userid': userProvider.userId,
      'book_date': formaProvider.booking_date != null
          ? DateFormat('yyyy-MM-dd').format(formaProvider.booking_date!)
          : '',
      'booktime': formaProvider.booking_date != null
          ? DateFormat('HH:mm:ss').format(formaProvider.booking_date!)
          : '',
      'eventdate':
          formaProvider.event_date_range?.start.toIso8601String() ?? '',
      'eventtime': formaProvider.event_start_time != null &&
              formaProvider.event_end_time != null
          ? '${formaProvider.event_start_time!.format(context)} - ${formaProvider.event_end_time!.format(context)}'
          : '',
      'foodtrucktype': formaProvider.food_sell_types ?? 'Not Provided',
      'numberofdays': formaProvider.event_date_range != null
          ? formaProvider.event_date_range!.end
                  .difference(formaProvider.event_date_range!.start)
                  .inDays +
              1
          : 0,
      'price': finProis > 0 ? finProis : ftpProvider.totProis,
    };

    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final bookingId = await txn.insert('truckbook', bookingData);

        if (bookingId > 0) {
          for (var pck in ftpProvider.selPax) {
            final packageData = {
              'booking_id': bookingId,
              'food_truck': pck['ft']?.toString() ?? 'Unknown',
              'package_name': pck['pax']?.toString() ?? 'Unknown',
              'price': (pck['prois'] ?? 0.0).toDouble(),
              'quantity': (pck['qty'] ?? 1).toInt(),
            };
            await txn.insert('booking_packages', packageData);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onBookingSaved != null) {
        widget.onBookingSaved!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving booking: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildInfoCard(String title, List<Widget> content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ftP = Provider.of<FTPDat>(context);
    final formaP = Provider.of<FormaPDat>(context);

    double chkProis = ftP.totProis;
    double discountReduction = chkProis - (finProis > 0 ? finProis : chkProis);
    double finalPrice = finProis > 0 ? finProis : chkProis;

    DateTime? bookDate = formaP.booking_date;
    String forBookDate = bookDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(bookDate)
        : 'Not set';

    DateTime? startDateRange = formaP.event_date_range?.start;
    String forStartDate = startDateRange != null
        ? DateFormat('dd/MM/yyyy').format(startDateRange)
        : 'Not set';

    DateTime? endDateRange = formaP.event_date_range?.end;
    String forEndDate = endDateRange != null
        ? DateFormat('dd/MM/yyyy').format(endDateRange)
        : 'Not set';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Summary',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : saveBooking,
            tooltip: 'Save Booking',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Details Card
                    _buildInfoCard('USER DETAILS', [
                      _buildInfoRow('Name', formaP.full_name ?? 'Not provided'),
                      _buildInfoRow(
                          'Address', formaP.address ?? 'Not provided'),
                      _buildInfoRow('Phone', formaP.phone_no ?? 'Not provided'),
                      _buildInfoRow('Email', formaP.email ?? 'Not provided'),
                    ]),

                    SizedBox(height: 20),

                    // Event Info Card
                    _buildInfoCard('EVENT INFORMATION', [
                      _buildInfoRow('Booking Date', forBookDate),
                      _buildInfoRow(
                          'Event Date', '$forStartDate - $forEndDate'),
                      _buildInfoRow('Event Time',
                          '${formaP.event_start_time?.format(context) ?? 'Not set'} - ${formaP.event_end_time?.format(context) ?? 'Not set'}'),
                      _buildInfoRow('Food Truck Type',
                          formaP.food_sell_types ?? 'Not provided'),
                      _buildInfoRow(
                          'Decoration Required',
                          formaP.add_req == true
                              ? "Yes"
                              : (formaP.add_req == false
                                  ? "No"
                                  : "Not provided")),
                    ]),

                    SizedBox(height: 20),

                    // Pricing Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey[50]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  'PRICE BREAKDOWN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.purple[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildInfoRow(
                                'Subtotal', 'RM${chkProis.toStringAsFixed(2)}'),
                            if (_discountApplied) ...[
                              SizedBox(height: 8),
                              _buildInfoRow('Discount',
                                  '- RM${discountReduction.toStringAsFixed(2)}'),
                            ],
                            Divider(height: 30, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                Text(
                                  'RM${finalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Discount Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_offer_outlined,
                                    color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'APPLY DISCOUNT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: dscountCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: Colors.blue),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      hintText: 'Enter discount code',
                                      prefixIcon: Icon(
                                          Icons.confirmation_number_outlined),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Colors.deepOrange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => appDscount(chkProis),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'APPLY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_discountApplied) ...[
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Discount applied! You saved RM${discountReduction.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Selected Packages Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey[50]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.fastfood_outlined,
                                    color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'SELECTED PACKAGES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${ftP.selPax.length} items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (ftP.selPax.isEmpty)
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.warning_amber_outlined,
                                        color: Colors.amber, size: 40),
                                    SizedBox(height: 12),
                                    Text(
                                      'No packages selected',
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Please go back and select at least one package',
                                      style: TextStyle(
                                        color: Colors.amber[600],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children:
                                    ftP.selPax.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final pck = entry.value;
                                  final subtotal =
                                      ((pck['prois'] ?? 0) * (pck['qty'] ?? 1));

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${pck['ft'] ?? 'Unknown'}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: Colors.grey[900],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${pck['pax'] ?? 'Unknown'} Package',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'RM${(pck['prois'] ?? 0).toStringAsFixed(2)} each × ${pck['qty'] ?? 1}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'RM${subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar - FIXED VERSION
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'RM${finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 160, // Fixed width to prevent overflow
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm Booking',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
