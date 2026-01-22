/// Network connectivity checker.
library;

import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for network info
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Implementation using connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  // final Connectivity _connectivity;
  
  // NetworkInfoImpl([Connectivity? connectivity]) 
  //     : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    // TODO: Implement with connectivity_plus
    // final result = await _connectivity.checkConnectivity();
    // return result != ConnectivityResult.none;
    return true; // Placeholder
  }

  @override
  Stream<bool> get onConnectivityChanged {
    // TODO: Implement with connectivity_plus
    // return _connectivity.onConnectivityChanged.map(
    //   (result) => result != ConnectivityResult.none,
    // );
    return Stream.value(true); // Placeholder
  }
}
