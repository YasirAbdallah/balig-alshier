// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'package:skeletonizer/skeletonizer.dart';

class UrlImageDisplayer extends StatefulWidget {
  final String? imageUrl;

  const UrlImageDisplayer({super.key, required this.imageUrl});

  @override
  _UrlImageDisplayerState createState() => _UrlImageDisplayerState();
}

class _UrlImageDisplayerState extends State<UrlImageDisplayer> {
  File? cachedImageFile; // ملف الصورة المحفوظة مؤقتًا
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      loadImage(widget.imageUrl!);
    }
  }

  Future<void> loadImage(String imageUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      // التحقق إذا كانت الصورة محفوظة في الكاش مسبقاً
      final cachedFile = await _getCachedImageFile(imageUrl);
      if (cachedFile.existsSync()) {
        setState(() {
          cachedImageFile = cachedFile; // استخدم الملف من الكاش
        });
      } else {
        // تحميل الصورة من الرابط وحفظها في الكاش
        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200) {
          cachedFile
              .writeAsBytesSync(response.data); // حفظ البيانات في الملف المؤقت
          setState(() {
            cachedImageFile = cachedFile;
          });
        } else {
          if (kDebugMode) {
            print(
              "Failed to download image. Status code: ${response.statusCode}");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading image: $e");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  } 

  // الحصول على ملف الصورة من الكاش باستخدام اسم فريد يعتمد على الرابط
  Future<File> _getCachedImageFile(String imageUrl) async {
    final dir = await getTemporaryDirectory();
    final fileName = imageUrl.split('/').last;
    final filePath = "${dir.path}/$fileName";
    return File(filePath);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) {
      return const SizedBox(); // إذا لم يكن هناك رابط، عرض مربع فارغ
    } else if (isLoading) {
      return _buildSkeleton(
          context); // عرض عظام تحميل إذا كانت الصورة تحت التحميل
    } else if (cachedImageFile != null) {
      return GestureDetector(
        onTap: () => _showPhotoViewer(cachedImageFile!),
        child:  Container(
            width: double.infinity, // استخدام عرض كامل المساحة
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), // حواف دائرية
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 2), // تأثير الظل
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8), // حواف دائرية
              child: Image.file(
                cachedImageFile!,
                fit: BoxFit.cover, // ملاءمة الصورة لملء الـ Container
              ),
            ),
          ),
      );
    } else {
      return _buildSkeleton(context); // عرض عظام تحميل إذا لم يكن هناك صورة
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        width: double.infinity, // يأخذ كامل العرض
        height: 200, // ارتفاع اختياري (يمكنك تغييره حسب احتياجك)
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  
  void _showPhotoViewer(File imageUrl) {
    Get.dialog(
      Dialog(
        child: PhotoView(
          imageProvider: FileImage(
            imageUrl,
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}
