import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/local_user_storage.dart';
import '../../features/auth/auth_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream reactivo de estado de sesión para AuthGate
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario autenticado actual
  User? get currentUser => _auth.currentUser;

  /// Registro de usuario con Correo y Contraseña
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name.trim();

    // 1. Crear credencial en el servicio de autenticación
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final user = userCredential.user;
    if (user != null) {
      // 2. Asignar el nombre en el perfil
      await user.updateDisplayName(cleanName);

      // 3. Persistir el perfil y rol en Firestore (Colección users)
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': cleanName,
          'email': cleanEmail,
          'role': role,
          'authProvider': 'password',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Advertencia al guardar usuario en Firestore: $e');
      }

      // 4. Actualizar la caché local para compatibilidad en la app
      await LocalUserStorage.registerUser(
        AuthUser(
          name: cleanName,
          email: cleanEmail,
          password: '',
          role: role,
        ),
      );
    }

    return userCredential;
  }

  /// Inicio de sesión con Correo y Contraseña
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final userCredential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final user = userCredential.user;
    if (user != null) {
      await _syncUserProfile(user, fallbackRole: 'student');
    }

    return userCredential;
  }

  /// Inicio de sesión con Google Sign-In con logging detallado para diagnóstico
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Iniciando Google Sign-In...');

      // 1. Iniciar el flujo interactivo de selección de cuenta de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si el usuario canceló el diálogo modal de Google
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelado por el usuario.');
        return null;
      }

      debugPrint('Cuenta seleccionada: ${googleUser.email}');

      // 2. Obtener los tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint(
        'Tokens recibidos -> idToken disponible: ${googleAuth.idToken != null}, '
        'accessToken disponible: ${googleAuth.accessToken != null}',
      );

      // 3. Crear la credencial con los tokens recibidos
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en el servicio de autenticación
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        debugPrint(
          'Autenticación con Google exitosa. UID: ${user.uid}, isNewUser: $isNewUser',
        );
        await _syncUserProfile(
          user,
          fallbackRole: 'student',
          providerName: 'google',
        );
      }

      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('Error detallado Google Sign-In: $e');
      if (e is PlatformException) {
        debugPrint(
          'Código: ${e.code}, Mensaje: ${e.message}, Detalles: ${e.details}',
        );
      }
      debugPrint('StackTrace Google Sign-In: $stackTrace');
      rethrow;
    }
  }

  /// Sincroniza los datos del usuario en Firestore y en caché local
  Future<void> _syncUserProfile(
    User user, {
    String fallbackRole = 'student',
    String providerName = 'password',
  }) async {
    String role = fallbackRole;
    String name =
        user.displayName ?? (user.email?.split('@').first ?? 'Estudiante');

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        role = doc.data()!['role'] ?? fallbackRole;
        name = doc.data()!['name'] ?? name;
      } else {
        // Si el usuario no existía en Firestore (ej. primer login con Google), se crea
        await docRef.set({
          'uid': user.uid,
          'name': name,
          'email': user.email ?? '',
          'role': role,
          'authProvider': providerName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Sincronización Firestore con fallback: $e');
    }

    await LocalUserStorage.registerUser(
      AuthUser(
        name: name,
        email: user.email ?? '',
        password: '',
        role: role,
      ),
    );
  }

  /// Envío de correo para restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  /// Cierre de sesión completo
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    await LocalUserStorage.logout();
  }

  /// Traducción descriptiva y accesible de excepciones a lenguaje natural (WCAG 2.2 AA)
  static String getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya se encuentra registrado. Por favor inicia sesión.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta registrada con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos. Verifica tus credenciales.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada. Contacta al soporte.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Por seguridad, inténtalo más tarde.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión a internet e inténtalo de nuevo.';
      case 'operation-not-allowed':
        return 'El método de autenticación no está habilitado actualmente.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo asociada a otro método de inicio de sesión.';
      default:
        return 'Ocurrió un error al autenticar: ${e.message ?? e.code}';
    }
  }
}
