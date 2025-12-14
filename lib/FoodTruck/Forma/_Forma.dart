import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'UserInfo.dart';
import 'EventInfoReq.dart';
import '../FT_Conf/FTSelect.dart';
import 'BkChkOut.dart';
import 'RateIt.dart';

class Forma extends StatefulWidget {
  const Forma({super.key});

  @override
  FormaState createState() => FormaState();
}

class FormaState extends State<Forma> {
  int cstep = 0;

  final GlobalKey<UserInfoState> UserInfoKey = GlobalKey<UserInfoState>();
  final GlobalKey<EventInfoReqState> EventInfoReqKey =
      GlobalKey<EventInfoReqState>();
  final GlobalKey<FTSelectState> FoodTruckSelectKey =
      GlobalKey<FTSelectState>();

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
      // on checkout step, don't validate - just let BkChkOut handle it
      valid = false; // don't auto-advance from checkout
    } else {
      valid = false;
    }

    if (valid && cstep < 4) {
      setState(() => cstep += 1);
    }
  }

  Widget gBckBtn() => ElevatedButton.icon(
        onPressed: prvstep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white24,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.arrow_back, color: Colors.white),
        label: Text(
          'Back',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );

  Widget gNxtBtn() => ElevatedButton.icon(
        onPressed: nxtstep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          cstep == 1
              ? 'Proceed Booking'
              : cstep == 2
                  ? 'Continue Checkout'
                  : 'Next',
          style: TextStyle(color: Colors.white, fontSize: 16),
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
                    BkChkOut(
                      onBookingSaved: () {
                        // after booking is saved, go to rating
                        setState(() {
                          cstep = 4; // move to Rating step
                        });
                      },
                    ),
                    ReviewPage(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: cstep == 0
                    ? [
                        Container(),
                        gNxtBtn(),
                      ]
                    : cstep == 3
                        ? [
                            gBckBtn(),
                          ]
                        : cstep == 4
                            ? [
                                // Empty for Rating page
                              ]
                            : [
                                gBckBtn(),
                                gNxtBtn(),
                              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
