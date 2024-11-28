// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';

import 'package:image_picker/image_picker.dart';
import 'package:poem_app/models/poem_model.dart';

class PoemService {
  final ImagePicker _picker = ImagePicker();

  final String poemDocumentId = "single_poem"; // معرف ثابت للوثيقة

  final String apiKey = 'AIzaSyCNtfRU7_9QVz4ESzcMSwga4abjT2ZMPjU'; // استخدم مفتاح API الصحيح
  final String projectId = 'poem-app-e89f8'; // استخدم معرف المشروع الصحيح
    final String bucketName =
      'poem-app-e89f8.appspot.com'; // استخدم اسم الـ bucket الخاص بك


  // 1. رفع بيانات القصيدة
  Future<void> uploadPoem(Poem poem) async {
    try {
      // تحويل القصيدة إلى JSON
      String poemJson = jsonEncode(poem.toJson());

      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب PUT باستخدام Dio لرفع البيانات
      Dio dio = Dio();
      Response response = await dio.put(
        url,
        data: jsonEncode({
          'fields': {
            // إضافة الحقول هنا بناءً على هيكل القصيدة
            'title': {'stringValue': poem.title},
            'author': {'stringValue': poem.author},
            'description': {'stringValue': poem.description},
            'price': {'stringValue': poem.price},
            'paymentMethods': {'stringValue': poem.paymentMethods},
            // أضف الحقول الأخرى حسب الحاجة
          }
        }),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        print("تم رفع القصيدة بنجاح");
      } else {
        print("فشل رفع القصيدة: ${response.statusCode}");
      }
    } catch (e) {
      print("خطأ في رفع القصيدة: $e");
    }
  }
  // 1. جلب بيانات القصيدة
  Future<Poem?> fetchPoem() async {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET باستخدام Dio لجلب البيانات
      Dio dio = Dio();
      Response response = await dio.get(url);

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        // تحويل البيانات من JSON إلى كائن Poem
        Map<String, dynamic> data =
            response.data['fields'] as Map<String, dynamic>;

        // إنشاء كائن Poem من البيانات
        Poem poem = Poem.fromJson(data);
        return poem;
      } else {
        print("القصيدة غير موجودة");
        return null;
      }
    } catch (e) {
      print("خطأ في استرجاع القصيدة: $e");
      return null;
    }
  }

  // 2. تحديث بيانات القصيدة
  Future<void> updatePoemInfo(Poem updatedPoem) async {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // تحضير البيانات التي سيتم تحديثها في الوثيقة
      Map<String, dynamic> updateData = {
        "fields": {
          "title": {"stringValue": updatedPoem.title},
          "author": {"stringValue": updatedPoem.author},
          "description": {"stringValue": updatedPoem.description},
          "price": {"doubleValue": updatedPoem.price},
          "paymentMethods": {
         "paymentMethods": {
              "mapValue": {
                "fields": updatedPoem.paymentMethods.map((key, value) {
                  return MapEntry(key, {
                    "stringValue": value
                  }); // تحويل كل قيمة إلى "stringValue"
                })
              }
            },
          },
        }
      };

      // إرسال طلب PATCH باستخدام Dio لتحديث الوثيقة
      Dio dio = Dio();
      Response response = await dio.patch(url, data: updateData);

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        print("تم تحديث القصيدة بنجاح");
      } else {
        print("فشل في تحديث القصيدة: ${response.statusCode}");
      }
    } catch (e) {
      print("خطأ في تحديث القصيدة: $e");
      throw Exception('Failed to update poem: $e');
    }
  }

  // 3. استرجاع بيانات القصيدة كـ Stream عبر REST API
  Stream<Poem?> getPoemStream() async* {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET للحصول على بيانات الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        // إذا تم الحصول على البيانات بنجاح
        Map<String, dynamic> data = json.decode(response.data);

        // تحويل البيانات إلى كائن Poem
        Poem poem = Poem.fromJson(data['fields']);

        // إرسال البيانات عبر الـ Stream
        yield poem;
      } else {
        print("فشل في جلب القصيدة: ${response.statusCode}");
        yield null; // إرجاع null إذا فشل الطلب
      }
    } catch (e) {
      print("خطأ في جلب القصيدة: $e");
      yield null; // إرجاع null إذا حدث خطأ
    }
  }


  // 3. استرجاع بيانات القصيدة عبر REST API واستخراج أول سطرين فقط
  Stream<Poem?> getPoemFreeStream() async* {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET للحصول على بيانات الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        // إذا تم الحصول على البيانات بنجاح
        Map<String, dynamic> data = json.decode(response.data);
        
        // استخراج الأسطر وتحويلها إلى قائمة من كائنات Line
        List<dynamic> linesData = data['fields']['lines']['arrayValue']['values'] ?? [];

        // تحويل كل عنصر من القائمة إلى كائن Line
        List<Line> allLines = linesData.map((lineData) {
          return Line(
            hemistich1: lineData['mapValue']['fields']['hemistich1']['stringValue'] ?? '',
            hemistich2: lineData['mapValue']['fields']['hemistich2']['stringValue'] ?? '',
            prose: lineData['mapValue']['fields']['prose']['stringValue'] ?? '',
            grammarAnalysis: Map<String, String>.from(lineData['mapValue']['fields']['grammarAnalysis']['mapValue']['fields'] ?? {}),
            rhetoricAnalysis: Map<String, String>.from(lineData['mapValue']['fields']['rhetoricAnalysis']['mapValue']['fields'] ?? {}),
            wordMeanings: Map<String, String>.from(lineData['mapValue']['fields']['wordMeanings']['mapValue']['fields'] ?? {}),
            imageUrl: lineData['mapValue']['fields']['imageUrl']['stringValue'] ?? '',
            voiceUrl: lineData['mapValue']['fields']['voiceUrl']['stringValue'] ?? '',
          );
        }).toList();

        // أخذ أول سطرين فقط
        List<Line> firstTwoLines = allLines.take(2).toList();

        // تحديث البيانات مع السطرين الأولين فقط
        data['fields']['lines']['arrayValue']['values'] = firstTwoLines.map((line) {
          return {
            'mapValue': {
              'fields': {
                'hemistich1': {'stringValue': line.hemistich1},
                'hemistich2': {'stringValue': line.hemistich2},
                'prose': {'stringValue': line.prose},
                'grammarAnalysis': {'mapValue': {'fields': line.grammarAnalysis}},
                'rhetoricAnalysis': {'mapValue': {'fields': line.rhetoricAnalysis}},
                'wordMeanings': {'mapValue': {'fields': line.wordMeanings}},
                'imageUrl': {'stringValue': line.imageUrl},
                'voiceUrl': {'stringValue': line.voiceUrl},
              },
            }
          };
        }).toList();

        // تحويل البيانات إلى كائن Poem
        yield Poem.fromJson(data['fields']);
      } else {
        print("فشل في جلب القصيدة: ${response.statusCode}");
        yield null;  // إرجاع null إذا فشل الطلب
      }
    } catch (e) {
      print("خطأ في جلب القصيدة: $e");
      yield null;  // إرجاع null إذا حدث خطأ
    }
  }



  // 4. حذف بيت من القصيدة عبر REST API
  Future<void> deleteLine(int lineIndex) async {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET للحصول على بيانات الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        // إذا تم الحصول على البيانات بنجاح
        Map<String, dynamic> data = json.decode(response.data);

        // استخراج الأسطر وتحويلها إلى قائمة من كائنات Line
        List<dynamic> linesData =
            data['fields']['lines']['arrayValue']['values'] ?? [];

        // تحقق إذا كان الفهرس ضمن حدود القائمة
        if (lineIndex >= 0 && lineIndex < linesData.length) {
          // حذف البيت من القائمة
          linesData.removeAt(lineIndex);

          // تحديث البيانات بعد حذف البيت
          data['fields']['lines']['arrayValue']['values'] = linesData;

          // إرسال طلب PATCH لتحديث الوثيقة
          Response updateResponse = await dio.patch(
            url,
            data: {
              'fields': {
                'lines': {
                  'arrayValue': {
                    'values': linesData,
                  }
                }
              }
            },
          );

          if (updateResponse.statusCode == 200) {
            print("تم حذف البيت بنجاح");
          } else {
            print("فشل في تحديث القصيدة بعد الحذف");
          }
        } else {
          print("البيت غير موجود في الفهرس المحدد");
        }
      } else {
        print("فشل في جلب القصيدة: ${response.statusCode}");
      }
    } catch (e) {
      print("خطأ في حذف البيت: $e");
    }
  }
  // استرجاع قائمة الأسطر مباشرة من وثيقة القصيدة عبر REST API
  Future<List<Line>?> fetchLines() async {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET للحصول على بيانات الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        // إذا تم الحصول على البيانات بنجاح
        Map<String, dynamic> data = json.decode(response.data);

        // استخراج قائمة الأسطر وتحويلها إلى كائنات Line
        List<dynamic> linesData =
            data['fields']['lines']['arrayValue']['values'] ?? [];

        // تحويل كل عنصر من القائمة إلى كائن Line
        List<Line> lines = linesData.map((lineJson) {
          return Line.fromJson(lineJson);
        }).toList();

        return lines;
      } else {
        print("فشل في جلب القصيدة: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("خطأ في استرجاع الأسطر: $e");
      return null;
    }
  }

  String removeDiacritics(String input) {
    final diacritics = RegExp(r'[\u064B-\u0652]');
    return input.replaceAll(diacritics, '');
  }

  // دالة البحث في قائمة الأسطر
  List<Line> searchLines(List<Line> lines, String query) {
    final lowerQuery = removeDiacritics(query.toLowerCase());

    return lines.where((line) {
      // إزالة التشكيل من الخصائص النصية للمقارنة
      final hemistich1 = removeDiacritics(line.hemistich1.toLowerCase());
      final hemistich2 = removeDiacritics(line.hemistich2.toLowerCase());
      final prose = removeDiacritics(line.prose.toLowerCase());
      if (hemistich1.toLowerCase().contains(lowerQuery) ||
          hemistich2.toLowerCase().contains(lowerQuery) ||
          prose.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      if (line.grammarAnalysis.entries.any((entry) =>
          removeDiacritics(entry.key.toLowerCase()).contains(lowerQuery) ||
          removeDiacritics(entry.value.toLowerCase()).contains(lowerQuery))) {
        return true;
      }

      if (line.rhetoricAnalysis.entries.any((entry) =>
          removeDiacritics(entry.key.toLowerCase()).contains(lowerQuery) ||
          removeDiacritics(entry.value.toLowerCase()).contains(lowerQuery))) {
        return true;
      }

      if (line.wordMeanings.entries.any((entry) =>
          removeDiacritics(entry.key.toLowerCase()).contains(lowerQuery) ||
          removeDiacritics(entry.value.toLowerCase()).contains(lowerQuery))) {
        return true;
      }

      return false;
    }).toList();
  }

// استرجاع أول X أسطر من وثيقة القصيدة عبر REST API
  Future<List<Line>?> fetchLimitedLines(int limit) async {
    try {
      // بناء الرابط للوصول إلى وثيقة القصيدة
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/poem/$poemDocumentId?key=$apiKey';

      // إرسال طلب GET للحصول على بيانات الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        // إذا تم الحصول على البيانات بنجاح
        Map<String, dynamic> data = json.decode(response.data);

        // استخراج قائمة الأسطر وتحويلها إلى كائنات Line
        List<dynamic> linesData =
            data['fields']['lines']['arrayValue']['values'] ?? [];

        // تحويل كل عنصر من القائمة إلى كائن Line
        List<Line> lines = linesData.map((lineJson) {
          return Line.fromJson(lineJson);
        }).toList();

        // إرجاع أول X أسطر بناءً على القيمة المحددة
        return lines.take(limit).toList();
      } else {
        print("فشل في جلب القصيدة: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("خطأ في استرجاع الأسطر: $e");
      return null;
    }
  }

  // Pick an image and return File
  Future<File?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  // Pick an audio file and return File
  Future<File?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return null;
    return File(result.files.single.path!);
  }

  // رفع ملف إلى Firebase Storage عبر Google Cloud Storage API
  Future<String?> uploadFile(File file, String folder) async {
    try {
      String fileName = basename(file.path);
      String uploadUrl =
          'https://storage.googleapis.com/upload/storage/v1/b/$bucketName/o?uploadType=multipart&name=$folder/$fileName';

      Dio dio = Dio();
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      Response response = await dio.post(uploadUrl,
          data: formData,
          options: Options(headers: {
            'Authorization':
                'Bearer your-access-token', // احصل على الـ Access Token المناسب
          }));

      if (response.statusCode == 200) {
        // في حال نجاح الرفع، الحصول على رابط التنزيل
        Map<String, dynamic> responseData = json.decode(response.data);
        String downloadUrl =
            'https://storage.googleapis.com/$bucketName/${responseData['name']}';
        return downloadUrl;
      } else {
        print("فشل في رفع الملف: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("خطأ في رفع الملف: $e");
      return null;
    }
  }

  // // حفظ رابط الصورة في قاعدة البيانات فقط
  // Future<void> saveImageUrl(String docId, String imageUrl) async {
  //   await _firestore.collection('poems').doc(docId).update({
  //     'imageUrl': imageUrl,
  //   });
  // }

  // // حفظ رابط الصوت في قاعدة البيانات فقط
  // Future<void> saveAudioUrl(String docId, String audioUrl) async {
  //   await _firestore.collection('poems').doc(docId).update({
  //     'audioUrl': audioUrl,
  //   });
  // }
}
