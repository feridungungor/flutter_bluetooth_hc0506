import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'lamp/lamp.dart';
import 'lamp/lamp_hanger_rope.dart';
import 'lamp/lamp_switch.dart';
import 'lamp/lamp_switch_rope.dart';
import 'lamp/ledbulb.dart';
import 'lamp/room_name.dart';
import 'dart:math' as math;

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection connection;

  int _deviceState;

  bool isDisconnecting = false;

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  final darkGrey = const Color(0xFF232323);
  final animationDuration = const Duration(milliseconds: 500);

  bool get isConnected => connection != null && connection.isConnected;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0;

    enableBluetooth();

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _devicesList = devices;
    });
  }

  var _isSwitchOn = false;
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            Stack(
              children: <Widget>[
                LampHangerRope(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  color: darkGrey,
                ),
                LEDBulb(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  onColor: blubOnColor,
                  offColor: blubOffColor,
                  isSwitchOn: _isSwitchOn,
                ),
                Lamp(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  color: darkGrey,
                  isSwitchOn: _isSwitchOn,
                  gradientColor: blubOnColor,
                  animationDuration: animationDuration,
                ),
                LampSwitch(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  toggleOnColor: blubOnColor,
                  toggleOffColor: blubOffColor,
                  color: darkGrey,
                  isSwitchOn: _isSwitchOn,
                  onTap: () {
                    setState(() {
                      if (_connected) {
                        _isSwitchOn = !_isSwitchOn;
                        if (_isSwitchOn) {
                          _sendOnMessageToBluetooth();
                        } else {
                          _sendOffMessageToBluetooth();
                        }
                      }
                    });
                  },
                  animationDuration: animationDuration,
                ),
                LampSwitchRope(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  color: darkGrey,
                  isSwitchOn: _isSwitchOn,
                  animationDuration: animationDuration,
                ),
                RoomName(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  color: darkGrey,
                  roomName: "Lambader",
                )
              ],
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              right: _isOpen ? 0 : -160,
              child:                  Container(
                height: screenHeight,
                width: screenWidth / 2,
                color: darkGrey.withAlpha(200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () async {
                            await getPairedDevices().then(
                                  (_) {
                                show('Device Listesi Yenilendi');
                              },
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 50),
                            child: Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(left: 10, top: 50),
                            child: Text(
                              "Refresh",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ))
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            FlutterBluetoothSerial.instance.openSettings();
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 10, top: 10),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 10),
                          child: Text(
                            "Settings",
                            style: TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20,),
                    GestureDetector(
                      onTap: _isButtonUnavailable
                          ? null
                          : _connected ? _disconnect : _connect,
                      child: Container(
                        height: screenHeight / 5,
                        width: 40,
                        color: Colors.green.withAlpha(200),
                        child: Stack(
                          children: <Widget>[
                            Positioned(
                              bottom: 75,
                              right: _connected ? -15 : -8,
                              child: Transform.rotate(
                                angle: -1.58,
                                child: Text(
                                  _connected ? 'Disconnect'.toUpperCase() : 'Connect'.toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      height: 40,
                      color: Colors.white,
                      child: DropdownButton(
                        icon: Icon(Icons.arrow_downward),
                        iconSize: 20,
                        items: _getDeviceItems(),
                        onChanged: (value) =>
                            setState(() => _device = value),
                        value: _devicesList.isNotEmpty ? _device : null,
                        style: TextStyle(color: darkGrey),
                        underline: Container(
                          height: 2,
                          color: darkGrey.withAlpha(200),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Visibility(
                      visible: _isButtonUnavailable &&
                          _bluetoothState == BluetoothState.STATE_ON,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.green,
                        valueColor: AlwaysStoppedAnimation<Color>(darkGrey),
                      ),
                    )
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        show('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
  }

  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1;
    });
  }

  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1;
    });
  }

  Future show(String message,
      {Duration duration: const Duration(seconds: 3)}) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}
