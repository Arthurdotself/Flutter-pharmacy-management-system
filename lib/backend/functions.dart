import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'dart:io';


late String userEmail;
late String pharmacyId;
late String lang ='';


//-------------------------fecth sells-------------------------------
void setUserEmail(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  userEmail = userProvider.userId;
  pharmacyId = userProvider.PharmacyId;
  lang = userProvider.lang;
}

Future<List<Map<String, dynamic>>> fetchSellsData( {String? selectedDate}) async {
  selectedDate ??= DateTime.now().toString().substring(0, 10);; // Use current date if no date is provided

  try {
    if (selectedDate == '0') {
      // Retrieve all sells
      QuerySnapshot sellsQuerySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .get();

      List<Map<String, dynamic>> allSellsData = [];
      for (QueryDocumentSnapshot doc in sellsQuerySnapshot.docs) {
        QuerySnapshot dailySellsQuerySnapshot = await doc.reference.collection('dailySells').get();
        dailySellsQuerySnapshot.docs.forEach((dailyDoc) {
          allSellsData.add(dailyDoc.data() as Map<String, dynamic>);
        });
      }
      if (allSellsData.isNotEmpty) {
        return allSellsData;
      } else {
        return [];
      }
    } else if (selectedDate == '7') {
      // Retrieve sells data for the last 7 days
      List<Map<String, dynamic>> sellsData = [];
      for (int i = 0; i < 7; i++) {
        // Calculate the date i days ago
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String dateString = date.toString().substring(0, 10);

        QuerySnapshot dailySellsQuerySnapshot = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(pharmacyId)
            .collection('sells')
            .doc(dateString)
            .collection('dailySells')
            .get();

        dailySellsQuerySnapshot.docs.forEach((doc) {
          sellsData.add(doc.data() as Map<String, dynamic>);
        });
       // print(sellsData);
      }

      if (sellsData.isNotEmpty) {
        return sellsData;
      } else {
        return [];
      }
    } else {
      // Retrieve sells data for the specified date
      QuerySnapshot dailySellsQuerySnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyId)
          .collection('sells')
          .doc(selectedDate)
          .collection('dailySells')
          .get();

      List<Map<String, dynamic>> sellsData = [];
      dailySellsQuerySnapshot.docs.forEach((doc) {
        sellsData.add(doc.data() as Map<String, dynamic>);
      });

      if (sellsData.isNotEmpty) {
        return sellsData;
      } else {
        return [];
      }
    }
  } catch (error) {
    print(error);
    return [];
  }
}


Future<void> sellscanBarcode(BuildContext context) async {
  String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
    '#ff6666', // Scanner overlay color
    'Cancel', // Cancel button text
    true, // Use flash
    ScanMode.BARCODE, // Scan mode
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(getTranslations()['scanned_barcode']!+': $barcodeScanRes'),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );

  _showAddSellDialog(context, barcodeScanRes);
}


