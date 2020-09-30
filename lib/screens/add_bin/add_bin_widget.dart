import 'dart:io';

import 'package:camera/camera.dart';
import 'package:citycollection/blocs/auth/auth_bloc.dart';
import 'package:citycollection/blocs/home_tab/home_tab_bloc.dart';
import 'package:citycollection/blocs/home_tab/home_tabs.dart';
import 'package:citycollection/blocs/redeem/redeem_bloc.dart';
import 'package:citycollection/blocs/tagged_bins/tagged_bins_bloc.dart';
import 'package:citycollection/blocs/take_picture/take_picture_bloc.dart';
import 'package:citycollection/configurations/city_colors.dart';
import 'package:citycollection/models/tagged_bin.dart';
import 'package:citycollection/networking/repositories/data_repository.dart';
import 'package:citycollection/screens/general/take_picture_screen.dart';
import 'package:citycollection/screens/me/see_tagged_bins_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

class TakePictureTab extends StatefulWidget {
  final ScrollController scrollController;

  const TakePictureTab({Key key, this.scrollController}) : super(key: key);
  @override
  _TakePictureTabState createState() => _TakePictureTabState();
}

class _TakePictureTabState extends State<TakePictureTab>
    with TickerProviderStateMixin {
  final Logger logger = Logger("TakePictureTabState");
  String _binName;
  File _binImage;
  TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  Widget _buildingStartingTab(context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Add a Bin.",
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
                "Want to add a bin to the map? Just follow the instructions below.",
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.subtitle1),
            SizedBox(
              height: 20,
            ),
            Text(
              "1. Take a picture of the bin.",
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              "2. Name the bin.",
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              "3. Someone from our team will review and approve the bin.",
              style: Theme.of(context).textTheme.bodyText1,
            ),
            SizedBox(
              height: 20.0,
            ),
            Align(
              alignment: Alignment.center,
              child: RaisedButton(
                child: Text("Start"),
                onPressed: () {
                  _tabController.animateTo(1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessTab(context) {
    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text("An error has occured saving this bin, try again"),
              SizedBox(height: 10),
              RaisedButton(
                child: Text("Go Home"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: CityColors.primary_teal),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "Thanks for your adding a bin!",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "Your bin is now under review.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "Someone from our team will check the bin before adding it to the map.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            SizedBox(
              height: 10.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton(
                  child: Text("See My Bins"),
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacementNamed(SeeTaggedBinsScreen.routeName);
                  },
                ),
                RaisedButton(
                  child: Text("Go Home"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30.0)),
          ),
          margin: const EdgeInsets.only(top: 70.0),
          child: BlocListener<TaggedBinsBloc, TaggedBinsState>(
            listener: (context, state) {
              if (state is UploadSucessTaggedBinState) {
                _tabController.animateTo(4);
              } else if (state is UploadFailedTaggedBinState) {
                setState(() {
                  _isError = true;
                });
                _tabController.animateTo(4);
              } else if (state is UploadingTaggedBinState) {
                _tabController.animateTo(3);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30.0)),
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: <Widget>[
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildingStartingTab(context),
                        TakePictureScreen(
                          icon: Icon(FontAwesomeIcons.trash,
                              color: Colors.white, size: 40),
                          message: "Take a picture of the bin.",
                          onImageTaken: (file) {
                            _tabController.animateTo(2);
                            setState(() {
                              _binImage = file;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Name the bin!",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  Text(
                                      "Make the bin your own and add a name to show on the map.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                    decoration:
                                        InputDecoration(hintText: "Bin name"),
                                    validator: (val) {
                                      if (val == "") {
                                        return "Enter a valid name.";
                                      }
                                    },
                                    onSaved: (val) {
                                      setState(() {
                                        _binName = val;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.center,
                                    child: RaisedButton(
                                      child: Text("Save"),
                                      onPressed: () {
                                        if (_formKey.currentState.validate()) {
                                          _formKey.currentState.save();
                                          TaggedBin bin = TaggedBin(
                                              userId: BlocProvider.of<AuthBloc>(
                                                      context)
                                                  .currentUser
                                                  .id,
                                              isNew: true,
                                              active: false,
                                              binName: _binName,
                                              disposalsMade: 0,
                                              locationLan: 7.004453,
                                              locationLon: 79.913834,
                                              reportStrikes: 0,
                                              taggedTime: DateTime.now(),
                                              pointsEarned: 0);
                                          BlocProvider.of<TaggedBinsBloc>(
                                                  context)
                                              .add(UploadTaggedBinEvent(
                                                  bin,
                                                  _binImage,
                                                  BlocProvider.of<AuthBloc>(
                                                          context)
                                                      .currentUser));
                                        }
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text("Uploading your bin...",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.subtitle1),
                            ],
                          ),
                        ),
                        _buildSuccessTab(context),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
