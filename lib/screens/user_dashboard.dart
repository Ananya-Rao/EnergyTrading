import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:land_registration/providers/LandRegisterModel.dart';
import 'package:land_registration/constant/loadingScreen.dart';
import 'package:land_registration/screens/ChooseLandMap.dart';
import 'package:land_registration/screens/viewRequestDetails.dart';
import 'package:land_registration/widget/land_container.dart';
import 'package:land_registration/widget/menu_item_tile.dart';
import 'package:mapbox_search/mapbox_search.dart';
import 'package:provider/provider.dart';
import '../providers/MetamaskProvider.dart';
import '../constant/constants.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:http/http.dart' as http;
import '../constant/utils.dart';

class UserDashBoard extends StatefulWidget {
  const UserDashBoard({Key? key}) : super(key: key);

  @override
  _UserDashBoardState createState() => _UserDashBoardState();
}

class _UserDashBoardState extends State<UserDashBoard> {
  var model, model2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int screen = 0;
  late List<dynamic> userInfo;
  bool isLoading = true, isUserVerified = false;
  bool isUpdated = true;
  List<List<dynamic>> LandGall = [];
  String name = "";

  final _formKey = GlobalKey<FormState>();
  late String  landAddress, landPrice, COname, allLatiLongi;
  late String energy = '0';
  List<List<dynamic>> landInfo = [];
  List<List<dynamic>> receivedRequestInfo = [];
  List<List<dynamic>> sentRequestInfo = [];
  List<dynamic> prices = [];
  List<Menu> menuItems = [
    Menu(title: 'Dashboard', icon: Icons.dashboard),
    Menu(title: 'Request Electricity', icon: Icons.add_chart),
   // Menu(title: 'My Requests', icon: Icons.landscape_rounded),
    // Menu(title: 'Land Gallery', icon: Icons.landscape_rounded),
    //Menu(title: 'My Received Request', icon: Icons.request_page_outlined),
    Menu(title: 'My Sent Requests', icon: Icons.request_page_outlined),
    Menu(title: 'Logout', icon: Icons.logout),
  ];
  Map<String, String> requestStatus = {
    '0': 'Pending',
    '1': 'Accepted',
    '2': 'Rejected',
    '3': 'Payment Done',
    '4': 'Completed'
  };

