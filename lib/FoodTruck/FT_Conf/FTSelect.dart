import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../FT_Conf/FTDetail.dart';
import '../Forma/FormaDat/_FTPDat.dart';

class FTSelect extends StatefulWidget {
  final bool isEditMode;
  final VoidCallback? onUpdateComplete; // Callback for edit mode

  const FTSelect({
    Key? k,
    this.isEditMode = false,
    this.onUpdateComplete,
  }) : super(key: k);

  @override
  FTSelectState createState() => FTSelectState();
}

class FTSelectState extends State<FTSelect> {
  final List<Map<String, String>> foodCat = [
    {'name': 'Da Grill Mastas', 'img': 'assets/da_grill_mastas.png'},
    {'name': 'Spice Caravan', 'img': 'assets/spice_caravan.png'},
    {'name': 'Sweet Treat Wheels', 'img': 'assets/sweet_treat_wheels.png'},
    {'name': 'The Wok Working', 'img': 'assets/the_wok_working.png'},
  ];

  bool visSht = false;

  bool fillBook() {
    final ftPDat = Provider.of<FTPDat>(context, listen: false);
    return ftPDat.hasPax();
  }

  void _handleSelection(BuildContext context, String foodTruckName) async {
    final ftPDat = Provider.of<FTPDat>(context, listen: false);

    // In edit mode, allow re-selecting already selected trucks
    if (!widget.isEditMode && ftPDat.isFTSel(foodTruckName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$foodTruckName has already been selected.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FTDetail(
          cat: foodTruckName,
        ),
      ),
    );

    if (res != null) {
      print("DEBUG: Before addPax -> selPax: ${ftPDat.selPax}");
      ftPDat.addPax(res);
      print("DEBUG: After addPax -> selPax: ${ftPDat.selPax}");
    }
  }

  void _handleConfirm() {
    final ftPDat = Provider.of<FTPDat>(context, listen: false);

    if (widget.isEditMode) {
      // For edit mode, return the selected packages WITH quantities
      Navigator.pop(context, {
        'updated': true,
        'packages': ftPDat.selPax
            .map((pax) => {
                  'ft': pax['ft'],
                  'pax': pax['pax'],
                  'prois': pax['prois'],
                  'quantity':
                      pax['quantity'] ?? 1, // Make sure quantity is included
                })
            .toList(),
      });
    } else {
      // For booking mode, navigate to next screen
      Navigator.pushNamed(context, '/booking-confirmation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ftPDat = Provider.of<FTPDat>(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title:
            Text(widget.isEditMode ? "Update Food Truck" : "Select Food Truck"),
        leading: widget.isEditMode
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
        actions: [
          if (widget.isEditMode && ftPDat.hasPax())
            TextButton(
              onPressed: _handleConfirm,
              child: Text(
                "Update",
                style: TextStyle(color: Colors.white),
              ),
            ),
          InkWell(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () {
              setState(() {
                visSht = !visSht;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent,
                ),
                child: Icon(
                  visSht ? Icons.close : Icons.shopping_cart_checkout,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: foodCat.length,
            itemBuilder: (ctx, idx) {
              final cat = foodCat[idx];
              final isSel = ftPDat.isFTSel(cat['name']!);

              return GestureDetector(
                onTap: () => _handleSelection(context, cat['name']!),
                child: Card(
                  color: isSel ? Colors.purple.withOpacity(0.1) : Colors.white,
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.asset(
                        cat['img']!,
                        width: double.infinity,
                        height: 120.0,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 10.0,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cat['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (isSel && !widget.isEditMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (visSht)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              builder: (ctx, ctrl) {
                return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 12)
                    ],
                  ),
                  child: CustomScrollView(
                    controller: ctrl,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SliverAppBar(
                        title: Text(
                          widget.isEditMode
                              ? 'Updated Packages'
                              : 'Selected Packages',
                          style: TextStyle(color: Colors.black87, fontSize: 18),
                        ),
                        backgroundColor: Colors.white,
                        primary: false,
                        pinned: true,
                        centerTitle: false,
                        elevation: 0,
                        actions: [
                          if (ftPDat.hasPax())
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  ftPDat.clrPax();
                                });
                              },
                              child: const Text(
                                "Clear All",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final pck = ftPDat.selPax[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: Card(
                                child: ListTile(
                                  title: Text('${pck['ft']} (${pck['pax']})'),
                                  subtitle: Text(
                                    'RM${pck['prois'].toStringAsFixed(2)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.cancel,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        ftPDat.rmvPax(idx);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: ftPDat.selPax.length,
                        ),
                      ),
                      if (!fillBook())
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              widget.isEditMode
                                  ? 'No packages updated yet.'
                                  : 'No food truck packages selected yet.',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      if (widget.isEditMode && ftPDat.hasPax())
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: _handleConfirm,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: Colors.purpleAccent,
                              ),
                              child: Text(
                                'Confirm Update',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      // Add floating action button for booking mode
      floatingActionButton: !widget.isEditMode && ftPDat.hasPax()
          ? FloatingActionButton.extended(
              onPressed: _handleConfirm,
              backgroundColor: Colors.purpleAccent,
              icon: Icon(Icons.arrow_forward),
              label: Text('Continue'),
            )
          : null,
    );
  }
}
