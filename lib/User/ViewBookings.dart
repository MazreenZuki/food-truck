import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'EditBooking.dart';
import '../utils/date_calculations.dart';

class ViewBookingsPage extends StatefulWidget {
  final int userId;

  ViewBookingsPage({required this.userId});

  @override
  _ViewBookingsPageState createState() => _ViewBookingsPageState();
}

class _ViewBookingsPageState extends State<ViewBookingsPage> {
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await DatabaseHelper.instance.getBookings(widget.userId);
    setState(() {
      _bookings = bookings;
    });
  }

  Future<void> _deleteBooking(int bookId) async {
    final booking = await DatabaseHelper.instance.getBookingById(bookId);
    if (booking != null) {
      final eventDate = DateTime.parse(booking['eventdate']);

      // Check if booking can be deleted
      if (!BookingPolicy.canEditOrDelete(eventDate)) {
        _showCannotModifyDialog('delete');
        return;
      }

      bool confirm = await _showDeleteConfirmationDialog();
      if (confirm) {
        await DatabaseHelper.instance.deleteBooking(bookId);
        _loadBookings(); // Refresh the list
      }
    }
  }

  void _editBooking(Map<String, dynamic> booking) {
    final eventDate = DateTime.parse(booking['eventdate']);

    // Check if booking can be edited
    if (!BookingPolicy.canEditOrDelete(eventDate)) {
      _showCannotModifyDialog('edit');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookingPage(
          booking: booking,
          onUpdate: _loadBookings,
        ),
      ),
    );
  }

  void _showCannotModifyDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot $action booking'),
        content: Text(
          action == 'edit'
              ? 'This booking cannot be edited because the event is within 3 days. For urgent changes, please contact support.'
              : 'This booking cannot be deleted because the event is within 3 days. For cancellations, please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Booking'),
            content: Text('Are you sure you want to delete this booking?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Helper method to get status color
  Color _getStatusColor(DateTime eventDate) {
    final daysRemaining = BookingPolicy.daysRemaining(eventDate);
    if (daysRemaining > 3) return Colors.green;
    if (daysRemaining > 1) return Colors.orange;
    return Colors.red;
  }

  // Helper method to get status text
  String _getStatusText(DateTime eventDate) {
    final daysRemaining = BookingPolicy.daysRemaining(eventDate);
    final canEdit = BookingPolicy.canEditOrDelete(eventDate);

    if (!canEdit) return 'Locked (${daysRemaining}d)';
    if (daysRemaining > 7) return 'Editable';
    if (daysRemaining > 3) return 'Editable (${daysRemaining}d)';
    return 'Almost locked (${daysRemaining}d)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue[700],
        elevation: 1,
      ),
      body: _bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Create your first food truck booking!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                final eventDate = DateTime.parse(booking['eventdate']);

                print('Booking ${booking['bookid']}:');
                print('  Event Date: $eventDate');
                print(
                    '  Days Remaining: ${BookingPolicy.daysRemaining(eventDate)}');
                print(
                    '  Can Edit: ${BookingPolicy.canEditOrDelete(eventDate)}');

                final canEdit = BookingPolicy.canEditOrDelete(eventDate);
                final statusColor = _getStatusColor(eventDate);
                final statusText = _getStatusText(eventDate);
                final daysRemaining = BookingPolicy.daysRemaining(eventDate);

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left icon section
                        Container(
                          width: 60,
                          height: 60,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.food_bank,
                            color: Colors.blue[700],
                            size: 30,
                          ),
                        ),

                        // Middle content section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and date
                              Text(
                                '${booking['foodtrucktype']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('EEE, MMM d, yyyy')
                                    .format(eventDate), // Shorter format
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),

                              // Event details
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${booking['eventtime']}',
                                      style: TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_view_day,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    '${booking['numberofdays']} day(s)',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),

                              // Status badge
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      canEdit ? Icons.edit : Icons.lock,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11, // Smaller font
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right section (price and buttons)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Price
                            Text(
                              'RM${NumberFormat('###0.00').format(booking['price'])}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 12),

                            // Debug info (remove this in production)
                            Text(
                              '$daysRemaining days',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
                            ),

                            // Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit Button
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: canEdit ? Colors.blue : Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: canEdit
                                      ? () => _editBooking(booking)
                                      : null,
                                  tooltip: canEdit
                                      ? 'Edit booking'
                                      : 'Cannot edit (within 3 days)',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                SizedBox(width: 8),
                                // Delete Button
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: canEdit ? Colors.red : Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: canEdit
                                      ? () => _deleteBooking(booking['bookid'])
                                      : null,
                                  tooltip: canEdit
                                      ? 'Delete booking'
                                      : 'Cannot delete (within 3 days)',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
