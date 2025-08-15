// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
// import 'grade1_summary_screen.dart';
// import 'otp_verification_screen.dart';

// class Grade1UploadScreen extends StatefulWidget {
//   final String childFullName;
//   final String dateOfBirth;
//   final String parentName;
//   final String guardianNic;
//   final String contactNumber;
//   final String schoolName;

//   Grade1UploadScreen({
//     required this.childFullName,
//     required this.dateOfBirth,
//     required this.parentName,
//     required this.guardianNic,
//     required this.contactNumber,
//     required this.schoolName,
//   });

//   @override
//   _Grade1UploadScreenState createState() => _Grade1UploadScreenState();
// }

// class _Grade1UploadScreenState extends State<Grade1UploadScreen> {
//   List<File> _files = [];
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickFile() async {
//     final picked = await _picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         _files.add(File(picked.path));
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Upload Documents')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _pickFile,
//               child: Text('Pick File'),
//             ),
//             SizedBox(height: 10),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _files.length,
//                 itemBuilder: (context, index) => ListTile(
//                   title: Text(_files[index].path.split('/').last),
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               child: Text('Next'),
//               onPressed: _files.isEmpty
//                   ? null
//                   : () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Grade1SummaryScreen(
//                             childFullName: widget.childFullName,
//                             dateOfBirth: widget.dateOfBirth,
//                             parentName: widget.parentName,
//                             guardianNic: widget.guardianNic,
//                             contactNumber: widget.contactNumber,
//                             schoolName: widget.schoolName,
//                             files: _files,
//                           ),
//                         ),
//                       );
//                     },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
