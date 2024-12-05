import 'package:broadcast/signaling.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget{
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _initializeRenderers();
    signaling.onAddRemoteStream = ((stream){
      if (stream != null){
        _remoteRenderer.srcObject = stream;
        setState(() {});
      }else{
        print("No remote stream available.");
      }
    });
  }

  Future<void> _initializeRenderers() async{
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose(){
    _disposeResources();
    super.dispose();
  }

  Future<void> _disposeResources() async{
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context){
    double h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            SizedBox(height: 100),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: (){
                      signaling.openUserMedia(_localRenderer, _remoteRenderer);
                    },
                    child: Text("カメラ起動"),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () async{
                      try {
                        roomId = await signaling.createRoom(_remoteRenderer);
                        if (roomId != null) {
                          textEditingController.text = roomId!;
                          setState(() {});
                        }else{
                          print("Failed to create room.");
                        }
                      } catch (e){
                        print("Error creating room: $e");
                      }
                    },
                    child: Text("ルーム作成"),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      if (textEditingController.text.trim().isNotEmpty) {
                        signaling.joinRoom(
                          textEditingController.text.trim(),
                          _remoteRenderer,
                        );
                      } else{
                        print("Room ID is empty.");
                      }
                    },
                    child: Text("参加する"),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: (){
                      signaling.hangUp(_localRenderer);
                      _localRenderer.srcObject = null;
                      _remoteRenderer.srcObject = null;
                      setState(() {});
                    },
                    child: Text("手をあげる"),
                  ),
                  SizedBox(height: 50),
                  Text("ルーム検索"),
                  TextFormField(
                    controller: textEditingController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: false,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: RTCVideoView(
                    _remoteRenderer,
                    mirror: false,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}