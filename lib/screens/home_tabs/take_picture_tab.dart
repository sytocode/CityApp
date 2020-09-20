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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

import 'me_tab.dart';

class TakePictureTab extends StatefulWidget {
  final ScrollController scrollController;

  const TakePictureTab({Key key, this.scrollController}) : super(key: key);
  @override
  _TakePictureTabState createState() => _TakePictureTabState();
}

class _TakePictureTabState extends State<TakePictureTab>
    with TickerProviderStateMixin {
  TakePictureBloc _bloc;
  bool _isCameraInitialized = false;
  String _cameraError;
  String _uploadingError;
  CameraController _cameraController;
  File _currentImageTaken;
  bool _isBinImageUploading = false;
  bool _isBinUploaded = false;
  final Logger logger = Logger("TakePictureTabState");
  final GlobalKey<FormState> _globalKey = GlobalKey();
  String _binName;

  @override
  void initState() {
    super.initState();
    _bloc = TakePictureBloc();
    _bloc.add(InitializeCameraEvent());
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.close();
  }

  void _initBinUpload(File image) async {
    String binName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            title: Text("Name your bin"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter a name for your bin.",
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                Form(
                  key: _globalKey,
                  child: TextFormField(
                    decoration: InputDecoration(labelText: "Bin Name"),
                    onSaved: (val) {
                      setState(() {
                        _binName = val;
                      });
                    },
                    validator: (val) {
                      if (val.length == 0) {
                        return "Enter a valid length";
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              RaisedButton(
                child: Text("Done"),
                onPressed: () {
                  if (_globalKey.currentState.validate()) {
                    _globalKey.currentState.save();
                    Navigator.of(context).pop(_binName);
                  }
                },
              )
            ],
          );
          //camera tab
        });
    if (binName != null) {
      TaggedBin bin = TaggedBin(
          userId: BlocProvider.of<AuthBloc>(context).currentUser.id,
          isNew: true,
          active: true,
          binName: binName,
          locationLan: 7.004453,
          locationLon: 79.913834,
          reportStrikes: 0,
          taggedTime: DateTime.now().millisecondsSinceEpoch,
          pointsEarned: 0);
      BlocProvider.of<TaggedBinsBloc>(context).add(UploadTaggedBinEvent(
          bin, image, BlocProvider.of<AuthBloc>(context).currentUser));
    }
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
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30.0)),
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: <Widget>[
              SliverFillRemaining(
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<TakePictureBloc, TakePictureState>(
                      cubit: _bloc,
                      listener: (context, TakePictureState state) {
                        if (state is CameraInitializeSuccessState) {
                          setState(() {
                            _cameraController = state.cameraController;
                          });
                        } else if (state is CameraInitializeFailedState) {
                          setState(() {
                            _cameraError = "Could not initialize camera";
                          });
                        } else if (state is CameraPictureTakenSuccessState) {
                          logger.info("Image Taken");
                          setState(() {
                            _currentImageTaken = state.image;
                          });
                          //_initBinUpload(state.image);
                        }
                      },
                    ),
                    BlocListener<TaggedBinsBloc, TaggedBinsState>(
                      listener: (context, TaggedBinsState state) {
                        if (state is UploadSucessTaggedBinState) {
                          setState(() {
                            _isBinImageUploading = false;
                            _isBinUploaded = true;
                          });
                        } else if (state is UploadFailedTaggedBinState) {
                          setState(() {
                            _isBinImageUploading = false;
                            _uploadingError =
                                "An error has occured, try again.";
                          });
                        } else if (state is UploadingTaggedBinState) {
                          setState(() {
                            _isBinImageUploading = true;
                          });
                        }
                      },
                    )
                  ],
                  child: _cameraController != null
                      ? Container(
                          color: Colors.blue,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: _cameraController.value.aspectRatio /
                                    deviceRatio,
                                child: AspectRatio(
                                  aspectRatio:
                                      _cameraController.value.aspectRatio,
                                  child: CameraPreview(_cameraController),
                                ),
                              ),
                              Center(
                                child: AnimatedSize(
                                  vsync: this,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.bounceOut,
                                  alignment: Alignment.center,
                                  child: _currentImageTaken != null
                                      ? Image.file(
                                          _currentImageTaken,
                                          frameBuilder: (context, child, frame,
                                              wasSyncholoaded) {
                                            return Container(
                                              key: GlobalKey(
                                                  debugLabel: "initialImage"),
                                              margin:
                                                  const EdgeInsets.all(30.0),
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              30.0))),
                                              child: ClipRRect(
                                                  child: child,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              30.0))),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.transparent,
                                          key: GlobalKey(
                                              debugLabel: "initialImage"),
                                          height: 30,
                                          width: 30,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  margin: const EdgeInsets.all(20.0),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30.0))),
                                    color: Colors.black38,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20.0, horizontal: 20.0),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          if (_isBinImageUploading) {
                                            return CircularProgressIndicator();
                                          } else if (_isBinUploaded) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text("Sent for review.",
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline6
                                                        .copyWith(
                                                            color:
                                                                Colors.white)),
                                                Text(
                                                    "Your bin will be live once our team\napproves it.",
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        .copyWith(
                                                            color:
                                                                Colors.white)),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                RaisedButton(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  20.0))),
                                                  child: Text(
                                                    "Done",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  color:
                                                      CityColors.primary_teal,
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          } else {
                                            return Center(
                                              child: AnimatedSize(
                                                vsync: this,
                                                duration:
                                                    Duration(milliseconds: 500),
                                                curve: Curves.bounceOut,
                                                alignment: Alignment.center,
                                                child: _currentImageTaken ==
                                                        null
                                                    ? Container(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          key: GlobalKey(
                                                              debugLabel:
                                                                  "columnTakePicture"),
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              "Tag a bin and put it on the map!",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            ),
                                                            Text(
                                                              "Firstly, take a picture of it.",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .subtitle2
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .white),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            ),
                                                            SizedBox(
                                                                height: 15),
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  _bloc.add(
                                                                      InitPictureTakeEvent());
                                                                },
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          10.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: CityColors
                                                                        .primary_teal,
                                                                  ),
                                                                  child: Icon(
                                                                      Icons
                                                                          .camera,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          40.0),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              "Continue?",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .white),
                                                            ),
                                                            SizedBox(
                                                                height: 10),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                FlatButton(
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.all(Radius.circular(
                                                                                20.0))),
                                                                    child: Text(
                                                                      "Retake",
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _currentImageTaken =
                                                                            null;
                                                                      });
                                                                    },
                                                                    color: Colors
                                                                        .white),
                                                                SizedBox(
                                                                  width: 10.0,
                                                                ),
                                                                RaisedButton(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(20.0))),
                                                                  child: Text(
                                                                    "Continue",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  color: CityColors
                                                                      .primary_teal,
                                                                  onPressed:
                                                                      () {
                                                                    _initBinUpload(
                                                                        _currentImageTaken);
                                                                  },
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
