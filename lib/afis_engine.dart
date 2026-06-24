import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// Signature C de la fonction du fichier C++
typedef ProcessNagglyAfisC = Int32 Function(Pointer<Uint8> imageBytes, Int32 width, Int32 height, Pointer<Int32> outX, Pointer<Int32> outY);
// Signature Dart
typedef ProcessNagglyAfisDart = int Function(Pointer<Uint8> imageBytes, int width, int height, Pointer<Int32> outX, Pointer<Int32> outY);

class AfisEngine {
  late DynamicLibrary _lib;
  late ProcessNagglyAfisDart _processAfis;

  AfisEngine() {
    // Charge le module C++ compilé
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libnaggly_afis.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Plateforme non supportée pour l\'AFIS C++');
    }

    // Lie la fonction
    _processAfis = _lib.lookupFunction<ProcessNagglyAfisC, ProcessNagglyAfisDart>('process_naggly_afis');
  }

  /// Extrait instantanément les minuties en appelant OpenCV C++
  List<Point> extractBifurcations(Uint8List imageBytes, int width, int height) {
    // 1. Allocation de la mémoire pour l'image (copie vers le C++)
    final Pointer<Uint8> imgPtr = malloc.allocate<Uint8>(imageBytes.length);
    imgPtr.asTypedList(imageBytes.length).setAll(0, imageBytes);

    // 2. Allocation pour les résultats (jusqu'à 1000 bifurcations max)
    final Pointer<Int32> outX = malloc.allocate<Int32>(1000 * sizeOf<Int32>());
    final Pointer<Int32> outY = malloc.allocate<Int32>(1000 * sizeOf<Int32>());

    // 3. Appel C++ natif (Zéro latence ! Le calcul se fait dans OpenCV)
    final count = _processAfis(imgPtr, width, height, outX, outY);

    // 4. Récupération des résultats en Dart
    List<Point> bifurcations = [];
    for (int i = 0; i < count; i++) {
      bifurcations.add(Point(outX[i], outY[i]));
    }

    // 5. Libération de la mémoire pour éviter les fuites
    malloc.free(imgPtr);
    malloc.free(outX);
    malloc.free(outY);

    return bifurcations;
  }
}

class Point {
  final int x, y;
  Point(this.x, this.y);
}
