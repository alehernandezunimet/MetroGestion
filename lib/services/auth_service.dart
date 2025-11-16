import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicia sesión con email y contraseña.
  /// Devuelve un mensaje de error si falla, o null si tiene éxito.
  Future<String?> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Email o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        return 'Formato de email inválido.';
      }
      return 'Ocurrió un error. Intente de nuevo.';
    }
  }

  /// Registra un nuevo usuario.
  /// Devuelve un mensaje de error si falla, o null si tiene éxito.
  Future<String?> registerUser({
    required String email,
    required String password,
    required String nombreCompleto,
    required String rol,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Guardar datos adicionales en Firestore
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'email': email,
        'nombre': nombreCompleto,
        'rol': rol,
        'fechaRegistro': DateTime.now(),
      });

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        return 'Este correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo no es válido.';
      }
      return 'Error al registrar. Intente de nuevo.';
    }
  }

  /// Envía un correo para restablecer la contraseña.
  /// Devuelve un mensaje de error si falla, o null si tiene éxito.
  Future<String?> sendPasswordResetEmail({required String email}) async {
    if (email.isEmpty) {
      return 'Por favor, ingrese su correo electrónico.';
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No existe un usuario con ese correo.';
      } else if (e.code == 'invalid-email') {
        return 'Formato de correo inválido.';
      }
      return 'Error al enviar correo de restablecimiento.';
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}