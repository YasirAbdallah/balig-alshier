// ignore_for_file: empty_catches, use_rethrow_when_possible

import 'dart:convert';
 
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poem_app/models/pay_info_model.dart';
import 'dart:io';

import 'package:poem_app/models/payments_model.dart';

class PaymentServices {
    final String projectId = 'poem-app-e89f8';

   final String storageUrl =
      'https://firebasestorage.googleapis.com/v0/b/poem-app-e89f8.appspot.com/o/';
  final String apiKey = 'AIzaSyCNtfRU7_9QVz4ESzcMSwga4abjT2ZMPjU'; // استخدم مفتاح API الصحيح
  // final ImagePicker _picker = ImagePicker();

  // طريقة لاختيار الصورة من المعرض أو الكاميرا
  Future<File?> pickPaymentImage() async {
    ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery); // يمكن استبدال .gallery بـ .camera
    if (pickedImage != null) {
      return File(pickedImage.path);
    }
    return null;
  }

  // طريقة لتحميل الصورة إلى Firebase باستخدام Dio
  Future<String?> uploadPaymentImage(File image, String userId) async {
    try {
      // تحديد مسار الصورة في Firebase Storage
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  //    String filePath = 'paymentImages/$userId/$fileName';

      // تحديد رابط الـ REST API للرفع
      String uploadUrl =
          '$storageUrl$Uri.encodeComponent(filePath)}?uploadType=multipart&key=$apiKey';

      // تحضير الملف لرفع باستخدام Dio
      Dio dio = Dio();
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: fileName),
      });

      // إرسال طلب POST لتحميل الصورة
      Response response = await dio.post(uploadUrl, data: formData);

      if (response.statusCode == 200) {
        // عند النجاح في الرفع، احصل على رابط التنزيل
        String downloadUrl = response.data['mediaLink'];

        // حفظ رابط الصورة في Firestore
        await _updatePaymentImage(downloadUrl, userId);

        return downloadUrl; // إرجاع الرابط
      } else {
        print('Failed to upload image: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error uploading payment image: $e');
      return null;
    }
  }

  // دالة لتحديث صورة الدفع في Firestore باستخدام REST API
  Future<void> _updatePaymentImage(String paymentImage, String userId) async {
    try {
      // رابط REST API لتحديث البيانات في Firestore
      final String firestoreUrl =
          'https://firestore.googleapis.com/v1/projects/your-project-id/databases/(default)/documents/payments/$userId?key=$apiKey';

      // إعداد الجسم (body) لتحديث صورة الدفع في Firestore
      final body = json.encode({
        'fields': {
          'paymentImage': {'stringValue': paymentImage}
        }
      });

      // إرسال طلب PATCH لتحديث الوثيقة في Firestore
      Dio dio = Dio();
      Response response = await dio.patch(
        firestoreUrl,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        print('Payment image updated successfully in Firestore');
      } else {
        print('Error updating payment image in Firestore: ${response.data}');
      }
    } catch (e) {
      print('Error updating payment image in Firestore: $e');
    }
  }

