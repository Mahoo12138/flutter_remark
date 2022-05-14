import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_remark/utils.dart';
import 'package:flutter_remark/window_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:collection/collection.dart';
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
      home: const MyHomePage(),
      // here
      navigatorObservers: [FlutterSmartDialog.observer],
      // here
      builder: FlutterSmartDialog.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, String>> _inputResult = [];

  // 拖入的文件
  final List<XFile> _fileList = [];

  // 输入框的控制器
  final List<TextEditingController> _remarkControllers = [];
  final List<TextEditingController> _pathControllers = [];

  final GlobalKey _formKey = GlobalKey<FormState>();

  final String svgName = 'assets/file.svg';

  void _reset() {
    setState(() {
      _inputResult.clear();
      _fileList.clear();
      _pathControllers.clear();
      _remarkControllers.clear();
    });
  }

  void removeInputWidget(int index) {
    _remarkControllers.removeAt(index);
    _pathControllers.removeAt(index);
  }

  void addInputWidget({XFile? file}) {
    // var key = const Uuid().v4();
    // _inputWidgets.add(_generateFormField(key, file: file));
    setState(() {
      _pathControllers.add(TextEditingController(text: file?.path));
      _remarkControllers.add(TextEditingController());
      _inputResult.add({"path": file?.path ?? "", "remark": ""});
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
    _inputResult.mapIndexed((key, value) {
      if (value["path"] == path) {
        isExist = true;
      }
    });
    return isExist;
  }

  Widget _generateFormField(int index, {XFile? file}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _pathControllers[index],
            decoration: InputDecoration(
                hintText: "请输入文件夹路径",
                suffixIcon: IconButton(
                    onPressed: () =>
                        {_chooseDirectory(_pathControllers[index])},
                    icon: const Icon(Icons.more_horiz_rounded))),
            validator: (path) {
              print(path);
              return checkDirIsExist(path) ? null : "路径不存在或不合法";
            },
          ),
        ),
        const SizedBox(width: 50),
        Expanded(
            child: TextFormField(
          controller: _remarkControllers[index],
          decoration: const InputDecoration(hintText: "请输入文件夹备注"),
          validator: (comment) {
            // TODO: 为空应不应该清除
            return comment!.trim().isNotEmpty ? null : "备注不能为空";
          },
        )),
        IconButton(
            onPressed: () {
              setState(() {
                _inputResult.removeAt(index);
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.blue,
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
    if ((_formKey.currentState as FormState).validate()) {
      SmartDialog.showLoading(msg: "修改中");
      _inputResult.forEachIndexed((key, item) {
        if (item['path'] != "" && item['remark'] != "") {
          modifyRemark(item['path']!, item['remark']!);
        }
      });
      await Future.delayed(const Duration(milliseconds: 800));
      SmartDialog.dismiss();
      SmartDialog.showToast('修改成功');
    }
  }

  _restartExplorer() async {
    SmartDialog.show(
        widget: Container(
      margin: const EdgeInsets.all(20),
      height: 180,
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text(
          '确定要重启资源管理器吗？',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => SmartDialog.dismiss(),
                child: const Text("取消")),
            const SizedBox(width: 35),
            ElevatedButton(
                onPressed: () {
                  restartExplorer();
                  SmartDialog.dismiss();
                },
                child: const Text("确认")),
          ],
        )
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    var style = ButtonStyle(
      padding: MaterialStateProperty.all(EdgeInsets.all(20)),
      minimumSize: MaterialStateProperty.all(Size(0, 0)),
      maximumSize: MaterialStateProperty.all(Size(400.0, 45.0)),
    );
    _pathControllers.forEachIndexed((index, controller) {
      controller.addListener(() {
        _inputResult[index]["path"] = controller.text;
      });
    });
    _remarkControllers.forEachIndexed((index, controller) {
      controller.addListener(() {
        _inputResult[index]["remark"] = controller.text;
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
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                  key: _formKey,
                                  child: ListView.builder(
                                      itemCount: _inputResult.length,
                                      itemBuilder: ((context, index) {
                                        return _generateFormField(index);
                                      }))),
                            )),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _inputResult.isEmpty
                            ? Container()
                            : ElevatedButton(
                                onPressed: _restartExplorer,
                                style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(20)),
                                    minimumSize:
                                        MaterialStateProperty.all(Size(0, 0)),
                                    maximumSize: MaterialStateProperty.all(
                                        Size(400.0, 45.0)),
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.redAccent)),
                                child: const Text("重启资源管理器")),
                        const Expanded(child: SizedBox(width: 15)),
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
