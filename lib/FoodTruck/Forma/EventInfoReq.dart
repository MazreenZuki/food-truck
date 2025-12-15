import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'FormaDat/_FormaPDat.dart';

class EventInfoReq extends StatefulWidget {
  const EventInfoReq({Key? k}) : super(key: k);

  @override
  EventInfoReqState createState() => EventInfoReqState();
}

class EventInfoReqState extends State<EventInfoReq> {
  final _fKey = GlobalKey<FormBuilderState>();
  final List<DropdownMenuItem<String>> _ddItm = [
    DropdownMenuItem(value: 'Buffet', child: Text('Buffet')),
    DropdownMenuItem(value: 'Food Stalls', child: Text('Food Stalls')),
    DropdownMenuItem(value: 'Takeaway', child: Text('Takeaway')),
  ];

  // Custom validator for event date range
  String? _validateEventDates(DateTimeRange? dateRange) {
    if (dateRange == null) return 'Please select event dates';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(
        dateRange.start.year, dateRange.start.month, dateRange.start.day);

    // Rule 1: Event must be at least 1 day from today
    final daysUntilEvent = eventStart.difference(today).inDays;
    if (daysUntilEvent < 1) {
      return 'Event must be at least 1 day from today';
    }

    // Rule 2: Event can't be too far in the future (optional)
    if (daysUntilEvent > 365) {
      return 'Event cannot be more than 1 year in advance';
    }

    // Rule 3: Event duration (end - start days)
    final eventDuration = dateRange.end.difference(dateRange.start).inDays + 1;
    if (eventDuration > 30) {
      return 'Event cannot be longer than 30 days';
    }

    return null;
  }

  // Custom validator for booking date vs event date
  String? _validateBookingDate(
      DateTime? bookingDate, DateTimeRange? eventRange) {
    if (bookingDate == null || eventRange == null) return null;

    final bookingDay =
        DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
    final eventStartDay = DateTime(
        eventRange.start.year, eventRange.start.month, eventRange.start.day);

    // Rule: Booking must be at least 3 days before event start
    final daysBetween = eventStartDay.difference(bookingDay).inDays;
    if (daysBetween < 3) {
      return 'Booking must be made at least 3 days before event';
    }

    return null;
  }

  // Custom validator for event times
  String? _validateEventTimes(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) return null;

    // Rule 1: End time must be after start time
    if (endTime.isBefore(startTime) || endTime == startTime) {
      return 'End time must be after start time';
    }

    // Rule 2: Minimum event duration (e.g., at least 2 hours)
    final duration = endTime.difference(startTime);
    if (duration.inHours < 2) {
      return 'Event must be at least 2 hours long';
    }

    // Rule 3: Maximum event duration (e.g., max 12 hours)
    if (duration.inHours > 12) {
      return 'Event cannot be longer than 12 hours';
    }

    // Rule 4: Reasonable hours (e.g., between 8 AM and 10 PM)
    final startHour = startTime.hour;
    final endHour = endTime.hour;
    if (startHour < 8 || endHour > 22) {
      return 'Events can only be between 8:00 AM and 10:00 PM';
    }

    return null;
  }

  bool valForm(BuildContext context) {
    if (_fKey.currentState?.saveAndValidate() ?? false) {
      final dat = _fKey.currentState?.value;

      // Additional cross-field validation
      final bookingDate = dat?['booking_date'];
      final eventRange = dat?['event_date_range'];
      final startTime = dat?['event_start_time'];
      final endTime = dat?['event_end_time'];

      // Check booking vs event date rule
      final bookingDateError = _validateBookingDate(bookingDate, eventRange);
      if (bookingDateError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingDateError),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Check event times rule
      final timesError = _validateEventTimes(startTime, endTime);
      if (timesError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(timesError),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // These two are being used to convert from DateTime to TimeOfDay
      TimeOfDay? startToim =
          startTime != null ? TimeOfDay.fromDateTime(startTime) : null;
      TimeOfDay? endToim =
          endTime != null ? TimeOfDay.fromDateTime(endTime) : null;

      // These are useful to "feed" the Provider for later use..
      Provider.of<FormaPDat>(context, listen: false).updtEventInfoReq(
        booking_date: bookingDate,
        event_date_range: eventRange,
        event_start_time: startToim,
        event_end_time: endToim,
        add_req: dat?['add_req'],
        food_sell_types: dat?['food_sell_types'],
      );
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Event Information'),
        ),
        body: FormBuilder(
          key: _fKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Box explaining rules
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Booking Guidelines',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Book at least 3 days before your event\n'
                          '• Events must be 2-12 hours long\n'
                          '• Operating hours: 8:00 AM - 10:00 PM\n'
                          '• Maximum event duration: 30 days',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Booking Date Picker
                  FormBuilderDateTimePicker(
                    name: 'booking_date',
                    decoration: InputDecoration(
                      labelText: 'Booking Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    firstDate: DateTime.now(),
                    format: DateFormat('dd/MM/yyyy hh:mm aaa'),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  SizedBox(height: 16),

                  // Event Date Range Picker
                  FormBuilderDateRangePicker(
                    name: 'event_date_range',
                    decoration: InputDecoration(
                      labelText: 'Event Start & End Date',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    firstDate: DateTime.now()
                        .add(Duration(days: 1)), // At least 1 day from today
                    lastDate: DateTime.now()
                        .add(Duration(days: 365)), // Max 1 year ahead
                    format: DateFormat('dd/MM/yyyy'),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      (value) => _validateEventDates(value),
                    ]),
                  ),
                  SizedBox(height: 16),

                  // Event Times
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'event_start_time',
                            inputType: InputType.time,
                            initialTime: TimeOfDay(hour: 10, minute: 0),
                            decoration: InputDecoration(
                              labelText: 'Start Time',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blueGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'event_end_time',
                            inputType: InputType.time,
                            initialTime: TimeOfDay(hour: 18, minute: 0),
                            decoration: InputDecoration(
                              labelText: 'End Time',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blueGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Time validation helper text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Events should be 2-12 hours long, between 8:00 AM - 10:00 PM',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Checkbox for Food Truck Decoration
                  FormBuilderCheckbox(
                    name: 'add_req',
                    title: Text(
                      'Food Truck Decoration',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Dropdown for Food Selling Types
                  FormBuilderDropdown(
                    name: 'food_sell_types',
                    items: _ddItm,
                    decoration: InputDecoration(
                      labelText: 'Select an Option',
                      prefixIcon: Icon(Icons.fastfood),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
}