// جلب بيانات الدفع من Firebase
  // جلب بيانات الدفع من Firestore عبر REST API
  Future<List<PaymentModel>> fetchPayments() async {
    try {
      // بناء الرابط الخاص بالاستعلام على مجموعة "payments"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments?key=$apiKey';

      Dio dio = Dio();
      Response response = await dio.get(url);

      // التأكد من أن الاستجابة صحيحة
      if (response.statusCode == 200) {
        List<PaymentModel> payments = [];

        // تحويل الاستجابة إلى قائمة من الوثائق
        var documents = response.data['documents'] as List;

        // التحقق من كل وثيقة وجلب البيانات
        for (var doc in documents) {
          Map<String, dynamic> data = _parseFields(doc['fields']);

          // التحقق من وجود صورة الدفع
          if (data.containsKey('paymentImage') &&
              data['paymentImage'] != null &&
              data['paymentImage'].toString().isNotEmpty) {
            if (data['isUpgraded'] == false || data['isUpgraded'] == null) {
              payments.add(PaymentModel.fromMap(data));
            }
          }
        }

        return payments;
      } else {
        print('Failed to fetch payments: ${response.data}');
        return [];
      }
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  // دالة لتحويل الحقول الخاصة بالوثيقة إلى خريطة
  Map<String, dynamic> _parseFields(Map<String, dynamic> fields) {
    Map<String, dynamic> parsedData = {};

    fields.forEach((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('stringValue')) {
        parsedData[key] = value['stringValue'];
      } else if (value is Map<String, dynamic> &&
          value.containsKey('booleanValue')) {
        parsedData[key] = value['booleanValue'];
      } else if (value is Map<String, dynamic> &&
          value.containsKey('integerValue')) {
        parsedData[key] = value['integerValue'];
      }
      // إضافة المزيد من القيم حسب الحاجة
    });

    return parsedData;
  }

  // إرسال رد الإدارة إلى Firebase
  Future<void> sendAdminRespond(String userId, String adminRespond) async {
    try {
      // بناء رابط الوثيقة الخاصة بالمستخدم في مجموعة "payments"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

      // بناء البيانات التي سيتم تحديثها
      Map<String, dynamic> dataToUpdate = {
        'fields': {
          'adminRespond': {
            'stringValue': adminRespond
          }, // تحديث حقل adminRespond
        }
      };

      // إرسال طلب PATCH باستخدام Dio
      Dio dio = Dio();
      Response response = await dio.patch(
        url,
        data: json.encode(dataToUpdate),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('Admin response updated successfully');
      } else {
        print('Failed to update admin response: ${response.data}');
      }
    } catch (e) {
      print('Error sending admin response: $e');
      throw e;
    }
  }


  // جلب بيانات الدفع من Firebase
  Future<List<PaymentModel>> fetchPastPayments() async {
    try {
      // بناء الرابط للوصول إلى جميع المستندات في مجموعة payments
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments?key=$apiKey';

      // إرسال طلب GET باستخدام Dio
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        List<PaymentModel> payments = [];

        // تحويل الوثائق إلى كائنات PaymentModel
        for (var doc in response.data['documents']) {
          Map<String, dynamic> data = doc['fields'] as Map<String, dynamic>;

          // التحقق من وجود paymentImage وعدم كونه فارغًا
          if (data['paymentImage'] != null &&
                  data['paymentImage']['stringValue']?.isNotEmpty) {
            payments.add(PaymentModel.fromMap({
              'paymentImage': data['paymentImage']['stringValue'],
              // أضف باقي الحقول هنا بناءً على هيكل الـ PaymentModel
            }));
          }
        }

        return payments;
      } else {
        return []; // إذا كانت الاستجابة غير ناجحة
      }
    } catch (e) {
      print('Error fetching past payments: $e');
      return []; // في حالة حدوث خطأ
    }
  }
  // استرجاع رابط صورة الدفع من Firestore
  Future<String?> getPaymentImage(String userId) async {
    try {
      // بناء رابط الوثيقة الخاصة بالمستخدم في مجموعة "payments"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

      // إرسال طلب GET باستخدام Dio لاسترجاع الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        // تحويل الاستجابة إلى خريطة JSON
        Map<String, dynamic> data = json.decode(response.data);

        // استرجاع رابط صورة الدفع من الحقول
        if (data['fields'] != null && data['fields']['paymentImage'] != null) {
          String? paymentImageUrl =
              data['fields']['paymentImage']['stringValue'];
          return paymentImageUrl;
        } else {
          return null; // إذا لم يكن هناك رابط صورة
        }
      } else {
        print('Failed to fetch payment image: ${response.data}');
        return null; // في حال فشل الاسترجاع
      }
    } catch (e) {
      print('Error fetching payment image: $e');
      return null; // في حال حدوث خطأ
    }
  }
  // ترقية المستخدم في Firestore
  Future<void> upgradeUser(String userId) async {
    try {
      // بناء رابط الوثيقة الخاصة بالمستخدم في مجموعة "payments"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

      // البيانات التي سيتم تحديثها (ترقية المستخدم)
      Map<String, dynamic> data = {
        'fields': {
          'isUpgraded': {'booleanValue': true}, // ترقية الحقل إلى true
        }
      };

      // إرسال طلب PATCH باستخدام Dio لتحديث الوثيقة
      Dio dio = Dio();
      Response response = await dio.patch(
        url,
        data: json.encode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('User upgraded successfully');
      } else {
        print('Failed to upgrade user: ${response.data}');
      }
    } catch (e) {
      print('Error upgrading user: $e');
    }
  }

  // جلب رد الإدارة بناءً على userId
  Future<String?> getAdminResponse(String userId) async {
    try {
      // بناء رابط الوثيقة الخاصة بالرد في مجموعة "adminResponses"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/adminResponses/$userId?key=$apiKey';

      // إرسال طلب GET باستخدام Dio لجلب الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        // إذا كانت الاستجابة ناجحة، الحصول على الرد
        Map<String, dynamic> data = json.decode(response.data);
        String? adminResponse = data['fields']?['response']?['stringValue'];
        return adminResponse;
      } else {
        print('Failed to get admin response: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error getting admin response: $e');
      return null;
    }
  }


  // دالة للتحقق مما إذا كانت صورة الدفع موجودة
  Future<bool> doesPaymentImageExist(String userId) async {
    try {
      // بناء رابط الوثيقة الخاصة بالمستخدم في مجموعة "payments"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

      // إرسال طلب GET باستخدام Dio للحصول على الوثيقة
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        // إذا كانت الاستجابة ناجحة، الحصول على بيانات الوثيقة
        Map<String, dynamic> data = json.decode(response.data);

        // التحقق من وجود حقل 'paymentImage' في البيانات
        String? paymentImageUrl =
            data['fields']?['paymentImage']?['stringValue'];

        // إرجاع ما إذا كانت صورة الدفع موجودة
        return paymentImageUrl != null && paymentImageUrl.isNotEmpty;
      } else {
        print('Failed to fetch payment document: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Error checking payment image: $e');
      return false;
    }
  }
    // طريقة للتحقق مما إذا كان المستخدم قد تم ترقيته
  Future<bool> isUserUpgraded(String userId) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        // بناء رابط الوثيقة الخاصة بالمستخدم في مجموعة "payments"
        String url =
            'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

        // إرسال طلب GET باستخدام Dio للحصول على الوثيقة
        Dio dio = Dio();
        Response response = await dio.get(
          url,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        if (response.statusCode == 200) {
          // إذا كانت الاستجابة ناجحة، الحصول على بيانات الوثيقة
          Map<String, dynamic> data = json.decode(response.data);

          // التحقق من وجود الحقل "isUpgraded"
          bool isUpgraded =
              data['fields']?['isUpgraded']?['booleanValue'] ?? false;
          return isUpgraded;
        } else {
          print('Failed to fetch payment document: ${response.data}');
          return false;
        }
      } catch (e) {
        attempts++;
        await Future.delayed(
            Duration(seconds: 2 * attempts)); // زيادة وقت الانتظار مع كل محاولة
      }
    }
    return false;
  }


