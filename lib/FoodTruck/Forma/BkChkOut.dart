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
  bool _isSaving = false; // To prevent double clicks

  // ====================================================================
  //                        DISCOUNT CODE MATCHING
  // ====================================================================

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

  // ====================================================================
  //DISCOUNT CODE VALIDATION
  // ====================================================================

  void appDscount(double SelPaxProis) {
    String dscountKod = dscountCtrl.text.trim();
    double calcProis = dscountProis(SelPaxProis, dscountKod);

    if (calcProis == SelPaxProis) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid Discount Code'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      setState(() {
        finProis = calcProis;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Great Discount, Happy Booking!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  // ====================================================================
  // SAVE BOOKING TO DATABASE
  // ====================================================================

  Future<void> saveBooking() async {
    if (_isSaving) return; // Prevent double click

    setState(() {
      _isSaving = true;
    });

    print("=== DEBUG: saveBooking() CALLED! ===");

    final formaProvider = Provider.of<FormaPDat>(context, listen: false);
    final ftpProvider = Provider.of<FTPDat>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    print("=== DEBUG: Selected packages count: ${ftpProvider.selPax.length}");

    if (ftpProvider.selPax.isEmpty) {
      print("=== DEBUG: WARNING! No packages to save!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one package!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Prepare booking data
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
      print("=== DEBUG: Starting database transaction...");

      // Start a database transaction
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        // Insert booking
        final bookingId = await txn.insert('truckbook', bookingData);
        print("=== DEBUG: Booking inserted with ID: $bookingId");

        if (bookingId > 0) {
          // Save each package
          for (var pck in ftpProvider.selPax) {
            print("=== DEBUG: Inserting package: ${pck['ft']} - ${pck['pax']}");

            final packageData = {
              'booking_id': bookingId,
              'food_truck': pck['ft']?.toString() ?? 'Unknown',
              'package_name': pck['pax']?.toString() ?? 'Unknown',
              'price': (pck['prois'] ?? 0.0).toDouble(),
              'quantity': (pck['qty'] ?? 1).toInt(),
            };

            print("=== DEBUG: Package data: $packageData");

            final res = await txn.insert('booking_packages', packageData);
            print("=== DEBUG: Package inserted with ID: $res");
          }

          // Verify insertion
          final packages = await txn.query(
            'booking_packages',
            where: 'booking_id = ?',
            whereArgs: [bookingId],
          );
          print("=== DEBUG: Verification - packages count: ${packages.length}");
          print("=== DEBUG: Packages: $packages");
        }
      });

      print("=== DEBUG: Booking saved successfully!");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (widget.onBookingSaved != null) {
        widget.onBookingSaved!(); // call the callback to go to rating
      } else {
        Navigator.pop(context); // fallback
      }
    } catch (e) {
      print('=== DEBUG: Error saving booking: $e');
      print('=== DEBUG: Error stack trace: ${e.toString()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving booking: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final ftP = Provider.of<FTPDat>(context);
    final formaP = Provider.of<FormaPDat>(context);

    // DEBUG: Print selected packages on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("=== DEBUG BkChkOut Build:");
      print("  Selected packages: ${ftP.selPax}");
      print("  Package count: ${ftP.selPax.length}");
    });

    double chkProis = ftP.totProis;
    double discountReduction = chkProis - (finProis > 0 ? finProis : chkProis);

    // Get data from Event Info page via Provider
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Booking Information'),
        actions: [
          // Add save button in app bar too
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _isSaving ? null : saveBooking,
            tooltip: 'Save Booking',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User Details:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 8),
                            Text('Name: ${formaP.full_name ?? 'Not Provided'}'),
                            Text(
                                'Address: ${formaP.address ?? 'Not Provided'}'),
                            Text('Phone: ${formaP.phone_no ?? 'Not Provided'}'),
                            Text('Email: ${formaP.email ?? 'Not Provided'}'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Event Info Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Event Info:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 8),
                            Text('Booking Date: $forBookDate'),
                            Text(
                                'Event Start-End Date: $forStartDate - $forEndDate'),
                            Text(
                                'Event Start-End Time: ${formaP.event_start_time?.format(context) ?? 'Not Provided'} - ${formaP.event_end_time?.format(context) ?? 'Not Provided'}'),
                            Text(
                                'Food Truck Decoration: ${formaP.add_req == true ? "Yes" : (formaP.add_req == false ? "No" : "Not Provided")}'),
                            Text(
                                'Food Selling Type: ${formaP.food_sell_types ?? 'Not Provided'}'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Pricing Section
                    Text(
                      'Pricing Details:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Original Total Price:',
                                  style: TextStyle(fontSize: 16)),
                              Text(
                                'RM${chkProis.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      finProis > 0 ? Colors.grey : Colors.black,
                                  decoration: finProis > 0
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Discount Reduction (if any)
                          if (discountReduction > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount Reduction:',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.red)),
                                Text(
                                  '- RM${discountReduction.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.red),
                                ),
                              ],
                            ),
                          SizedBox(height: 8),
                          // Final Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Price:',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              Text(
                                'RM${(finProis > 0 ? finProis : chkProis).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Discount Section
                    Text(
                      'Apply Discount:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dscountCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter Discount Code',
                              hintText: 'Enter Discount Code',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 10),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => appDscount(chkProis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Apply',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Selected Packages List
                    Text(
                      'Selected Packages:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    if (ftP.selPax.isEmpty)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Center(
                          child: Text(
                            'No packages selected yet!',
                            style: TextStyle(color: Colors.amber[800]),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: ftP.selPax.length,
                        itemBuilder: (context, index) {
                          final pck = ftP.selPax[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('${pck['ft']} (${pck['pax']})',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'RM${pck['prois'].toStringAsFixed(2)} each'),
                                  Text('Quantity: ${pck['qty'] ?? 1}',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: Text(
                                'RM${((pck['prois'] ?? 0) * (pck['qty'] ?? 1)).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700]),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'RM${(finProis > 0 ? finProis : chkProis).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : saveBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
