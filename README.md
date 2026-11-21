<div align="center">

# 👁️‍🗨️ AIrSight

**Aplicación móvil accesible impulsada por Inteligencia Artificial para el aprendizaje de vocabulario en inglés (Nivel A1) dirigida a estudiantes con discapacidad visual.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Google AI Studio](https://img.shields.io/badge/Google_AI_Studio-Gemini_Flash-4285F4?style=for-the-badge&logo=googlegemini&logoColor=white)](https://aistudio.google.com/)
[![WCAG 2.2](https://img.shields.io/badge/Accesibilidad-WCAG_2.2-2E7D32?style=for-the-badge&logo=accessibility&logoColor=white)](https://www.w3.org/WAI/standards-guidelines/wcag/)

</div>

---

##  Sobre el Proyecto

**AIrSight** nace como un proyecto de grado enfocado en reducir las barreras de accesibilidad en el aprendizaje de una segunda lengua. La aplicación transforma el entorno físico del estudiante en un aula interactiva: permite capturar objetos de la vida cotidiana mediante la cámara del dispositivo, analizarlos con IA multimodal y guiar el aprendizaje de su pronunciación y escritura en inglés (**nivel A1**).

###  Características Principales

*  **Interacción 100% Guiada por Voz:** Integración nativa de *Text-to-Speech (TTS)* y *Speech-to-Text (STT)* para navegar, escuchar instrucciones y practicar pronunciación sin depender de la pantalla.
*  **Reconocimiento Multimodal de Objetos:** Uso de **Gemini Flash** (a través de **Google AI Studio**) para analizar las imágenes capturadas por la cámara, identificar objetos del entorno y generar definiciones contextualizadas en inglés básico.
*  **Retroalimentación Háptica Inteligente:** Patrones de vibración diferenciados que confirman aciertos, errores y estados de escucha para una experiencia táctil intuitiva.
*  **Diseño Centrado en Accesibilidad (WCAG 2.2):** Interfaz de alto contraste, áreas táctiles amplias, etiquetas semánticas compatibles con lectores de pantalla (TalkBack) y navegación simplificada.
*  **Aprendizaje Gamificado:** Progreso estructurado por retos y seguimiento de vocabulario almacenado en la nube.

---

## Stack Tecnológico

| Categoría | Tecnología | Propósito en el proyecto |
| :--- | :--- | :--- |
| **Frontend Móvil** | Flutter & Dart (Android) | Desarrollo multiplataforma nativo y gestión de accesibilidad UI. |
| **IA Multimodal** | Gemini Flash API (Google AI Studio) | Reconocimiento visual de objetos, generación de vocabulario A1 y retroalimentación. |
| **Base de Datos** | Cloud Firestore (Firebase) | Persistencia de progreso del usuario, historial y métricas de aprendizaje. |
| **Accesibilidad & Audio** | Flutter TTS, Speech-to-Text, Haptics | Síntesis de voz, reconocimiento de pronunciación y respuesta táctil. |
| **Testing & QA** | Flutter Test & Mockito | Pruebas unitarias y de integración para el servicio de Gemini y flujos de voz. |

---

## Cómo Clonar y Ejecutar el Proyecto

Sigue estos pasos para levantar el entorno de desarrollo en tu máquina local:

### 1. Prerrequisitos
* [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y configurado en el `PATH`.
* Android Studio / VS Code con soporte para Android.
* Una clave de API generada en **Google AI Studio** y un proyecto configurado en **Firebase**.

### 2. Clonar el repositorio
```bash
git clone [https://github.com/JGMoony/AIrSight.git](https://github.com/JGMoony/AIrSight.git)
cd AIrSight