// رفع معلومات الدفع
  Future<void> uploadPayInfo(PayInfoModel payInfo) async {
    try {
      // بناء رابط للرفع في Firestore في مجموعة "paymentInfo"
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/paymentInfo/payInfo?key=$apiKey';

      // تحويل PayInfoModel إلى Map لتكون جاهزة للإرسال
      Map<String, dynamic> data = payInfo.toMap();

      // إرسال طلب POST باستخدام Dio لرفع البيانات
      Dio dio = Dio();
      Response response = await dio.post(
        url,
        data: json.encode({
          "fields": {
            "fieldName1": {
              "stringValue": data['fieldName1']
            }, // استبدل fieldName1 بالاسم الفعلي للحقل
            "fieldName2": {
              "stringValue": data['fieldName2']
            }, // استبدل fieldName2 بالاسم الفعلي للحقل
            // إضافة الحقول الأخرى بناءً على بنية PayInfoModel
          }
        }),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('Payment info uploaded successfully');
      } else {
        print('Failed to upload payment info: ${response.data}');
      }
    } catch (e) {
      print('Error uploading payment info: $e');
      rethrow;
    }
  }
  // جلب معلومات الدفع
  Future<PayInfoModel?> getPayInfo() async {
    try {
      // بناء رابط لاسترجاع البيانات من Firestore
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/paymentInfo/payInfo?key=$apiKey';

      // إرسال طلب GET باستخدام Dio
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        // تحويل البيانات المسترجعة إلى نموذج PayInfoModel
        Map<String, dynamic> data =
            response.data['fields'] as Map<String, dynamic>;

        // تحويل الحقول إلى التنسيق المناسب
        PayInfoModel payInfo = PayInfoModel.fromMap({
          'fieldName1': data['fieldName1']
              ['stringValue'], // استبدل fieldName1 بالاسم الفعلي للحقل
          'fieldName2': data['fieldName2']
              ['stringValue'], // استبدل fieldName2 بالاسم الفعلي للحقل
          // إضافة الحقول الأخرى بناءً على بنية PayInfoModel
        });

        return payInfo;
      } else {
        return null; // في حال كانت الاستجابة غير ناجحة
      }
    } catch (e) {
      print('Error fetching payment info: $e');
      return null;
    }
  }

   // الدالة للحصول على دفعة مستخدم واحدة كمجموعة
  Future<PaymentModel?> getUserPayment(String userId) async {
    try {
      // بناء الرابط للوصول إلى مستند الدفع الخاص بالمستخدم
      String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';

      // إرسال طلب GET باستخدام Dio
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // التحقق من حالة الاستجابة
      if (response.statusCode == 200) {
        // تحويل البيانات المسترجعة إلى نموذج PaymentModel
        Map<String, dynamic> data =
            response.data['fields'] as Map<String, dynamic>;

        // تحويل الحقول إلى التنسيق المناسب
        PaymentModel payment = PaymentModel.fromMap({
          'fieldName1': data['fieldName1']
              ['stringValue'], // استبدل fieldName1 بالاسم الفعلي للحقل
          'fieldName2': data['fieldName2']
              ['stringValue'], // استبدل fieldName2 بالاسم الفعلي للحقل
          // إضافة الحقول الأخرى بناءً على بنية PaymentModel
        });

        return payment;
      } else {
        return null; // في حال كانت الاستجابة غير ناجحة
      }
    } catch (e) {
      print('Error fetching user payment: $e');
      return null;
    }
  }
    // الدالة للحصول على دفعة مستخدم واحدة كمجموعة باستخدام REST API وتحويلها إلى Stream
  Stream<PaymentModel?> getUserPaymentStream(String userId) async* {
      final Dio _dio = Dio(); // إنشاء كائن Dio

    try {
        String url =
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/payments/$userId?key=$apiKey';
      while (true) {
        Response response = await _dio.get(
          url,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        if (response.statusCode == 200) {
          // إذا كانت الاستجابة ناجحة، قم بتحويل البيانات
          yield PaymentModel.fromMap(response.data);
        } else {
          // في حال كانت هناك استجابة غير ناجحة، يمكن إرجاع null أو الاستمرار في محاولة
          yield null;
        }

        // إضافة تأخير زمني بين المحاولات، إذا كنت بحاجة لعمل تدفق مستمر
        await Future.delayed(
            Duration(seconds: 5)); // تأخير 5 ثواني بين المحاولات
      }
    } catch (e) {
      // في حال حدوث خطأ في الاتصال بالـ API
      print("Error fetching payment: $e");
      yield null;
    }
  }

}
