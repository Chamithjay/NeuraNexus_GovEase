class Grade1Application {
  String childFullName;
  String dateOfBirth;
  String parentName;
  String guardianNic;
  String contactNumber;
  String schoolName;
  List<String> uploadedFiles;

  Grade1Application({
    required this.childFullName,
    required this.dateOfBirth,
    required this.parentName,
    required this.guardianNic,
    required this.contactNumber,
    required this.schoolName,
    required this.uploadedFiles,
  });

  Map<String, String> toMap() {
    return {
      'child_full_name': childFullName,
      'date_of_birth': dateOfBirth,
      'parent_name': parentName,
      'guardian_nic': guardianNic,
      'contact_number': contactNumber,
      'school_name': schoolName,
    };
  }
}
