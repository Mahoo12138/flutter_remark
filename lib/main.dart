import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_remark/utils.dart';
import 'package:flutter_remark/window_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(800, 600);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "备注编辑小工具";
    win.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '备注编辑小工具',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      // here
      navigatorObservers: [FlutterSmartDialog.observer],
      // here
      builder: FlutterSmartDialog.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Widget> _inputWidgets = [];

  final Map<String, Map<String, String>> _inputResult = {};

  final List<XFile> _fileList = [];

  final Map<String, TextEditingController> _remarkControllers = {};
  final Map<String, TextEditingController> _pathControllers = {};

  final String svgName = 'assets/file.svg';

  void _reset() {
    setState(() {
      _inputWidgets.clear();
      _inputResult.clear();
      _fileList.clear();
      _pathControllers.clear();
      _remarkControllers.clear();
    });
  }

  void addInputWidget({XFile? file}) {
    var key = const Uuid().v4();
    _inputWidgets.add(_generateInput(key, file: file));
    setState(() {
      _inputResult[key] = {"path": file?.path ?? "", "remark": ""};
    });
  }

  void _dragDone(DropDoneDetails detail) {
    setState(() {
      for (var file in detail.files) {
        if (!checkIsPathExist(file.path)) {
          addInputWidget(file: file);
        } else {
          SmartDialog.showToast("\"" + file.path + '" 已在列表内');
        }
      }
    });
  }

  bool checkIsPathExist(String path) {
    var isExist = false;
    _inputResult.forEach((key, value) {
      if (value["path"] == path) {
        isExist = true;
      }
    });
    return isExist;
  }

  Widget _generateInput(String key, {XFile? file}) {
    _pathControllers[key] = TextEditingController(text: file?.path);
    _remarkControllers[key] = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _pathControllers[key],
            decoration: InputDecoration(
                hintText: "请输入文件夹路径",
                suffixIcon: IconButton(
                    onPressed: () => {_chooseDirectory(_pathControllers[key])},
                    icon: const Icon(Icons.more_horiz_rounded))),
          ),
        ),
        const SizedBox(width: 50),
        Expanded(
            child: TextField(
          controller: _remarkControllers[key],
          decoration: const InputDecoration(hintText: "请输入文件夹备注"),
        ))
      ],
    );
  }

  Widget initialWidget() {
    return Column(children: [
      SizedBox(
          width: 320,
          height: 420,
          child: SvgPicture.asset(svgName, semanticsLabel: 'Acme Logo')),
      const Text(
        "拖入文件夹或点击【添加】👇，开始编辑😊！",
        style: TextStyle(fontSize: 25),
      )
    ]);
  }

  Future<void> _chooseDirectory(TextEditingController? controller) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null && controller != null) {
      controller.text = selectedDirectory;
    }
  }

  _execModifyRemark() async {
    SmartDialog.showLoading(msg: "修改中");
    _inputResult.forEach((key, item) {
      if (item['path'] != "" && item['remark'] != "") {
        modifyRemark(item['path']!, item['remark']!);
      }
    });
    await Future.delayed(const Duration(milliseconds: 800));
    SmartDialog.dismiss();
    SmartDialog.showToast('修改成功');
  }

  @override
  Widget build(BuildContext context) {
    var style = ButtonStyle(
      padding: MaterialStateProperty.all(EdgeInsets.all(20)),
      minimumSize: MaterialStateProperty.all(Size(0, 0)),
      maximumSize: MaterialStateProperty.all(Size(400.0, 45.0)),
    );
    _pathControllers.forEach((key, controller) {
      controller.addListener(() {
        _inputResult[key]!["path"] = controller.text;
      });
    });
    _remarkControllers.forEach((key, controller) {
      controller.addListener(() {
        _inputResult[key]!["remark"] = controller.text;
      });
    });

    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: DropTarget(
              onDragDone: _dragDone,
              child: Column(
                children: [
                  WindowTitleBarBox(
                    child: Row(
                      children: [
                        Expanded(
                            child: MoveWindow(
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            child: const Text(
                              "备注编辑小工具",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        )),
                        WindowButtons()
                      ],
                    ),
                  ),
                  Expanded(
                      child: _inputResult.isEmpty
                          ? initialWidget()
                          : SingleChildScrollView(
                              child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: _inputWidgets,
                              ),
                            ))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                            onPressed: addInputWidget,
                            style: style,
                            child: const Text("添加")),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: _reset,
                          child: const Text("重置"),
                          style: style,
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                            onPressed:
                                _inputResult.isEmpty ? null : _execModifyRemark,
                            style: style,
                            child: const Text("确定"))
                      ],
                    ),
                  )
                ],
              ),
            )));
  }
}
