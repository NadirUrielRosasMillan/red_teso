import 'package:red_teso/features/courses/domain/models/course_model.dart';

class MockCoursesData {
  static final List<CourseModel> sampleCourses = [
    CourseModel(
      id: 'course_1',
      title: 'Arquitectura Cloud & DevOps con AWS y Kubernetes',
      category: 'Sistemas & Cloud',
      description:
          'Capacitación ejecutiva para empresas enfocada en la modernización de infraestructura, microservicios, CI/CD pipelines y contenedores Docker/Kubernetes con certificación TESOEM.',
      duration: '40 Horas (Modalidad Híbrida)',
      price: '\$14,500 MXN / Empresa',
      level: 'Avanzado',
      bannerUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
      rating: 4.9,
      featuredStudents: [
        FeaturedStudent(
          id: 'student_1',
          name: 'Carlos Eduardo Mendoza',
          career: 'Ing. en Sistemas Computacionales',
          gpa: 9.6,
          roleInCourse: 'Instructor Líder en Kubernetes',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
        ),
        FeaturedStudent(
          id: 'student_2',
          name: 'Valeria Gómez Peña',
          career: 'Ing. en Sistemas Computacionales',
          gpa: 9.4,
          roleInCourse: 'Especialista en CI/CD & Terraform',
          avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300',
        ),
      ],
      clips: [
        CourseClip(
          id: 'clip_1',
          title: 'Despliegue automatizado de clústeres en AWS',
          subtitle: 'Aprende a automatizar pipelines CI/CD corporativos en tiempo récord con nuestros alumnos.',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          thumbnailUrl: 'https://images.unsplash.com/photo-1618401471353-b98afee0b2eb?w=600',
          courseId: 'course_1',
          courseTitle: 'Arquitectura Cloud & DevOps',
          likes: 342,
        ),
        CourseClip(
          id: 'clip_2',
          title: 'Monitoreo en tiempo real con Prometheus',
          subtitle: 'Demostración práctica por alumnos destacados de Sistemas TESOEM.',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          thumbnailUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600',
          courseId: 'course_1',
          courseTitle: 'Arquitectura Cloud & DevOps',
          likes: 289,
        ),
      ],
    ),
    CourseModel(
      id: 'course_2',
      title: 'Inteligencia Artificial Aplicada a Procesos Industriales',
      category: 'IA & Ciencia de Datos',
      description:
          'Curso corporativo para la automatización de decisiones empresariales usando modelos de Machine Learning, Computer Vision y procesamiento de lenguaje natural con Python.',
      duration: '60 Horas (Acreditación Oficial)',
      price: '\$18,900 MXN / Empresa',
      level: 'Avanzado',
      bannerUrl: 'https://images.unsplash.com/photo-1677442136019-21780efad99a?w=800',
      rating: 5.0,
      featuredStudents: [
        FeaturedStudent(
          id: 'student_3',
          name: 'Alejandro Ruiz Peralta',
          career: 'Ing. en Sistemas Computacionales',
          gpa: 9.8,
          roleInCourse: 'Desarrollador de Modelos ML',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        ),
        FeaturedStudent(
          id: 'student_4',
          name: 'Sofia Hernández Vega',
          career: 'Ing. en Sistemas Computacionales',
          gpa: 9.5,
          roleInCourse: 'Especialista en Visión por Computadora',
          avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
        ),
      ],
      clips: [
        CourseClip(
          id: 'clip_3',
          title: 'Detección de defectos industriales en vivo con OpenCV',
          subtitle: 'Mira la demo creada por Sofia Hernández para optimizar calidad en fábricas.',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          thumbnailUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=600',
          courseId: 'course_2',
          courseTitle: 'IA Aplicada a Procesos',
          likes: 512,
        ),
      ],
    ),
    CourseModel(
      id: 'course_3',
      title: 'Ciberseguridad Empresarial & Hacking Ético',
      category: 'Seguridad Informática',
      description:
          'Formación intensiva para auditoría de vulnerabilidades, protección de redes corporativas, Pentesting y cumplimiento de regulaciones ISO 27001.',
      duration: '45 Horas (Certificado TESOEM)',
      price: '\$16,000 MXN / Empresa',
      level: 'Intermedio - Avanzado',
      bannerUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
      rating: 4.8,
      featuredStudents: [
        FeaturedStudent(
          id: 'student_5',
          name: 'Fernando Morales Ramírez',
          career: 'Ing. en Sistemas Computacionales',
          gpa: 9.3,
          roleInCourse: 'Analista de Vulnerabilidades',
          avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
        ),
      ],
      clips: [
        CourseClip(
          id: 'clip_4',
          title: 'Simulación de ataques Ransomware y blindaje',
          subtitle: 'Demo de seguridad preventiva desarrollada por el equipo de ciberseguridad TESOEM.',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          thumbnailUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
          courseId: 'course_3',
          courseTitle: 'Ciberseguridad Empresarial',
          likes: 420,
        ),
      ],
    ),
  ];
}
