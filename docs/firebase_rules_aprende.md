# Reglas de Firebase para AGORA Aprende

El modulo usa colecciones nuevas, todas con prefijo `learning_`.
No toca `courses`, `evaluations`, `users` ni las demas colecciones de red_teso.

IMPORTANTE: estas reglas se AGREGAN a las que ya tienes en la consola. No reemplaces
todo el archivo: pega las funciones y los bloques `match` dentro de
`match /databases/{database}/documents { ... }`.
Si ya tienes funciones con el mismo nombre (por ejemplo `isSignedIn`), reutilizalas.

## Firestore

```
// ---- funciones auxiliares ----
function isSignedIn() {
  return request.auth != null;
}
function userType() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.type;
}
function isAdminUser() {
  return isSignedIn() && userType() == 'admin';
}
function isTeacherUser() {
  return isSignedIn() && (userType() == 'profesor' || userType() == 'admin');
}

// ---- cursos ----
match /learning_courses/{courseId} {
  allow read: if isSignedIn() && (
    resource.data.published == true ||
    resource.data.ownerId == request.auth.uid ||
    isAdminUser()
  );
  allow create: if isTeacherUser() &&
    request.resource.data.ownerId == request.auth.uid;
  allow update: if isSignedIn() && (
    isAdminUser() ||
    (userType() == 'profesor' &&
      resource.data.ownerId == request.auth.uid &&
      request.resource.data.ownerId == request.auth.uid) ||
    // El alumno solo puede sumar 1 al contador de inscritos.
    (userType() == 'alumno' &&
      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['enrolled']) &&
      request.resource.data.enrolled == resource.data.enrolled + 1)
  );
  allow delete: if isSignedIn() && (
    isAdminUser() ||
    (userType() == 'profesor' && resource.data.ownerId == request.auth.uid)
  );
}

// ---- inscripciones y avance ----
match /learning_enrollments/{enrollmentId} {
  allow read: if isSignedIn() && (
    resource.data.userId == request.auth.uid ||
    isAdminUser() ||
    (userType() == 'profesor' &&
      get(/databases/$(database)/documents/learning_courses/$(resource.data.courseId)).data.ownerId == request.auth.uid)
  );
  allow create: if isSignedIn() && userType() == 'alumno' &&
    request.resource.data.userId == request.auth.uid &&
    enrollmentId == request.auth.uid + '_' + request.resource.data.courseId;
  allow update: if isSignedIn() &&
    resource.data.userId == request.auth.uid &&
    request.resource.data.userId == request.auth.uid;
  allow delete: if isAdminUser();
}

// ---- certificados (se consultan por folio) ----
match /learning_certificates/{folio} {
  allow get: if isSignedIn();
  allow list: if isAdminUser();
  allow create: if isSignedIn() && userType() == 'alumno' &&
    request.resource.data.userId == request.auth.uid;
  allow update, delete: if false;
}
```

No se necesitan indices compuestos: todas las consultas usan un solo filtro de igualdad.

## Storage

```
match /learning/{courseId}/{fileName} {
  allow read: if request.auth != null;
  allow write: if request.auth != null &&
    firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.type in ['profesor', 'admin'] &&
    request.resource.size < 200 * 1024 * 1024;
}
```

## Limites que conviene conocer

- Las evaluaciones se califican en el dispositivo y las respuestas correctas viajan
  dentro del documento del curso. Un alumno con conocimientos tecnicos podria
  consultarlas. Es aceptable para un uso academico interno; para examenes de alto
  riesgo se necesitaria calificar en un servidor (Cloud Functions).
- Lo mismo aplica a la emision del certificado: el cliente comprueba los requisitos.
  Las reglas impiden suplantar a otro usuario y editar un certificado ya emitido,
  pero no recalculan el avance.
- Los enlaces de descarga de Storage incluyen un token: quien los tenga puede abrirlos.
