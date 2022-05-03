import 'dart:io';

runCommand(String command) async {
  var result = await Process.run('cmd', ['/c', command]);
}

getSettingFilePath(String path) {
  return path + '\\' + 'desktop.ini';
}

modifyRemark(String path, String remark) async {
  var content = '[.ShellClassInfo]\r\nInfoTip=' + remark + '\r\n';
  var settingPath = getSettingFilePath(path);
  var settingFile = File(settingPath);
  await settingFile.writeAsString(content);
  runCommand("attrib " + settingPath + ' +s +h');
  runCommand("attrib " + path + ' +s');
}

