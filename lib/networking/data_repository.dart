import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:citycollection/exceptions/data_fetch_exception.dart';
import 'package:citycollection/exceptions/data_upload_exception.dart';
import 'package:citycollection/models/current_user.dart';
import 'package:citycollection/models/prize.dart';
import 'package:citycollection/models/scan_winnings.dart';
import 'package:citycollection/models/tagged_bin.dart';
import 'package:citycollection/networking/db.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/image.dart';
import 'package:logging/logging.dart';

class DataRepository {
  DataRepository(this.db);

  final DB db;
  final List<Prize> cachedPrizes = List();
  final List<TaggedBin> _cachedBins = List();
  StreamController<TaggedBin> _binStreamController;
  StreamSubscription<TaggedBin> _binStreamSubscription;

  final Logger logger = Logger("DataRepository");
  double redeemPageScrollPosition = 0;

  Future<void> createUser(String email, String name, String uid, DateTime dob) {
    try {
      return db.createUser(email, name, uid, dob);
    } catch (e, stk) {
      throw DataUploadException(e.toString(), stk);
    }
  }

  Future<CurrentUser> fetchCurrentUser(String id) {
    try {
      return db.fetchCurrentUser(id);
    } catch (e) {
      throw DataFetchException(e.toString());
    }
  }

  Future<PrizeRedemptionStatus> redeemPrize(
      Prize prize, CurrentUser user) async {
    try {
      return await db.redeemPrize(prize, user);
    } on PlatformException catch (e, stk) {
      logger.severe(e.toString());
      logger.severe(stk);
      throw DataFetchException(e.message);
    }
  }

  Future<List<Prize>> fetchPrizes() async {
    try {
      List<Prize> prizes = await db.fetchPrizes();
      prizes.forEach((prize) {
        if (!cachedPrizes.contains(prize)) {
          cachedPrizes.add(prize);
        }
      });
      return prizes;
    } catch (e) {
      throw DataFetchException(e.toString());
    }
  }

  List<TaggedBin> openBinStream(Function(List<TaggedBin> bins) onBinsChanged) {
    try {
      logger.info("Opening bin stream");
      _binStreamController = db.openBinStream();
      _binStreamSubscription =
          _binStreamController.stream.listen((TaggedBin bin) {
        if (_cachedBins.contains(bin)) {
        } else {
          bool contained = false;
          _cachedBins.forEach((oldBin) {
            if (oldBin.id == bin.id) {
              _cachedBins.remove(oldBin);
              _cachedBins.add(bin);
              contained = true;
            }
          });
          if (!contained) _cachedBins.add(bin);
        }
        onBinsChanged(_cachedBins);
      });
      return _cachedBins;
    } catch (e, stacktrace) {
      logger.severe("Opening bin stream has failed: ${e.toString()}");
      logger.severe(stacktrace);
      throw DataFetchException(e.toString());
    }
  }

  void closeBinStream() {
    logger.info("Closing bin streamcontrollers and subscriptions");
    db.closeBinStream();
    _binStreamController?.close();
    _binStreamSubscription?.cancel();
  }

  Future<void> uploadWasteImage(CurrentUser user, Uint8List image) async {
    try {
      String ref = await db.uploadWasteImageData(user, image);
      await db.saveDisposalData(user, ref);
    } catch (e, stacktrace) {
      logger.severe("Error uploading disposal data");
      logger.severe(stacktrace);
      throw DataUploadException(e, stacktrace);
    }
  }

  Future<void> uploadTaggedBin(
      CurrentUser user, TaggedBin bin, File image) async {
    try {
      String ref = await db.uploadBinImageData(user, image);
      TaggedBin updatedBin = bin.copyWith(imageSrc: ref);
      await db.saveTaggedBin(user, updatedBin);
    } catch (e, stacktrace) {
      logger.severe("Error uploading disposal data");
      logger.severe(stacktrace);
      throw DataUploadException(e, stacktrace);
    }
  }

  Future<void> updateTaggedBin(CurrentUser user, TaggedBin bin) async {
    try {
      await db.updateTaggedBin(bin, user);
    } on PlatformException catch (e, stacktrace) {
      logger.severe("Error uploading disposal data");
      logger.info(e.message);
      logger.severe(stacktrace);
      throw DataUploadException(e.message, stacktrace);
    }
  }

  Future<ScanWinnings> fetchScanWinnings(CurrentUser user) async {
    return db.fetchScanWinnings(user);
  }
}
