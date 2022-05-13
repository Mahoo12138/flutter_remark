import 'dart:io';

runCommand(String command) async {
  try {
    var result = await Process.run('powershell', ['/c', command]);
    return result.stdout;
  } catch (e) {
    print(e);
  }
}

getSettingFilePath(String path) {
  return path + '\\' + 'desktop.ini';
}

checkDirIsExist(String? path) {
  if (path == null) return false;
  var dir = Directory(path);
  return dir.existsSync();
}

modifyRemark(String path, String remark) async {
  var content = '[.ShellClassInfo]\r\nInfoTip=' + remark + '\r\n';
  var settingPath = getSettingFilePath(path);
  var settingFile = File(settingPath);
  try {
    String info = await runCommand("attrib '" + settingPath + '\' -s -h');
    if (info.startsWith("File not found")) {
      // print("文件不存在");
      settingFile.createSync();
    }
    await settingFile.writeAsString(content);
    runCommand("attrib '" + settingPath + "' +s +h");
    runCommand("attrib '" + path + "' +s");
  } catch (e) {
    print(e);
  }
}
