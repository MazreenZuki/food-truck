import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import '../FoodTruck/FT_Conf/FTSelect.dart';
import '../db/database_helper.dart';

class EditBookingPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onUpdate;

  const EditBookingPage({
    required this.booking,
    required this.onUpdate,
    Key? key,
  }) : super(key: key);

  @override
  _EditBookingPageState createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  final List<DropdownMenuItem<String>> _dropdownItems = [
    DropdownMenuItem(value: 'Buffet', child: Text('Buffet')),
    DropdownMenuItem(value: 'Food Stalls', child: Text('Food Stalls')),
    DropdownMenuItem(value: 'Takeaway', child: Text('Takeaway')),
  ];

  List<Map<String, dynamic>> cart = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  double get _totalPrice {
    double total = 0;
    for (var item in cart) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _initEventTime();
    _loadBookingPackages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDatabaseStructure();
      _testDatabaseMethodsDirectly(); // ADD THIS LINE
    });
  }

  void _initEventTime() {
    final eventTimeStr = widget.booking['eventtime']; // e.g., "13:00 - 18:00"
    if (eventTimeStr != null && eventTimeStr.contains(" - ")) {
      try {
        final parts = eventTimeStr.split(" - ");
        final start = DateFormat.Hm().parse(parts[0].trim());
        final end = DateFormat.Hm().parse(parts[1].trim());
        _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
        _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      } catch (_) {
        _startTime = TimeOfDay(hour: 13, minute: 0);
        _endTime = TimeOfDay(hour: 18, minute: 0);
      }
    }
  }

  void _checkDatabaseStructure() async {
    print("\n" + "=" * 60);
    print("=== DATABASE DIAGNOSTIC CHECK ===");

    try {
      // First, check if booking exists
      print("1. Checking if booking ID 6 exists...");
      final booking = await DatabaseHelper.instance.getBookingById(6);
      print("   Booking exists: ${booking != null}");
      if (booking != null) {
        print("   Booking data: $booking");
      }

      // Check all booking packages table (if you have such a method)
      print("\n2. Checking ALL booking packages...");
      // If you have a method to get all booking packages
      // final allPackages = await DatabaseHelper.instance.getAllBookingPackages();
      // print("   All packages in DB: $allPackages");

      // Test insert a dummy package
      print("\n3. Testing package insertion...");
      try {
        await DatabaseHelper.instance.updateBookingPackage(
          6,
          "TEST_TRUCK",
          "TEST_PACKAGE",
          1,
        );
        print("   ✓ Test insertion successful");

        // Now try to fetch it back
        print("\n4. Fetching test package...");
        final testFetch = await DatabaseHelper.instance.getBookingPackages(6);
        print("   Packages after test insert: $testFetch");

        // Clean up test data
        print("\n5. Cleaning up test data...");
        // You'll need a delete method
        // await DatabaseHelper.instance.deleteBookingPackage(6, "TEST_TRUCK", "TEST_PACKAGE");
      } catch (e) {
        print("   ✗ Test insertion failed: $e");
      }
    } catch (e) {
      print("Diagnostic error: $e");
    }

    print("=" * 60 + "\n");
  }

  // Add this method to your EditBookingPage
  void _testDatabaseMethodsDirectly() async {
    print("\n" + "=" * 60);
    print("=== DIRECT DATABASE METHOD TEST ===");

    // First, let's see what the actual SQLite database contains
    print("1. Querying database directly with raw SQL...");

    try {
      final db = await DatabaseHelper.instance.database;

      // First, check what tables exist
      print("\n2. Checking existing tables...");
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;");
      print("   Tables in database:");
      for (var table in tables) {
        print("   - ${table['name']}");
      }

      // Check if booking_packages table exists
      print("\n3. Checking booking_packages table structure...");
      final tableInfo =
          await db.rawQuery("PRAGMA table_info(booking_packages);");
      if (tableInfo.isEmpty) {
        print("   ❌ booking_packages table doesn't exist!");
      } else {
        print("   Columns in booking_packages:");
        for (var column in tableInfo) {
          print("   - ${column['name']} (${column['type']})");
        }
      }

      // Check all data in booking_packages
      print("\n4. Checking ALL data in booking_packages...");
      final allData = await db.rawQuery("SELECT * FROM booking_packages;");
      print("   Total rows in booking_packages: ${allData.length}");
      for (var row in allData) {
        print("   Row: $row");
      }

      // Specifically check for booking ID 6
      print("\n5. Specifically checking for booking_id = 6...");
      final rowsForBooking6 = await db
          .rawQuery("SELECT * FROM booking_packages WHERE booking_id = 6;");
      print("   Rows for booking 6: ${rowsForBooking6.length}");
      for (var row in rowsForBooking6) {
        print("   Row: $row");
      }
    } catch (e) {
      print("Error in direct SQL test: $e");
    }

    print("=" * 60 + "\n");
  }

  void _openPackageSelectionDialog() async {
    // naviagte to FTSelect page
    final selectedPackages = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FTSelect(),
      ),
    );

    if (selectedPackages != null && selectedPackages is List) {
      for (var pkg in selectedPackages) {
        // Avoid duplicates in the cart
        final exists = cart.any(
            (c) => c['foodTruck'] == pkg['ft'] && c['package'] == pkg['pax']);
        if (!exists) {
          final packageData = {
            'foodTruck': pkg['ft'],
            'package': pkg['pax'],
            'price': pkg['prois'],
            'quantity': 1,
          };
          _addPackageToCart(packageData);
        }
      }
    }
  }

  void _addPackageToCart(Map<String, dynamic> package) async {
    final bookingId = widget.booking['bookid'];

    print("=== DEBUG: Adding package to cart:");
    print("  Booking ID: $bookingId");
    print("  Package: $package");

    try {
      // First check if package already exists
      final existingPackages =
          await DatabaseHelper.instance.getBookingPackages(bookingId);
      final exists = existingPackages.any((p) =>
          p['food_truck'] == package['foodTruck'] &&
          p['package_name'] == package['package']);

      if (exists) {
        // Update quantity if exists
        await DatabaseHelper.instance.updateBookingPackage(
          bookingId,
          package['foodTruck'],
          package['package'],
          package['quantity'],
        );
        print("  Package exists, updated quantity");
      } else {
        // INSERT NEW PACKAGE using addBookingPackage
        await DatabaseHelper.instance.addBookingPackage({
          'booking_id': bookingId,
          'food_truck': package['foodTruck'],
          'package_name': package['package'],
          'price': package['price'],
          'quantity': package['quantity'],
        });
        print("  Package inserted as new row");
      }

      // Refresh cart
      await _loadBookingPackages();
    } catch (e) {
      print("=== DEBUG: Error adding package: $e");
    }
  }

  Future<void> _loadBookingPackages() async {
    final bookingId = widget.booking['bookid'];

    print("=" * 50);
    print("=== DEBUG: Loading packages for booking ID: $bookingId ===");
    print("=== DEBUG: Booking details:");
    print("  - Book ID: ${widget.booking['bookid']}");
    print("  - Book Date: ${widget.booking['book_date']}");
    print("  - Event Date: ${widget.booking['eventdate']}");
    print("  - Food Type: ${widget.booking['foodtrucktype']}");
    print("=" * 50);

    try {
      final packages =
          await DatabaseHelper.instance.getBookingPackages(bookingId);

      print("=== DEBUG: Raw packages from database:");
      if (packages.isEmpty) {
        print("  EMPTY LIST []");
      } else {
        for (int i = 0; i < packages.length; i++) {
          print("  Package $i: ${packages[i]}");
          print("    - Type: ${packages[i].runtimeType}");
          print("    - Keys: ${packages[i].keys.toList()}");
        }
      }
      print("=== DEBUG: Total packages found: ${packages.length}");
      print("=" * 50);

      if (packages.isNotEmpty) {
        print("=== DEBUG: Converting packages to cart format...");
        final newCart = <Map<String, dynamic>>[];

        for (final pkg in packages) {
          print("  Processing package: $pkg");

          // Try different possible key names
          final foodTruck = pkg['food_truck'] ??
              pkg['foodtruck'] ??
              pkg['foodTruck'] ??
              pkg['ft'] ??
              'Unknown';

          final packageName =
              pkg['package_name'] ?? pkg['package'] ?? pkg['pax'] ?? 'Unknown';

          final price =
              pkg['price']?.toDouble() ?? pkg['prois']?.toDouble() ?? 0.0;

          final quantity = pkg['quantity']?.toInt() ?? pkg['qty']?.toInt() ?? 1;

          final cartItem = {
            'foodTruck': foodTruck,
            'package': packageName,
            'price': price,
            'quantity': quantity,
          };

          print("  Converted to: $cartItem");
          newCart.add(cartItem);
        }

        print("=== DEBUG: Setting cart with ${newCart.length} items");
        setState(() {
          cart = newCart;
        });

        print("=== DEBUG: Cart after loading:");
        for (int i = 0; i < cart.length; i++) {
          print("  Cart item $i: ${cart[i]}");
        }
      } else {
        print("=== DEBUG: No packages found. Setting empty cart.");
        setState(() {
          cart = [];
        });
      }
    } catch (e) {
      print("=== DEBUG: ERROR loading packages: $e");
      print("=== DEBUG: Stack trace: ${e.toString()}");
      setState(() {
        cart = [];
      });
    }

    print("=" * 50);
    print("=== DEBUG: loadBookingPackages() completed ===");
    print("=" * 50);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay(hour: 13, minute: 0))
        : (_endTime ?? TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  String get _formattedEventTime {
    final startStr = _startTime?.format(context) ?? "13:00";
    final endStr = _endTime?.format(context) ?? "18:00";
    return "$startStr - $endStr";
  }

  Future<void> _updateBooking() async {
    if (_formKey.currentState!.saveAndValidate()) {
      final values = _formKey.currentState!.value;
      final updatedBooking = {
        'book_date': DateFormat('yyyy-MM-dd').format(values['booking_date']),
        'booktime': DateFormat('HH:mm:ss').format(values['booking_date']),
        'eventdate': values['event_date_range']?.start.toIso8601String(),
        'eventtime': _formattedEventTime,
        'foodtrucktype': values['food_sell_types'],
        'numberofdays': widget.booking['numberofdays'],
      };

      await DatabaseHelper.instance.updateBooking(
        widget.booking['bookid'],
        updatedBooking,
      );

      // FIRST, clear existing packages for this booking
      await _clearAllPackagesForBooking();

      // THEN, insert all current cart items
      for (var item in cart) {
        await DatabaseHelper.instance.addBookingPackage({
          'booking_id': widget.booking['bookid'],
          'food_truck': item['foodTruck'],
          'package_name': item['package'],
          'price': item['price'],
          'quantity': item['quantity'],
        });
      }

      _showSnackBar(message: 'Booking updated successfully!', isError: false);
      widget.onUpdate();
      Navigator.pop(context);
    }
  }

  Future<void> _clearAllPackagesForBooking() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'booking_packages',
      where: 'booking_id = ?',
      whereArgs: [widget.booking['bookid']],
    );
  }

  void _showSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateQuantity(int index, bool increase) async {
    final bookingId = widget.booking['bookid'];
    final package = cart[index];

    if (increase) {
      setState(() {
        cart[index]['quantity']++;
      });
      // Use updateBookingPackage with price
      await DatabaseHelper.instance.updateBookingPackage(
        bookingId,
        package['foodTruck'],
        package['package'],
        package['quantity'],
        package['price'], // Pass price too
      );
    } else {
      if (package['quantity'] > 1) {
        setState(() {
          cart[index]['quantity']--;
        });
        await DatabaseHelper.instance.updateBookingPackage(
          bookingId,
          package['foodTruck'],
          package['package'],
          package['quantity'],
          package['price'],
        );
      } else {
        await DatabaseHelper.instance.deleteBookingPackage(
          bookingId,
          package['foodTruck'],
          package['package'],
        );
        setState(() {
          cart.removeAt(index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Booking',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(),
            SizedBox(height: 24),
            _buildCartSection(),
            SizedBox(height: 32),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  // Form Section
  Widget _buildFormSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'booking_date': DateTime.parse(widget.booking['book_date']),
            'event_date_range': DateTimeRange(
              start: DateTime.parse(widget.booking['eventdate']),
              end: DateTime.parse(widget.booking['eventdate'])
                  .add(Duration(days: widget.booking['numberofdays'])),
            ),
            'food_sell_types': widget.booking['foodtrucktype'],
          },
          child: Column(
            children: [
              _buildDateTimePicker(),
              SizedBox(height: 16),
              _buildDateRangePicker(),
              SizedBox(height: 16),
              _buildTimeInput(),
              SizedBox(height: 16),
              _buildDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return FormBuilderDateTimePicker(
      name: 'booking_date',
      decoration: InputDecoration(
        labelText: 'Booking Date',
        prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      firstDate: DateTime.now(),
      format: DateFormat('dd/MM/yyyy hh:mm aaa'),
      validator: FormBuilderValidators.required(
          errorText: 'Please select a booking date'),
    );
  }

  Widget _buildDateRangePicker() {
    return FormBuilderDateRangePicker(
      name: 'event_date_range',
      decoration: InputDecoration(
        labelText: 'Event Start & End Date',
        prefixIcon: Icon(Icons.date_range, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      format: DateFormat('dd/MM/yyyy'),
      validator: FormBuilderValidators.required(
          errorText: 'Please select event dates'),
    );
  }

  Widget _buildTimeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Time',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pickTime(isStart: true),
                child: Text(_startTime != null
                    ? _startTime!.format(context)
                    : "Start Time"),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pickTime(isStart: false),
                child: Text(
                    _endTime != null ? _endTime!.format(context) : "End Time"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return FormBuilderDropdown(
      name: 'food_sell_types',
      items: _dropdownItems,
      decoration: InputDecoration(
        labelText: 'Select an Option',
        prefixIcon: Icon(Icons.fastfood, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: FormBuilderValidators.required(
          errorText: 'Please select a food type'),
    );
  }

  Widget _buildCartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Packages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openPackageSelectionDialog,
              icon: Icon(Icons.add, size: 20),
              label: Text('Add Package'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
// In your _buildCartSection() method, add a debug button:
        if (cart.isEmpty)
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Text(
                    'No packages selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          )
        else
          Column(
            children: [
              ...cart.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildCartItem(item, index);
              }),
              SizedBox(height: 16),
              _buildTotalPrice(),
            ],
          ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(item['foodTruck'],
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['package'], style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 4),
            Text('RM${item['price'].toStringAsFixed(2)} each',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 18),
                color: Colors.red[600],
                onPressed: () => _updateQuantity(index, false),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item['quantity'].toString(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 18),
                color: Colors.green[600],
                onPressed: () => _updateQuantity(index, true),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPrice() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              )),
          Text('RM${_totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.blue[800],
              )),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Update Booking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
