class FeaturedStudent {
  final String id;
  final String name;
  final String career;
  final double gpa;
  final String roleInCourse; // e.g. "Instructor Líder", "Desarrollador Demo"
  final String avatarUrl;

  FeaturedStudent({
    required this.id,
    required this.name,
    required this.career,
    required this.gpa,
    required this.roleInCourse,
    required this.avatarUrl,
  });

  factory FeaturedStudent.fromMap(Map<String, dynamic> map) {
    return FeaturedStudent(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      career: map['career'] ?? 'Ing. en Sistemas Computacionales',
      gpa: (map['gpa'] ?? 8.5).toDouble(),
      roleInCourse: map['roleInCourse'] ?? 'Alumno Colaborador',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'career': career,
      'gpa': gpa,
      'roleInCourse': roleInCourse,
      'avatarUrl': avatarUrl,
    };
  }
}

class CourseClip {
  final String id;
  final String title;
  final String subtitle;
  final String videoUrl;
  final String thumbnailUrl;
  final String courseId;
  final String courseTitle;
  final int likes;

  CourseClip({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.courseId,
    required this.courseTitle,
    this.likes = 124,
  });
}

class CourseModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String duration;
  final String price;
  final String level;
  final String bannerUrl;
  final double rating;
  final List<FeaturedStudent> featuredStudents;
  final List<CourseClip> clips;

  CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.price,
    required this.level,
    required this.bannerUrl,
    this.rating = 4.9,
    required this.featuredStudents,
    required this.clips,
  });
}
