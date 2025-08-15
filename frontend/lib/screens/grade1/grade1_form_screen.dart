// import 'package:flutter/material.dart';
// import 'grade1_upload_screen.dart';

// class Grade1FormScreen extends StatefulWidget {
//   final String schoolName;
//   Grade1FormScreen({required this.schoolName});

//   @override
//   _Grade1FormScreenState createState() => _Grade1FormScreenState();
// }

// class _Grade1FormScreenState extends State<Grade1FormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String childFullName = '';
//   String dateOfBirth = '';
//   String parentName = '';
//   String guardianNic = '';
//   String contactNumber = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Application Form')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Child Full Name'),
//                 onSaved: (val) => childFullName = val ?? '',
//                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
//                 onSaved: (val) => dateOfBirth = val ?? '',
//                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Parent/Guardian Name'),
//                 onSaved: (val) => parentName = val ?? '',
//                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Guardian NIC Number'),
//                 onSaved: (val) => guardianNic = val ?? '',
//                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Contact Number'),
//                 onSaved: (val) => contactNumber = val ?? '',
//                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 child: Text('Next'),
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     _formKey.currentState!.save();
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => Grade1UploadScreen(
//                           childFullName: childFullName,
//                           dateOfBirth: dateOfBirth,
//                           parentName: parentName,
//                           guardianNic: guardianNic,
//                           contactNumber: contactNumber,
//                           schoolName: widget.schoolName,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
