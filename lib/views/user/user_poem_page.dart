import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poem_app/app_widgets.dart';
import 'package:poem_app/controllers/auth_controller.dart';
import 'package:poem_app/controllers/poem_controller.dart';
import 'package:poem_app/models/poem_model.dart';
import 'package:poem_app/views/user/poem_info_stream_page.dart';
import 'package:poem_app/views/user/user_line_details.dart';
import 'package:poem_app/views/user/user_notification_screen.dart';
import 'package:poem_app/views/user/user_pay_page.dart';
import 'package:poem_app/views/user/user_search_page.dart';

class UserPoemPage extends StatelessWidget {
  final UserController _userController = Get.put(UserController());
  final PoemController poemController = Get.put(PoemController());

  UserPoemPage({super.key}) {
    poemController.checkIfUserUpgraded();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  Get.to(UserSearchPage());
                },
                icon: const Icon(
                  Icons.search,
                  size: 30,
                  color: metallicBlue,
                ),
              ),
            )
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD700), // اللون الذهبي الأساسي
                  Color(0xFFFFC107), // لون ذهبي أفتح
                  Color(0xFFFFD700), // لون برتقالي ذهبي
                  Color(0xFFCC8400), // لون ذهبي داكن
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: const CustomTitleText(
            text: 'بليغ الشعر',
          ),
        ),
        drawer: _buildDrawer(context),
        body: Obx(
          () {
            if (poemController.isUpgraded.value) {
              return _buildPoemContent(poemController.getPoemStream(), context);
            } else {
              return _buildPoemContent(
                  poemController.getPoemFreeStream(), context);
            }
          },
        ),
      ),
    );
  }

  // بناء Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(
            () {
              var userInfo = _userController.currentUser;
              return DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD700), // اللون الذهبي الأساسي
                      Color(0xFFFFC107), // لون ذهبي أفتح
                      Color(0xFFFFD700), // لون برتقالي ذهبي
                      Color(0xFFCC8400), // لون ذهبي داكن
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(userInfo?.photoURL ?? ''),
                    ),
                    const SizedBox(height: 5),
                    CustomBodyText(
                      text: userInfo?.username ?? 'Guest',
                    ),
                    const SizedBox(height: 3),
                    CustomBodyText(
                      text: userInfo?.email ?? '',
                    ),
                  ],
                ),
              );
            },
          ),
          Card(
            margin: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // اللون الذهبي الأساسي
                    Color(0xFFFFC107), // لون ذهبي أفتح
                    Color(0xFFFFD700), // لون برتقالي ذهبي
                    Color(0xFFCC8400), // لون ذهبي داكن
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.info,
                  color: Color(0xFF32527B),
                ),
                title: const CustomBodyText(
                  text: 'معلومات حول القصيدة',
                ),
                onTap: () {
                  Get.back();
                  Get.to(PoemInfoStreamPage(
                    poem: poemController.poem,
                  ));
                },
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // اللون الذهبي الأساسي
                    Color(0xFFFFC107), // لون ذهبي أفتح
                    Color(0xFFFFD700), // لون برتقالي ذهبي
                    Color(0xFFCC8400), // لون ذهبي داكن
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.account_circle,
                  color: Color(0xFF32527B),
                ),
                title: const CustomBodyText(
                  text: 'ترقية الحساب',
                ),
                onTap: () {
                  Get.back();
                  Get.to(UserPayPage());
                },
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // اللون الذهبي الأساسي
                    Color(0xFFFFC107), // لون ذهبي أفتح
                    Color(0xFFFFD700), // لون برتقالي ذهبي
                    Color(0xFFCC8400), // لون ذهبي داكن
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF32527B),
                ),
                title: const CustomBodyText(
                  text: 'الإشعارات',
                ),
                onTap: () {
                  var userInfo = _userController.currentUser;
                  Get.back();
                  Get.to(UserNotificationScreen(
                    userId: userInfo!.uid,
                  ));
                },
              ),
            ),
          ),
          // زر تسجيل الخروج
          Card(
            margin: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // اللون الذهبي الأساسي
                    Color(0xFFFFC107), // لون ذهبي أفتح
                    Color(0xFFFFD700), // لون برتقالي ذهبي
                    Color(0xFFCC8400), // لون ذهبي داكن
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF32527B)),
                title: const CustomBodyText(
                  text: 'تسجيل الخروج',
                ),
                onTap: () async {
                  await _userController.signOut(); // استدعاء دالة تسجيل الخروج
                  Get.back(); // الرجوع للقائمة الجانبية
                  Get.offNamed('/'); // أو أي صفحة تانية بعد تسجيل الخروج
                },
              ),
            ),
          ),
          // نص ترقية الحساب في الأسفل
          poemController.isUpgraded.value 
          ?
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: CustomBodyText(
                text: 'قم بترقية حسابك للوصول لكامل أبيات القصيدة',
              ),
            ),
          )
          : const SizedBox(),
        ],
      ),
    );
  }

  // بناء محتوى القصيدة
  Widget _buildPoemContent(Stream<Poem?> poemStream, BuildContext context) {
    return Obx(
      () {
        if (poemController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (!poemController.isPoemInfoAdded.value) {
          return const Center(
              child: CustomBodyText(text: 'لا توجد معلومات متاحة'));
        } else {
          return StreamBuilder<Poem?>(
            stream: poemStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                    child: CustomBodyText(text: 'حدث خطأ: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                    child: CustomBodyText(text: 'لا توجد قصيدة متاحة'));
              } else {
                final Poem poem = snapshot.data!;
                return ListView.builder(
                  itemCount: poem.lines!.length,
                  itemBuilder: (context, index) {
                    final line = poem.lines![index];
                    final lineNumber = index + 1;
                    return Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700), // اللون الذهبي الأساسي
                                Color(0xFFFFC107), // لون ذهبي أفتح
                                Color(0xFFFFD700), // لون برتقالي ذهبي
                                Color(0xFFCC8400), // لون ذهبي داكن
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            onTap: () {
                              Get.to(UserLineDetailsPage(
                                line: line,
                                lineIndex: index,
                              ));
                            },
                            title: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomBodyText(
                                        text: line.hemistich1,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                  const SizedBox(height: 17),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      CustomBodyText(
                                        text: line.hemistich2,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                  CustomBodyText(
                                    text: '(${lineNumber.toString()})',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}