void _showAddSellDialog(BuildContext context, String scannedBarcode) async {
  String productName = '';
  double price = 0.0;
  int quantity = 0;
  String selectedExpirationDate = '';
  List<String> expirationDates = [];
  List<dynamic> shipments = [];
  try {
    final docRef = FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('medicines')
        .doc(scannedBarcode);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      productName = data['Name'] ?? '';
      quantity = data['quantity'] ?? 0;

      // Assign value to shipments
      shipments = data['shipments'] ?? [];

      if (shipments.isNotEmpty) {
        expirationDates = shipments.map((shipment) {
          Timestamp expireTimestamp = shipment['expire'];
          return expireTimestamp.toDate().toString();
        }).toList();

        expirationDates.sort((a, b) =>
            DateTime.parse(a).compareTo(DateTime.parse(b)));

        final currentDate = DateTime.now();
        for (final date in expirationDates) {
          final expirationDate = DateTime.parse(date);
          if (expirationDate.isAfter(currentDate)) {
            selectedExpirationDate = date;
            for (final shipment in shipments) {
              Timestamp expireTimestamp = shipment['expire'];
              String expireDate = expireTimestamp.toDate().toString();
              if (expireDate == selectedExpirationDate) {
                price = shipment['price'] != null ? double.parse(
                    shipment['price'].toString()) : 0.0;
                break;
              }
            }
            break;
          }
        }
      }
    }
  } catch (error) {
    print(error);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title:  Text(getTranslations()['add_sell']!),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text(selectedExpirationDate.isNotEmpty
                      ? getTranslations()['product_name']!+': $productName'
                      : getTranslations()['no_product_name_available']!),

                  Text(selectedExpirationDate.isNotEmpty
                      ? getTranslations()['price']!+': $price'
                      : getTranslations()['no_price_available']!),
                  TextFormField(
                    initialValue: '1',
                    decoration:  InputDecoration(
                      labelText: getTranslations()['quantity']!,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 0;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedExpirationDate,
                    decoration:  InputDecoration(
                        labelText: getTranslations()['expire']!),
                    onChanged: (value) {
                      setState(() {
                        selectedExpirationDate = value!;
                        for (final shipment in shipments) {
                          Timestamp expireTimestamp = shipment['expire'];
                          String expireDate = expireTimestamp.toDate()
                              .toString();
                          if (expireDate == selectedExpirationDate) {
                            price = shipment['price'] != null ? double.parse(
                                shipment['price'].toString()) : 0.0;
                            break;
                          }
                        }
                      });
                    },
                    items: expirationDates.map((date) {
                      return DropdownMenuItem(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:  Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  addSell(scannedBarcode, productName, price, quantity,
                      selectedExpirationDate);
                  Navigator.of(context).pop();
                },
                child:  Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

void addSell(String scannedBarcode, String productName, double price,
    int quantity, String expire) async {
  String currentDate = DateTime.now().toString().substring(0, 10);
  try {

    final pharmacySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();
    final pharmacyId = pharmacySnapshot['pharmacyId'];

    final sellRef = FirebaseFirestore.instance
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('sells')
        .doc(currentDate)
        .collection(
        'dailySells') // Create a subcollection to store daily sells
        .doc(); // Automatically generate a unique document ID

    // Add current time
    DateTime currentTime = DateTime.now();

    // Create a new sell document inside the selectedDate document
    await sellRef.set({
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'expire': expire,
      'time': currentTime, // Add current time
      'seller': userEmail
    });
  } catch (error) {
    print(error);
  }
}

DateTime timestampToDate(Timestamp timestamp) {
  return timestamp.toDate();
}

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}

String getDateForPeriod(String period) {
  DateTime today = DateTime.now();
  switch (period) {
    case 'Today':
      return today.toString().substring(0, 10);
    case 'Yesterday':
      DateTime yesterday = today.subtract(Duration(days: 1));
      return yesterday.toString().substring(0, 10);
    case 'All':
      return '0';
    default:
      return '';
  }
}


//-------------------------fecth sells-------------------------------

Future<int> getSellsCount() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('sells').get();
  return snapshot.docs.length;
}

Future<int> countTasks(BuildContext context) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').get();

    int totalTasks = querySnapshot.size;
    int completedTasks = querySnapshot.docs.where((doc) => doc['isCompleted'] == true).length;
    int pendingTasks = totalTasks - completedTasks;

    print('Total tasks: $totalTasks');
    print('Completed tasks: $completedTasks');
    print('Pending tasks: $pendingTasks');

    return pendingTasks; // Return the total number of tasks
  } catch (error) {
    print('Error counting tasks: $error');
    return 0; // Return 0 in case of an error
  }
}

Future<int> getMedicinesCount() async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).collection('medicines').get();

  return snapshot.docs.length;
}

