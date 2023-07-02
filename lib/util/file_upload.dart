import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<String> uploadFile(File file) async {
  try {
    var request =
        http.MultipartRequest('POST', Uri.parse('http://10.249.45.98/songs'));

    // Add the file to the request
    var fileStream = http.ByteStream(Stream.castFrom(file.openRead()));
    var fileLength = await file.length();
    var multipartFile = http.MultipartFile('song', fileStream, fileLength,
        filename: path.basename(file.path));
    request.files.add(multipartFile);

    // Send the request
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('文件上传失败');
    }
  } catch (error) {
    return error.toString();
  }
  return "成功上传文件！";
}
