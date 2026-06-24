import 'package:flutter/material.dart';
import 'afis_engine.dart';
import 'database_helper.dart';
import 'sms_codec.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Le chargement natif C++ s'initialise au lancement de l'application
  runApp(const NagglyApp());
}

class NagglyApp extends StatelessWidget {
  const NagglyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naggly OS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AfisEngine _afisEngine = AfisEngine();
  
  void _onScanVache() async {
    // 1. Capture de la photo via la Caméra
    // 2. YOLOv8 TFLite fait le crop (Zone T) sur l'image
    // 3. Appel du C++ OpenCV pour l'extraction des minuties :
    // List<Point> bifurcations = _afisEngine.extractBifurcations(imageBytes, width, height);
    
    // 4. Recherche Locale (SQLite) ou Envoi SMS National
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 Recherche biométrique C++ / SQLite lancée...')),
    );
  }

  void _onReceiveSMS(String smsString) async {
    try {
      // 1. Décodage Lossless instantané
      List<Point> bifurcations = SMSCodec.decode(smsString);
      
      // 2. Lancement de la Triangulation + Recherche SQLite
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💬 SMS Décodé ! Reconstitution de ${bifurcations.length} minuties.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Code SMS invalide')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐮 Naggly OS (Edge AFIS)'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.pets, size: 120, color: Colors.greenAccent),
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, size: 30),
                label: const Text('Scanner une Vache', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _onScanVache,
              ),
              
              const SizedBox(height: 20),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.sms, size: 30),
                label: const Text('Identifier via SMS', style: TextStyle(fontSize: 18)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  foregroundColor: Colors.greenAccent,
                  side: const BorderSide(color: Colors.greenAccent),
                ),
                onPressed: () => _onReceiveSMS("VON_EXEMPLE_DE_CODE_COMPRESSE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
