import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('foodtruck.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
<<<<<<< Updated upstream
      version: 1,
=======
      version: 3, // UPGRADED VERSION
>>>>>>> Stashed changes
      onCreate: _createDB,
    );
  }

//============================================================
//                  T   A   B   L   E   S
//============================================================

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        userid INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE truckbook (
        bookid INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER NOT NULL,
        book_date TEXT NOT NULL,
        booktime TEXT NOT NULL,
        eventdate TEXT NOT NULL,
        eventtime TEXT NOT NULL,
        foodtrucktype TEXT NOT NULL,
        numberofdays INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (userid) REFERENCES users (userid)
      )
    ''');

    await db.execute('''
      CREATE TABLE administrator (
        adminid INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
<<<<<<< Updated upstream
  }

//============================================================
//============================================================
=======

    // NEW: Food Truck Table
    await db.execute('''
      CREATE TABLE foodtrucks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE booking_packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        food_truck TEXT NOT NULL,
        package_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (booking_id) REFERENCES truckbook (bookid)
      )
      ''');
  }

  //============================================================
  //                  DATABASE UPGRADE HANDLER
  //============================================================
  Future<void> _upgradeDB(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE foodtrucks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          image TEXT
        )
      ''');
    }

    if (oldV < 3) {
      await db.execute('''
    CREATE TABLE booking_packages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      booking_id INTEGER NOT NULL,
      food_truck TEXT NOT NULL,
      package_name TEXT NOT NULL,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1
    )
  ''');
    }
  }
>>>>>>> Stashed changes


  // Function to register a new user
  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await instance.database;

    // Check if username already exists
    final existingUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user['username']],
    );

    if (existingUsers.isNotEmpty) {
      // Username already exists
      return -1; // Indicate failure
    }

    // Insert new user
    return await db.insert('users', user);
  }

  //============================================================

  // Function to login a user
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;

    // Query the database for matching username and password
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return result.first; // Return user data if login is successful
    } else {
      return null; // Login failed
    }
  }

  //============================================================

  // Function to add booking
  Future<int> addBooking(Map<String, dynamic> booking) async {
    final db = await instance.database;
    return await db.insert('truckbook', booking);
  }

  //============================================================

  // Get user profile by user ID
  Future<Map<String, dynamic>?> getUserInfo(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'userid = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  //============================================================

  // Update user profile
  Future<int> updateUserInfo(int userId, Map<String, dynamic> updatedValues) async {
    final db = await instance.database;
    return await db.update(
      'users',
      updatedValues,
      where: 'userid = ?',
      whereArgs: [userId],
    );
  }

  //============================================================

<<<<<<< Updated upstream
  // Get bookings for a user
=======
  Future<int> addBooking(Map<String, dynamic> booking) async {
    final db = await instance.database;
    return await db.insert('truckbook', booking);
  }

  // save booking packages
  Future<int> addBookingPackage(Map<String, dynamic> data) async {
    final db = await instance.database;
    try {
      int id = await db.insert(
        'booking_packages',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace, // avoid duplicates
      );
      print("DEBUG: Booking package inserted with id: $id");
      return id;
    } catch (e) {
      print("ERROR in addBookingPackage: $e");
      return 0;
    }
  }

>>>>>>> Stashed changes
  Future<List<Map<String, dynamic>>> getBookings(int userId) async {
    final db = await instance.database;
    return await db.query(
      'truckbook',
      where: 'userid = ?',
      whereArgs: [userId],
    );
  }

<<<<<<< Updated upstream
  //============================================================

  // Update booking
  Future<int> updateBooking(int bookingId, Map<String, dynamic> updatedBooking) async {
=======
  Future<Map<String, dynamic>?> getBookingById(int bookingId) async {
    final db = await instance.database;
    final result = await db.query(
      'truckbook',
      where: 'bookid = ?',
      whereArgs: [bookingId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getBookingPackages(int bookingId) async {
    final db = await instance.database;

    print("Fetching packages for booking ID: $bookingId"); // debug

    final result = await db.query(
      'booking_packages',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );

    print("Packages fetched from DB: $result"); // debug

    return result;
  }

  // get a specific package
  Future<Map<String, dynamic>?> getBookingPackage(
      int bookingId, String foodTruck, String packageName) async {
    final db = await instance.database;
    final result = await db.query(
      'booking_packages',
      where: 'booking_id = ? AND food_truck = ? AND package_name = ?',
      whereArgs: [bookingId, foodTruck, packageName],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

// Update the updateBookingPackage to be more robust
  Future<int> updateBookingPackage(
      int bookingId, String foodTruck, String packageName, int quantity,
      [double? price]) async {
    // Make price optional
    final db = await instance.database;

    final existing = await db.query(
      'booking_packages',
      where: 'booking_id = ? AND food_truck = ? AND package_name = ?',
      whereArgs: [bookingId, foodTruck, packageName],
    );

    if (existing.isNotEmpty) {
      // Update quantity
      return await db.update(
        'booking_packages',
        {'quantity': quantity},
        where: 'booking_id = ? AND food_truck = ? AND package_name = ?',
        whereArgs: [bookingId, foodTruck, packageName],
      );
    } else if (price != null) {
      // Insert new with all data
      return await db.insert('booking_packages', {
        'booking_id': bookingId,
        'food_truck': foodTruck,
        'package_name': packageName,
        'price': price,
        'quantity': quantity,
      });
    } else {
      print("ERROR: Cannot insert package without price");
      return 0;
    }
  }

  Future<int> deleteAllBookingPackages(int bookingId) async {
    final db = await instance.database;
    return await db.delete(
      'booking_packages',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<int> deleteBookingPackage(
      int bookingId, String foodTruck, String packageName) async {
    final db = await instance.database;
    return await db.delete(
      'booking_packages',
      where: 'booking_id = ? AND food_truck = ? AND package_name = ?',
      whereArgs: [bookingId, foodTruck, packageName],
    );
  }

  Future<int> updateBooking(
      int bookingId, Map<String, dynamic> updatedBooking) async {
>>>>>>> Stashed changes
    final db = await instance.database;
    return await db.update(
      'truckbook',
      updatedBooking,
      where: 'bookid = ?',
      whereArgs: [bookingId],
    );
  }

  //============================================================

  // Delete booking
  Future<int> deleteBooking(int bookingId) async {
    final db = await instance.database;
    return await db.delete(
      'truckbook',
      where: 'bookid = ?',
      whereArgs: [bookingId],
    );
  }

  //============================================================

  Future<List<Map<String, dynamic>>> getFoodTruckTypes() async {
    final db = await instance.database;

    return await db.query('foodtruck', columns: ['foodtrucktype']);
  }

  //============================================================

  // Insert predefined admin data
  Future<void> insertAdminData() async {
    final db = await instance.database;

    // Insert admin credentials (username and password)
    await db.insert(
      'administrator', { 'username': 'admin', 'password': 'admin123', },
      conflictAlgorithm: ConflictAlgorithm.replace, // In case the admin already exists
    );
  }

  //============================================================

  // Method to check admin login (for validation in the login function)
  Future<Map<String, dynamic>?> loginAdmin(String username, String password) async {
    final db = await instance.database;

    // Query to find the admin by username and password
    final List<Map<String, dynamic>> results = await db.query(
      'administrator',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  //============================================================

  // Fetch all registered users
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  //============================================================

  // Fetch all bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final db = await instance.database;
    return await db.query('truckbook');
  }

  //============================================================

  // Delete a booking by ID
  Future<void> adminDeleteBooking(int bookingId) async {
    final db = await instance.database;
    await db.delete(
      'truckbook',
      where: 'bookid = ?',
      whereArgs: [bookingId],
    );
  }

  //============================================================

  // Delete a user and their associated bookings
  Future<void> adminDeleteUser(int userId) async {
    final db = await instance.database;

    // Delete bookings first to maintain database integrity
    await db.delete(
      'truckbook',
      where: 'userid = ?',
      whereArgs: [userId],
    );

    // Then delete the user
    await db.delete(
      'users',
      where: 'userid = ?',
      whereArgs: [userId],
    );
  }

  //============================================================

  // Update user details
  Future<int> adminUpdateUser(int userId, Map<String, dynamic> updatedValues) async {
    final db = await instance.database;

    return await db.update(
      'users',
      updatedValues,
      where: 'userid = ?',
      whereArgs: [userId],
    );
  }


  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
