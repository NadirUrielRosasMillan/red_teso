enum StudentModality { servicioSocial, residencias, egresado }

class Student {
  final String id;
  final String name;
  final String email;
  final double gpa;
  final String gender;
  final bool speaksEnglish;
  final String career;
  final StudentModality modality;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.gpa,
    required this.gender,
    required this.speaksEnglish,
    required this.career,
    required this.modality,
  });
}
