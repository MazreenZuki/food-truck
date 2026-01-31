
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../db/database_helper.dart';
import '../../User/userProv.dart';
import '../../User/PaymentPage.dart';

import 'UserInfo.dart';
import 'EventInfoReq.dart';
import '../FT_Conf/FTSelect.dart';
import 'BkChkOut.dart';
import 'RateIt.dart';
import 'FormaDat/_FormaPDat.dart';
import 'FormaDat/_FTPDat.dart';

class Forma extends StatefulWidget {
  const Forma({super.key});

  @override
  FormaState createState() => FormaState();
}

class FormaState extends State<Forma> {
  int cstep = 0;

  final GlobalKey<UserInfoState> UserInfoKey = GlobalKey<UserInfoState>();
  final GlobalKey<EventInfoReqState> EventInfoReqKey = GlobalKey<EventInfoReqState>();
  final GlobalKey<FTSelectState> FoodTruckSelectKey = GlobalKey<FTSelectState>();

  void prvstep() {
    if (cstep > 0) {
      setState(() => cstep -= 1);
    }
  }

  void nxtstep() {
    bool valid = false;

    if (cstep == 0) {
      valid = UserInfoKey.currentState?.valForm(context) ?? false;
    } else if (cstep == 1) {
      valid = EventInfoReqKey.currentState?.valForm(context) ?? false;
    } else if (cstep == 2) {
      valid = FoodTruckSelectKey.currentState?.fillBook() ?? false;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Please add at least one Food Truck package first."),
          ),
        );
      }
    } else if (cstep == 3) {
      valid = true;
    } else {
      valid = false;
    }

    if (valid && cstep < 4) {
      setState(() => cstep += 1);
    }
  }

  Future<void> confirmCheckout() async {
    final formaProvider = Provider.of<FormaPDat>(context, listen: false);
    final ftpProvider = Provider.of<FTPDat>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final userId = userProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!ftpProvider.hasPax()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one package!'), backgroundColor: Colors.red),
      );
      return;
    }

    final bookingData = {
      'userid': userId,
      'book_date': formaProvider.booking_date != null
          ? DateFormat('yyyy-MM-dd').format(formaProvider.booking_date!)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'booktime': formaProvider.booking_date != null
          ? DateFormat('HH:mm:ss').format(formaProvider.booking_date!)
          : DateFormat('HH:mm:ss').format(DateTime.now()),
      'eventdate': formaProvider.event_date_range?.start.toIso8601String() ?? DateTime.now().toIso8601String(),
      'eventtime': formaProvider.event_start_time != null && formaProvider.event_end_time != null
          ? '${formaProvider.event_start_time!.format(context)} - ${formaProvider.event_end_time!.format(context)}'
          : '09:00 - 17:00',
      'foodtrucktype': formaProvider.food_sell_types ?? 'Not Provided',
      'numberofdays': formaProvider.event_date_range != null
          ? formaProvider.event_date_range!.end.difference(formaProvider.event_date_range!.start).inDays + 1
          : 1,
      'price': ftpProvider.totProis,
    };

    final selectedPackages = ftpProvider.selPax.map((pack) {
      return {
        'foodTruck': pack['ft'] ?? 'Unknown',
        'package': pack['paxName'] ?? pack['name'] ?? 'Unknown Package',
        'price': pack['prois'] ?? 0.0,
        'quantity': 1,
      };
    }).toList();

    final paymentSuccess = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          bookingData: bookingData,
          selectedPackages: selectedPackages,
          totalAmount: ftpProvider.totProis,
        ),
      ),
    );

    if (paymentSuccess == true) {
      await _saveBookingAfterPayment(bookingData);
    }
  }

  Future<void> _saveBookingAfterPayment(Map<String, dynamic> bookingData) async {
    try {
      int result = await DatabaseHelper.instance.addBooking(bookingData);

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking saved successfully!'), backgroundColor: Colors.green),
        );
        setState(() {
          cstep = 4;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save booking.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error saving booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget gBckBtn() => ElevatedButton.icon(
        onPressed: prvstep,
        icon: Icon(Icons.arrow_back, color: Colors.white),
        label: Text('Back', style: TextStyle(color: Colors.white, fontSize: 16)),
      );

  Widget gNxtBtn() => ElevatedButton.icon(
        onPressed: nxtstep,
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          cstep == 1 ? 'Proceed Booking' : cstep == 2 ? 'Continue Checkout' : 'Next',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );

  Widget gChckOutBtn() => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: 16),
          child: ElevatedButton(
            onPressed: confirmCheckout,
            child: const Text('Proceed to Payment', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            EasyStepper(
              activeStep: cstep,
              steps: const [
                EasyStep(title: 'User Info', icon: Icon(Icons.person_2)),
                EasyStep(title: 'Event & Requests', icon: Icon(Icons.event)),
                EasyStep(title: 'Food Truck', icon: Icon(Icons.dining)),
                EasyStep(title: 'Checkout', icon: Icon(Icons.payment)),
                EasyStep(title: 'Rating', icon: Icon(Icons.rate_review)),
              ],
              onStepReached: (idx) => setState(() => cstep = idx),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: IndexedStack(
                  index: cstep,
                  children: [
                    UserInfo(k: UserInfoKey),
                    EventInfoReq(k: EventInfoReqKey),
                    FTSelect(k: FoodTruckSelectKey),
                    BkChkOut(),
                    ReviewPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