Future<int> getExpiringCount() async {
  // Get today's date
  DateTime now = DateTime.now();

  // Define the start and end dates for the range (e.g., 24 hours before and after today)
  DateTime startDate = DateTime(now.year, now.month, now.day - 1); // 24 hours before today
  DateTime endDate = DateTime(now.year, now.month, now.day + 1); // 24 hours after today

  // Query shipments within the date range
  QuerySnapshot shipmentsSnapshot = await FirebaseFirestore.instance
      .collection('pharmacies')
      .doc(pharmacyId)
      .collection('medicines')
      .where('shipments.date', isGreaterThanOrEqualTo: startDate, isLessThan: endDate)
      .get();

  // Initialize the count of medicines
  int medicinesCount = 0;

  // Iterate over each document in the shipments collection
  for (QueryDocumentSnapshot doc in shipmentsSnapshot.docs) {
    // Get the list of shipments for the current document
    List<dynamic> shipments = doc['shipments'];

    // Iterate over each shipment in the list
    for (dynamic shipment in shipments) {
      // Extract the shipment date
      DateTime shipmentDate = DateTime.parse(shipment['date']);

      // Check if the shipment date is within the specified range
      if (shipmentDate.isAfter(startDate) && shipmentDate.isBefore(endDate)) {
        // Increment the count of medicines associated with this shipment
        medicinesCount++;
      }
    }
  }

  return medicinesCount;
}

Future<void> getImage(ImagePicker picker, ImageSource source) async {
  final pickedFile = await picker.pickImage(source: source);

  if (pickedFile != null) {
    File imageFile = File(pickedFile.path);

    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${userEmail}_avatar.jpg');

      await ref.putFile(imageFile);
      String downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userEmail).update({'photoURL': downloadURL});
    } catch (error) {
      print('Error uploading image: $error');
    }
  }
}