  List<MapBoxPlace> predictions = [];
  late PlacesSearch placesSearch;
  final FocusNode _focusNode = FocusNode();
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  TextEditingController addressController = TextEditingController();

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
        builder: (context) => Positioned(
              width: 540,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0.0, 40 + 5.0),
                child: Material(
                  elevation: 4.0,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: List.generate(
                        predictions.length,
                        (index) => ListTile(
                              title:
                                  Text(predictions[index].placeName.toString()),
                              onTap: () {
                                addressController.text =
                                    predictions[index].placeName.toString();

                                setState(() {});
                                _overlayEntry.remove();
                                _overlayEntry.dispose();
                              },
                            )),
                  ),
                ),
              ),
            ));
  }

  Future<void> autocomplete(value) async {
    List<MapBoxPlace>? res = await placesSearch.getPlaces(value);
    if (res != null) predictions = res;
    setState(() {});
    // print(res);
    // print(res![0].placeName);
    // print(res![0].geometry!.coordinates);
    // print(res![0]);
  }

  @override
  void initState() {
    placesSearch = PlacesSearch(
      apiKey: mapBoxApiKey,
      limit: 10,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context)!.insert(_overlayEntry);
      } else {
        _overlayEntry.remove();
      }
    });
    super.initState();
  }

  getLandInfo() async {
    setState(() {
      landInfo = [];
      isLoading = true;
    });
    List<dynamic> landList;
    if (connectedWithMetamask) {
      landList = await model2.myAllLands();
    } else {
      landList = await model.myAllLands();
    }

    List<List<dynamic>> info = [];
    List<dynamic> temp;
    for (int i = 0; i < landList.length; i++) {
      if (connectedWithMetamask) {
        temp = await model2.landInfo(landList[i]);
      } else {
        temp = await model.landInfo(landList[i]);
      }
      print(temp);
      landInfo.add(temp);
      setState(() {
        isLoading = false;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // getLandGallery() async {
  //   setState(() {
  //     isLoading = true;
  //     LandGall = [];
  //   });
  //   List<dynamic> landList;
  //   if (connectedWithMetamask) {
  //     landList = await model2.allLandList();
  //   } else {
  //     landList = await model.allLandList();
  //   }

  //   // List<List<dynamic>> allInfo = [];
  //   List<dynamic> temp;
  //   for (int i = 0; i < landList.length; i++) {
  //     if (connectedWithMetamask) {
  //       temp = await model2.landInfo(landList[i]);
  //     } else {
  //       temp = await model.landInfo(landList[i]);
  //     }
  //     LandGall.add(temp);
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  //   // screen = 3;
  //   isLoading = false;
  //   setState(() {});
  // }

  getMySentRequest() async {
    //SmartDialog.showLoading();
    sentRequestInfo = [];
    setState(() {
      isLoading = true;
    });
    await getEthToInr();
    List<dynamic> requestList;
    if (connectedWithMetamask) {
      requestList = await model2.mySentRequest();
      print(requestList);
    } else {
      requestList = await model.mySentRequest();
    }

    List<dynamic> temp;
    var pri;
    for (int i = 0; i < requestList.length; i++) {
      if (connectedWithMetamask) {
        print("came here amma");
        temp = await model2.requestInfo(requestList[i]);
        pri = await model2.landPrice(temp[3]);
      } else {
        temp = await model.requestInfo(requestList[i]);
        pri = await model.landPrice(temp[3]);
      }
      prices.add(pri);
      print(temp);
      sentRequestInfo.add(temp);
      print("this");
      print(sentRequestInfo);
      isLoading = false;

      // SmartDialog.dismiss();
      setState(() {});
    }

    // screen = 5;
    isLoading = false;

    // SmartDialog.dismiss();
    setState(() {});
  }

  getMyReceivedRequest() async {
    receivedRequestInfo = [];
    setState(() {
      isLoading = true;
    });
    List<dynamic> requestList;
    if (connectedWithMetamask) {
      print("came here");
      requestList = await model2.myReceivedRequest();
      print(requestList);
    } else {
      requestList = await model.myReceivedRequest();
    }

    List<dynamic> temp;
    for (int i = 0; i < requestList.length; i++) {
      if (connectedWithMetamask) {
        temp = await model2.requestInfo(requestList[i]);
      } else {
        temp = await model.requestInfo(requestList[i]);
      }
      receivedRequestInfo.add(temp);
      isLoading = false;
      setState(() {});
    }
    isLoading = false;
    //  screen = 4;
    setState(() {});
  }


  Future<void> getProfileInfo() async {
    // setState(() {
    //   isLoading = true;
    // });
    if (connectedWithMetamask) {
      userInfo = await model2.myProfileInfo();
    } else {
      userInfo = await model.myProfileInfo();
    }
    name = userInfo[1];
    setState(() {
      isLoading = false;
    });
  }

  String docuName = "";
  late PlatformFile documentFile;
  String cid = "", docUrl = "";
  bool isFilePicked = false;

  pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf'],
    );

    if (result != null) {
      isFilePicked = true;
      docuName = result.files.single.name;
      documentFile = result.files.first;
    }
    setState(() {});
  }

  Future<bool> uploadDocument() async {
    String url = "https://api.nft.storage/upload";
    var header = {"Authorization": "Bearer $nftStorageApiKey"};

    if (isFilePicked) {
      try {
        final response = await http.post(Uri.parse(url),
            headers: header, body: documentFile.bytes);
        var data = jsonDecode(response.body);
        //print(data);
        if (data['ok']) {
          cid = data["value"]["cid"];
          docUrl = "https://" + cid + ".ipfs.dweb.link";

          return true;
        }
      } catch (e) {
        print(e);
        showToast("Something went wrong,while document uploading",
            context: context, backgroundColor: Colors.red);
      }
    } else {
      showToast("Choose Document",
          context: context, backgroundColor: Colors.red);
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    model = Provider.of<LandRegisterModel>(context);
    model2 = Provider.of<MetaMaskProvider>(context);
    if (isUpdated) {
      getProfileInfo();
      isUpdated = false;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF272D34),
        leading: isDesktop
            ? Container()
            : GestureDetector(
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.menu,
                    color: Colors.white,
                  ), //AnimatedIcon(icon: AnimatedIcons.menu_arrow,progress: _animationController,),
                ),
                onTap: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),
        title: const Text('Charging Station Owner Dashboard'),
      ),
      drawer: drawer2(),
      drawerScrimColor: Colors.transparent,
      body: Row(
        children: [
          isDesktop ? drawer2() : Container(),
          if (screen == 0)
            userProfile()
          else if (screen == 1)
            addLand()
          else if (screen == 2)
            myLands()
          // else if (screen == 3)
          //   landGallery()
          else if (screen == 3)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: receivedRequest(),
              ),
            )
          else if (screen == 4)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: sentRequest(),
              ),
            )
        ],
      ),
    );
  }

  Widget sentRequest() {
    return ListView.builder(
      itemCount: sentRequestInfo == null ? 1 : sentRequestInfo.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            children: [
              const Divider(
                height: 15,
              ),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                    child: Text(
                      'Land Id',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                      child: Center(
                        child: Text('Owner Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      flex: 5),
                  Expanded(
                    child: Center(
                      child: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 3,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Price(in ₹)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Make Payment',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  )
                ],
              ),
              const Divider(
                height: 15,
              )
            ],
          );
        }
        index -= 1;
        List<dynamic> data = sentRequestInfo[index];
        print(data);
        return Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text((index + 1).toString()),
                flex: 1,
              ),
              Expanded(child: Center(child: Text(data[3].toString())), flex: 1),
              Expanded(
                  child: Center(
                    child: Text(data[1].toString()),
                  ),
                  flex: 5),
              Expanded(
                  child: Center(
                    child: Text(requestStatus[data[4].toString()].toString()),
                  ),
                  flex: 3),
              Expanded(
                  child: Center(
                    child: Text(prices[index].toString()),
                  ),
                  flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.green),
                        onPressed: data[4].toString() != '1'
                            ? null
                            : () async {
                                _paymentDialog(
                                    data[2],//cso
                                    data[1],//prosumer
                                    prices[index].toString(),
                                    double.parse(prices[index].toString()) /
                                        ethToInr,
                                    ethToInr,
                                    data[0]);
                                // SmartDialog.showLoading();
                                // try {
                                //   //await model.rejectRequest(data[0]);
                                //   //await getMyReceivedRequest();
                                // } catch (e) {
                                //   print(e);
                                // }
                                //
                                // //await Future.delayed(Duration(seconds: 2));
                                // SmartDialog.dismiss();
                              },
                        child: const Text('Make Payment')),
                  ),
                  flex: 2),
            ],
          ),
        );
      },
    );
  }

  Widget receivedRequest() {
    return ListView.builder(
      itemCount:
          receivedRequestInfo == null ? 1 : receivedRequestInfo.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            children: [
              const Divider(
                height: 15,
              ),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                    child: Text(
                      'Land Id',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    flex: 1,
                  ),
                  Expanded(
                      child: Center(
                        child: Text('Buyer Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      flex: 5),
                  Expanded(
                    child: Center(
                      child: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 3,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Payment Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Reject',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    flex: 2,
                  )
                ],
              ),
              const Divider(
                height: 15,
              )
            ],
          );
        }
        index -= 1;
        List<dynamic> data = receivedRequestInfo[index];
        return Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text((index + 1).toString()),
                flex: 1,
              ),
              Expanded(child: Center(child: Text(data[3].toString())), flex: 1),
              Expanded(
                  child: Center(
                    child: Text(data[2].toString()),
                  ),
                  flex: 5),
              Expanded(
                  child: Center(
                    child: Text(requestStatus[data[4].toString()].toString()),
                  ),
                  flex: 3),
              Expanded(child: Center(child: Text(data[5].toString())), flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(primary: Colors.redAccent),
                        onPressed: data[4].toString() != '0'
                            ? null
                            : () async {
                                SmartDialog.showLoading();
                                try {
                                  if (connectedWithMetamask) {
                                    await model2.rejectRequest(data[0]);
                                  } else {
                                    await model.rejectRequest(data[0]);
                                  }
                                  await getMyReceivedRequest();
                                } catch (e) {
                                  print(e);
                                }

                                //await Future.delayed(Duration(seconds: 2));
                                SmartDialog.dismiss();
                              },
                        child: const Text('Reject')),
                  ),
                  flex: 2),
              Expanded(
                  child: Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.greenAccent),
                        onPressed: data[4].toString() != '0'
                            ? null
                            : () async {
                                SmartDialog.showLoading();
                                try {
                                  if (connectedWithMetamask) {
                                    await model2.acceptRequest(data[0]);
                                  } else {
                                    await model.acceptRequest(data[0]);
                                  }
                                  await getMyReceivedRequest();
                                } catch (e) {
                                  print(e);
                                }

                                //await Future.delayed(Duration(seconds: 2));
                                SmartDialog.dismiss();
                              },
                        child: const Text('Accept')),
                  ),
                  flex: 2),
            ],
          ),
        );
      },
    );
  }

  
  
  Widget myLands() {
    if (isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (landInfo.isEmpty) {
      return const Expanded(
          child: Center(
              child: Text(
        'No Lands Added yet',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      )));
    }
    return Expanded(
      child: Center(
        child: SizedBox(
          width: isDesktop ? 900 : width,
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            scrollDirection: Axis.vertical,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: 440,
                crossAxisCount: isDesktop ? 2 : 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20),
            itemCount: landInfo.length,
            itemBuilder: (context, index) {
              return landWid(
                  landInfo[index][8],
                  landInfo[index][1].toString(),
                  landInfo[index][2].toString(),
                  landInfo[index][3].toString(),
                  landInfo[index][6],
                  () =>
                      confirmDialog('Are you sure to make it on sell?', context,
                          () async {
                        SmartDialog.showLoading();
                        if (connectedWithMetamask) {
                          await model2.makeForSell(landInfo[index][0]);
                        } else {
                          await model.makeForSell(landInfo[index][0]);
                        }
                        Navigator.pop(context);
                        await getLandInfo();
                        SmartDialog.dismiss();
                      }));
            },
          ),
        ),
      ),
    );
  }

  Widget addLand() {
    return Center(
      widthFactor: isDesktop ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            //color: Color(0xFFBb3b3cc),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all()),
        width: width,
        child: Form(
          key: _formKey,
          child: Column(
            // scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    COname = val;
                  },
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  //obscureText: true,
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                    hintText: 'Please enter your name',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    energy = val;
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  decoration: const InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                    labelText: 'Electricity required (in KW)',
                    hintText: 'Enter the amount of Electricity required',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the charging station Address';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    controller: addressController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        autocomplete(value);
                        _overlayEntry.remove();
                        _overlayEntry = _createOverlayEntry();
                        Overlay.of(context)!.insert(_overlayEntry);
                      } else {
                        if (predictions.isNotEmpty && mounted) {
                          setState(() {
                            predictions = [];
                          });
                        }
                      }
                    },
                    focusNode: _focusNode,
                    //obscureText: true,
                    decoration: const InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(),
                      labelText: 'Address',
                      hintText: 'Enter Charging Station Address',
                    ),
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(10),
              //   child: TextFormField(
              //     validator: (value) {
              //       if (value == null || value.isEmpty) {
              //         return 'Please enter Energy Price';
              //       }
              //       return null;
              //     },
              //     //maxLength: 12,
              //     style: const TextStyle(
              //       fontSize: 15,
              //     ),
              //     keyboardType: TextInputType.number,
              //     inputFormatters: <TextInputFormatter>[
              //       FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              //     ],
              //     onChanged: (val) {
              //       landPrice = val;
              //     },
              //     //obscureText: true,
              //     decoration: const InputDecoration(
              //       isDense: true, // Added this
              //       contentPadding: EdgeInsets.all(12),
              //       border: OutlineInputBorder(),
              //       labelText: 'Energy Price',
              //       hintText: 'Enter Energy Price',
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(10),
              //   child: TextFormField(
              //     validator: (value) {
              //       if (value == null || value.isEmpty) {
              //         return 'Please enter PID';
              //       }
              //       return null;
              //     },
              //     style: const TextStyle(
              //       fontSize: 15,
              //     ),
              //     //maxLength: 10,
              //     keyboardType: TextInputType.number,
              //     inputFormatters: <TextInputFormatter>[
              //       FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              //     ],
              //     onChanged: (val) {
              //       propertyID = val;
              //     },
              //     //obscureText: true,
              //     decoration: const InputDecoration(
              //       isDense: true, // Added this
              //       contentPadding: EdgeInsets.all(12),
              //       border: OutlineInputBorder(),
              //       labelText: 'PID',
              //       hintText: 'Enter Property ID',
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: MaterialButton(
                  color: Colors.grey,
                  onPressed: () async {
                    allLatiLongi = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const landOnMap()));
                    if (allLatiLongi.isEmpty || allLatiLongi == "") {
                      showToast("Please select area on map",
                          context: context, backgroundColor: Colors.red);
                    }
                    //print(res);
                  },
                  child: const Text('Draw Land on Map'),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(10),
              //   child: Row(
              //     children: [
              //       MaterialButton(
              //         color: Colors.grey,
              //         onPressed: pickDocument,
              //         child: const Text('Upload Document'),
              //       ),
              //       Text(docuName)
              //     ],
              //   ),
              // ),
              Center(
                child: Text(
                  "Price: ₹25 per KW. Total Price:"+ (int.parse(energy)*25).toString() + " per KW",
                  style: TextStyle(color: Colors.blue, height: 15),
                ),
              ),
              // Center(
              //   child: Text(
              //     "Price: ₹25"+ (int.parse(energy)*25).toString() + "per KW",
              //     style: TextStyle(color: Colors.blue, height: 15),
              //   ),
              // ),
              CustomButton(
                  'Place Request',
                  isLoading || !isUserVerified
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate() &&
                              allLatiLongi.isNotEmpty &&
                              allLatiLongi != "") {
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              // SmartDialog.showLoading(
                              //     msg: "Uploading Document");
                              bool isFileupload = true;
                              // SmartDialog.dismiss();
                              if (isFileupload) {
                                if (connectedWithMetamask) {
                                  await model2.addLand(
                                      energy,
                                      addressController.text,
                                      (int.parse(energy)*25).toString(),
                                      allLatiLongi,
                                      name);
                                } else {
                                  await model.addLand(
                                    energy,
                                    addressController.text,
                                    (int.parse(energy)*25).toString(),
                                    allLatiLongi,
                                    name,
                                  );
                                }
                                showToast("Request Sent Successfully",
                                    context: context,
                                    backgroundColor: Colors.green);
                                isFilePicked = false;
                              }
                            } catch (e) {
                              print(e);
                              showToast("Something Went Wrong",
                                  context: context,
                                  backgroundColor: Colors.red);
                            }

                            setState(() {
                              isLoading = false;
                            });
                          }

                          //model.makePaymentTestFun();
                        }),
              if (!isUserVerified)
                const Text('You are not verified',
                    style: TextStyle(color: Colors.redAccent)),
              isLoading ? spinkitLoader : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget userProfile() {
    if (isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    isUserVerified = userInfo[5];
    return Expanded(
      child: Center(
        child: Container(
          width: width,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              //color: Color(0xFFBb3b3cc),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all()),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              userInfo[5]
                  ? Row(
                      children: const [
                        Text(
                          'Verified',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Icon(
                          Icons.verified,
                          color: Colors.green,
                        )
                      ],
                    )
                  : const Text(
                      'Not Yet Verified',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
              CustomTextFiled(userInfo[0].toString(), 'Wallet Address'),
              CustomTextFiled(userInfo[1].toString(), 'Name'),
              CustomTextFiled(userInfo[2].toString(), 'Age'),
              CustomTextFiled(userInfo[3].toString(), 'City'),
              // CustomTextFiled(userInfo[4].toString(), 'Adhar Number'),
              // CustomTextFiled(userInfo[5].toString(), 'Pan'),
              // TextButton(
              //   onPressed: () {
              //     launchUrl(userInfo[6].toString());
              //   },
              //   child: const Text(
              //     '  View Document',
              //     style: TextStyle(color: Colors.blue),
              //   ),
              // ),
              CustomTextFiled(userInfo[4].toString(), 'Mail'),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawer2() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black26, spreadRadius: 2)
        ],
        color: Color(0xFF272D34),
      ),
      width: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 20,
          ),
          const Icon(
            Icons.person,
            size: 50,
          ),
          const SizedBox(
            width: 30,
          ),
          Text(name,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 80,
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, counter) {
                return const Divider(
                  height: 2,
                );
              },
              itemCount: menuItems.length,
              itemBuilder: (BuildContext context, int index) {
                return MenuItemTile(
                  title: menuItems[index].title,
                  icon: menuItems[index].icon,
                  isSelected: screen == index,
                  onTap: () {
                    if (index == 3) {
                      Navigator.pop(context);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const home_page()));
                      Navigator.of(context).pushNamed(
                        '/',
                      );
                    }
                    if (index == 0) getProfileInfo();
                    //if (index == 2) getLandInfo();
                    // if (index == 3) getLandGallery();
                    //if (index == 3) getMyReceivedRequest();
                    if (index == 2) getMySentRequest();
                    setState(() {
                      screen = index;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  _paymentDialog(buyerAdd, sellAdd, amountINR, total, ethval, reqID) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              backgroundColor: Colors.white,
              child: Container(
                margin: const EdgeInsets.all(10),
                height: 430.0,
                width: 320,
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'Confirm Payment',
                      style: TextStyle(fontSize: 30),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      buyerAdd.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Icon(
                      Icons.arrow_circle_down,
                      size: 30,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      sellAdd.toString(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      "Total Amount in ₹",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      amountINR,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      '1 ETH = ' + ethval.toString() + '₹',
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      "Total ETH:",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      total.toString(),
                      style: const TextStyle(fontSize: 30),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton3('Cancel', () {
                          Navigator.of(context).pop();
                        }, Colors.white),
                        CustomButton3('Confirm', () async {
                          SmartDialog.showLoading();
                          try {
                            if (connectedWithMetamask) {
                              await model2.makePayment(reqID, total);
                            } else {
                              await model.makePayment(reqID, total);
                            }
                            await getMySentRequest();
                            showToast("Payment Success",
                                context: context,
                                backgroundColor: Colors.green);
                          } catch (e) {
                            print(e);
                            showToast("Something Went Wrong",
                                context: context, backgroundColor: Colors.red);
                          }
                          SmartDialog.dismiss();
                          Navigator.of(context).pop();
                        }, Colors.blue)
                      ],
                    )
                  ],
                ),
              ));
        });
  }
}