Future<void> uploadImage(BuildContext context) async {
  final ImagePicker picker = ImagePicker(); // Declare _picker here

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Choose Image Source'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              GestureDetector(
                child: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  getImage(picker, ImageSource.camera);
                },
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
              ),
              GestureDetector(
                child: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  getImage(picker, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
class CounterData {
  final String date;
  final int count;

  CounterData(this.date, this.count);
}
//-------------------------dashboard ------------------------------------------------------------


Stream<QuerySnapshot> getTasksStream(BuildContext context) {
  return FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').where('isCompleted', isEqualTo: false).snapshots();
}

Stream<QuerySnapshot> getCompletedTasksStream(BuildContext context) {
  return FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks').where('isCompleted', isEqualTo: true).snapshots();
}
class Task {
  final String documentId; // Add this property to store the document ID
  final String description;
  final String title;

  final bool isCompleted;

  Task({
    required this.documentId,
    required this.description,
    required this.title,
    required this.isCompleted,
  });
}
void toggleTaskCompletion(BuildContext context, Task task) async {
  try {
    CollectionReference tasksCollection = FirebaseFirestore.instance.collection('users').doc(userEmail).collection('tasks');

    await tasksCollection.doc(task.documentId).update({
      'isCompleted': !task.isCompleted,
    });

    if (kDebugMode) {
      print('Task completion status updated successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('Error updating task completion status: $error');
    }
  }
}
//------------------------- language ------------------------------------------------------------
Map<String, String> arabic = {
  'login_screen': 'شاشة تسجيل الدخول',
  'log_in': 'تسجيل الدخول',
  'error': 'خطأ',
  'forgot_password': 'هل نسيت كلمة المرور',
  'sign_up': 'سجل',
  'sign_in_with_google': 'تسجيل الدخول باستخدام جوجل',
  'user_not_found': 'لا يوجد مستخدم مسجل بهذا البريد الإلكتروني.',
  'dashboard': 'لوحة القيادة',
  'medicines': 'الأدوية',
  'add_sells': 'إضافة المبيعات',
  'expiring_expired': 'المنتهية والمنتهية صلاحيتها',
  'patient_profile': 'الملف الشخصي للمريض',
  'tasks': 'المهام',
  'sells_of_last_7_days': 'المبيعات خلال الأيام السبعة الأخيرة',
  'home': 'الصفحة الرئيسية',
  'inventory': 'المخزون',
  'sells': 'المبيعات',
  'notes': 'ملاحظات',
  'settings': 'الإعدادات',
  'logout': 'تسجيل الخروج',
  'search': 'بحث',
  'category': 'الفئة',
  'name': 'الاسم',
  'brand': 'العلامة التجارية',
  'dose': 'الجرعة',
  'quantity': 'الكمية',
  'amount': 'المبلغ',
  'price': 'السعر',
  'cost': 'التكلفة',
  'expire': 'انتهاء الصلاحية',
  'seller': 'البائع',
  'time': 'الوقت',
  'no_sells_data_found_for': 'لم يتم العثور على بيانات مبيعات ل',
  'time_period': 'فترة زمنية',
  'select_language': 'اختر اللغة',
  'change_password': 'تغيير كلمة المرور',
  'current_password': 'كلمة المرور الحالية',
  'enter_current_password': 'أدخل كلمة المرور الحالية الخاصة بك',
  'new_password': 'كلمة المرور الجديدة',
  'enter_new_password': 'أدخل كلمة المرور الجديدة الخاصة بك',
  'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
  'confirm_new_password_description': 'تأكيد كلمة المرور الجديدة الخاصة بك',
  'save_changes': 'حفظ التغييرات',
  'fill_all_fields': 'يرجى ملء جميع الحقول',
  'passwords_do_not_match': 'كلمة المرور الجديدة وتأكيد كلمة المرور غير متطابقين',
  'password_changed_successfully': 'تم تغيير كلمة المرور بنجاح',
  'account': 'الحساب',
  'edit_profile': 'تعديل الملف الشخصي',
  'notifications': 'الإشعارات',
  'receive_notifications': 'تلقي الإشعارات',
  'app_settings': 'إعدادات التطبيق',
  'language': 'اللغة',
  'support': 'الدعم',
  'help_and_feedback': 'المساعدة والملاحظات',
  'contact_support': 'الاتصال بالدعم',
  'report_an_issue': 'الإبلاغ عن مشكلة',
  'provide_feedback': 'تقديم ملاحظات',
  'about': 'حول',
  'log_out': 'تسجيل الخروج',
  'scanned_barcode': 'الباركود الممسوح',
  'no_product_name_available': 'لا يوجد اسم للمنتج متاح',
  'product_name': 'اسم المنتج',
  'no_price_available': 'لا يوجد سعر متاح',
  'cancel': 'إلغاء',
  'save': 'حفظ',
  'add_sell': 'إضافة بيع',
  'unfinished_tasks': 'المهام غير المكتملة',
  'completed_tasks': 'المهام المكتملة',
  'create_new_task': 'إنشاء مهمة جديدة',
  'title': 'العنوان',
  'description': 'الوصف',
  'close': 'إغلاق',
  'sign_up_screen': 'شاشة التسجيل',
  'username': 'اسم المستخدم',
  'email': 'البريد الإلكتروني',
  'create_password': 'إنشاء كلمة المرور',
  're_enter_password': 'إعادة إدخال كلمة المرور',
  'password': 'كلمة المرور',
  'password_reset': 'إعادة تعيين كلمة المرور',
  'enter_email_for_password_reset': 'أدخل البريد الإلكتروني المرتبط بحسابك الذي نسيت كلمة المرور له.',
  'send_reset_password_email': 'إرسال بريد إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
  'password_reset_email_sent': 'تم إرسال بريد إعادة تعيين كلمة المرور بنجاح. تحقق من بريدك الإلكتروني.',
  'success': 'نجاح',
  'enter_email': 'أدخل بريدك الإلكتروني',
  'no_account_found': 'لم يتم العثور على حساب لهذا البريد الإلكتروني.',
  'change_pharmacy': 'تغيير الصيدلية',
  'search_pharmacy': 'البحث عن صيدلية',
  'pharmacy_name': 'اسم الصيدلية',
  'change_email': 'تغيير البريد الإلكتروني',
  'error_updating_email': 'خطأ في تحديث البريد الإلكتروني',
  'email_updated_successfully': 'تم تحديث البريد الإلكتروني بنجاح',
  'confirm': 'تأكيد',
  'expired_medicines': 'الأدوية منتهية الصلاحية',
  'expiring_after': 'تنتهي بعد',
  'expired_since': 'منتهية منذ',
  'add_note': 'إضافة ملاحظة',
  'delete_note': 'حذف الملاحظة',
  'delete': 'حذف',
};

Map<String, String> kurdish = {
  'login_screen': 'په‌نجه‌ره‌ی چوونه‌ژووره‌وه‌',
  'log_in': 'چوونه‌ ژووره‌وه‌',
  'error': 'هه‌ڵه‌',
  'forgot_password': 'تکایه‌ کلیلیت له‌ بیرکاره‌وه‌',
  'sign_up': 'خۆ تۆمارکردن',
  'sign_in_with_google': 'چوونه‌ ژووره‌وه‌ له‌گه‌ڵ جووگڵ',
  'user_not_found': 'هیچ بەکارهێنەرێک لەم پۆستی ئەلکترۆنیەیە نەدۆزرایەوە.',
  'dashboard': 'پانێڵی کاری',
  'medicines': 'دواکان',
  'add_sells': 'زیادکردنی فرۆشتن',
  'expiring_expired': 'پایانی و پایانی کراوە',
  'patient_profile': 'پڕۆفایلی بیمار',
  'tasks': 'کارهەکان',
  'sells_of_last_7_days': 'فرۆشتنەکانی 7 ڕۆژی کۆنەوە',
  'home': 'سەرەتا',
  'inventory': 'مەوجە',
  'sells': 'فرۆشتنەکان',
  'notes': 'تێبینیەکان',
  'settings': 'چەکان',
  'logout': 'دەرچوون',
  'search': 'گەڕان',
  'category': 'هاوپۆل',
  'name': 'ناو',
  'brand': 'مۆدێل',
  'dose': 'دۆز',
  'quantity': 'ژمارە',
  'amount': 'موژی',
  'price': 'نرخ',
  'cost': 'هێنان',
  'expire': 'انتهاء الصلاحية',
  'seller': 'فرۆشەر',
  'time': 'کات',
  'time_period': 'ئێرە زمانی',
  'no_sells_data_found_for': 'هیچ داتای فرۆشتنێک نه‌دۆزرایه‌وه‌ بۆ',
  'select_language': 'زمان دیاری بکە',
  'change_password': 'گۆڕینی تێپەڕەوشە',
  'current_password': 'تێپەڕەوشەی ئێستایی',
  'enter_current_password': 'تکایە تێپەڕەوشەی ئێستاییت داخڵ بکە',
  'new_password': 'تێپەڕەوشەی نوێ',
  'enter_new_password': 'تکایە تێپەڕەوشەی نوێت داخڵ بکە',
  'confirm_new_password': 'دووبارە پێشنیارکردنەوەی تێپەڕەوشەی نوێ',
  'confirm_new_password_description': 'دووبارە پێشنیارکردنەوەی تێپەڕەوشەی نوێت داخڵ بکە',
  'save_changes': 'پاشکه‌وتکردنی گۆڕانکاریەکان',
  'fill_all_fields': 'تکایە هەموو خانە پڕ بکە',
  'passwords_do_not_match': 'تێپەڕەوشەکان ناگۆڕێنەوە',
  'password_changed_successfully': 'تێپەڕەوشە بەسەرکەوتویی گۆڕانکرا',
  'account': 'حیساب',
  'edit_profile': 'دەستکاری پڕۆفایل',
  'notifications': 'ئاگاداریەکان',
  'receive_notifications': 'ئاگاداریەکان هاتووە',
  'app_settings': 'ڕێکخستنەکانی ئەپ',
  'language': 'زمان',
  'support': 'پشتگیری',
  'help_and_feedback': 'یارمەتی و پیشنیار',
  'contact_support': 'پەیوەندی بە پشتگیری',
  'report_an_issue': 'سەرکردنەوەی بەشەک',
  'provide_feedback': 'پیشنیاری بدە',
  'about': 'دەربارە',
  'log_out': 'دەرچوون',
  'scanned_barcode': 'بارکۆدی ماسکرکراو',
  'no_product_name_available': 'هیچ ناوی پرۆدوکتێک بۆ بینین نییە',
  'product_name': 'ناوی پرۆدوکت',
  'no_price_available': 'هیچ نرخێک بۆ بینین نییە',
  'cancel': 'هەڵوەشاندنەوە',
  'save': 'پاشکەوتکردن',
  'add_sell': 'زیادکردنی فرۆشتن',
  'unfinished_tasks': 'کارەکانی نەکتەوانراو',
  'completed_tasks': 'کارەکانی کۆتاییکراو',
  'create_new_task': 'دروستکردنی کارێکی نوێ',
  'title': 'سەردێڕ',
  'description': 'وەسف',
  'close': 'داخستن',
  'sign_up_screen': 'په‌نجه‌ره‌ی تۆمارکردن',
  'username': 'ناوی بەکارهێنەر',
  'email': 'ئیمەیل',
  'create_password': 'وشەی نهێنیی دروست بکە',
  're_enter_password': 'وشەی نهێنیی دووبارە بنووسە',
  'password': 'وشەی نهێنی',
  'password_reset': 'به‌ دوبارەی نهێنی',
  'enter_email_for_password_reset': 'ناونیشانی ئیمه‌یلی خۆت بنوسه‌ بۆ که‌ تۆ به‌ وشه‌ی نهێنیت له‌ بیردەكه‌وە فراموو',
  'send_reset_password_email': 'په‌یامی به‌ دوبارەی نهێنی بنێره‌ بۆ ئیمه‌یلەکه‌ت',
  'password_reset_email_sent': 'په‌یامی به‌ دوبارەی نهێنی بە سه‌رکه‌وتوویی ناردرا. تکایه‌ په‌یامه‌که‌ی ئیمه‌یلی خۆت بپشکنه‌وه‌.',
  'success': 'سەرکەوتوو',
  'enter_email': 'ئیمه‌یله‌که‌ت بنووسه‌',
  'no_account_found': 'هیچ هه‌ژمارێک نه‌دۆزرایه‌وه‌ بۆ ئه‌م ئیمه‌یله‌.',
  'change_pharmacy': 'گۆڕینی دەرمانخانە',
  'search_pharmacy': 'گەڕان لە دەرمانخانە',
  'pharmacy_name': 'ناوی دەرمانخانە',
  'change_email': 'گۆڕینی ئیمەیل',
  'error_updating_email': 'هەڵەی ڕویدا لە نوێکردنی ئیمەیل',
  'email_updated_successfully': 'ئیمەیل بە سەرکەوتوویی نوێکرا',
  'confirm': 'پشتڕین',
  'expired_medicines': 'دواکانی دانەکراو',
  'expiring_after': 'پاشان تەواو بووە',
  'expired_since': 'کەوتوی دانەکراو',
  'add_note': 'زیادکردنی تێبینی',
  'delete_note': 'سڕینەوەی تێبینی',
  'delete': 'سڕینەوە',
};

Map<String, String> english = {
  'login_screen': 'login screen',
  'log_in': 'login',
  'error': 'error',
  'forgot_password': 'forgot password',
  'sign_up': 'sign up',
  'sign_in_with_google': 'sign in with Google',
  'user_not_found': 'No user found for that email.',
  'dashboard': 'Dashboard',
  'medicines': 'Medicines',
  'add_sells': 'Add Sells',
  'expiring_expired': 'Expiring & Expired',
  'patient_profile': 'Patient Profile',
  'tasks': 'Tasks',
  'sells_of_last_7_days': 'Sells of Last 7 Days',
  'home': 'Home',
  'inventory': 'Inventory',
  'sells': 'Sells',
  'notes': 'Notes',
  'settings': 'Settings',
  'logout': 'Logout',
  'search': 'Search',
  'category': 'Category',
  'name': 'Name',
  'brand': 'Brand',
  'dose': 'Dose',
  'quantity': 'Quantity',
  'amount': 'Amount',
  'price': 'Price',
  'cost': 'Cost',
  'expire': 'Expire',
  'seller': 'Seller',
  'time': 'Time',
  'time_period': 'Time Period',
  'no_sells_data_found_for': 'No sells data found for',
  'select_language': 'Select Language',
  'change_password': 'Change Password',
  'current_password': 'Current Password',
  'enter_current_password': 'Enter your current password',
  'new_password': 'New Password',
  'enter_new_password': 'Enter your new password',
  'confirm_new_password': 'Confirm New Password',
  'confirm_new_password_description': 'Confirm your new password',
  'save_changes': 'Save Changes',
  'fill_all_fields': 'Please fill in all fields',
  'passwords_do_not_match': 'New password and confirm password do not match',
  'password_changed_successfully': 'Password changed successfully',
  'account': 'Account',
  'edit_profile': 'Edit Profile',
  'notifications': 'Notifications',
  'receive_notifications': 'Receive Notifications',
  'app_settings': 'App Settings',
  'language': 'Language',
  'support': 'Support',
  'help_and_feedback': 'Help & Feedback',
  'contact_support': 'Contact Support',
  'report_an_issue': 'Report an Issue',
  'provide_feedback': 'Provide Feedback',
  'about': 'About',
  'log_out': 'Log Out',
  'scanned_barcode': 'Scanned Barcode',
  'no_product_name_available': 'No product name available',
  'product_name': 'Product Name',
  'no_price_available': 'No price available',
  'cancel': 'Cancel',
  'save': 'Save',
  'add_sell': 'Add Sell',
  'unfinished_tasks': 'Unfinished Tasks',
  'completed_tasks': 'Completed Tasks',
  'create_new_task': 'Create New Task',
  'title': 'Title',
  'description': 'Description',
  'close': 'Close',
  'sign_up_screen': 'Sign Up Screen',
  'username': 'Username',
  'email': 'Email',
  'create_password': 'Create Password',
  're_enter_password': 'Re-Enter Password',
  'password': 'Password',
  'password_reset': 'Password Reset',
  'enter_email_for_password_reset': 'Enter the Email associated with your account for which you forgot your password.',
  'send_reset_password_email': 'Send a reset password to your email',
  'password_reset_email_sent': 'Password reset email sent successfully. Check your email.',
  'success': 'Success',
  'enter_email': 'Enter your email',
  'no_account_found': 'No Account found for that email.',
  'change_pharmacy': 'Change Pharmacy',
  'search_pharmacy': 'Search Pharmacy',
  'pharmacy_name': 'Pharmacy Name',
  'change_email': 'Change Email',
  'error_updating_email': 'Error updating email',
  'email_updated_successfully': 'Email updated successfully',
  'confirm': 'Confirm',
  'expired_medicines': 'Expired Medicines',
  'expiring_after': 'Expiring After',
  'expired_since': 'Expired since',
  'add_note': 'Add Note',
  'delete_note': 'Delete Note',
  'delete': 'Delete',
};



// Define a function to fetch translations based on the selected language

Map<String, String> getTranslations() {
  // Get the language code from UserProvider
  //String languageCode = lang;

  switch (lang) {
    case 'ar':
      return arabic;
    case 'ku':
      return kurdish;
    case 'en':
      return english;
    default:
      return english;
  }
}
