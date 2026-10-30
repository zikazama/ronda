/// Satu lapis pada pipeline deteksi hibrida 4 lapis.
class DetectionLayer {
  const DetectionLayer({
    required this.order,
    required this.name,
    required this.engine,
    required this.description,
    required this.targetMs,
  });

  final int order;
  final String name;
  final String engine;
  final String description;
  final int targetMs;

  static const pipeline = [
    DetectionLayer(
      order: 1,
      name: 'Offline Filter',
      engine: 'SQLite + Bloom Filter',
      description:
          'Cek 10.000+ hash nomor penipu & kata kunci bahaya di perangkat.',
      targetMs: 10,
    ),
    DetectionLayer(
      order: 2,
      name: 'DB Lookup',
      engine: 'PostgreSQL / Prisma',
      description: 'Cocokkan nomor pengirim dengan laporan komunitas.',
      targetMs: 40,
    ),
    DetectionLayer(
      order: 3,
      name: 'Rule Engine',
      engine: 'Regex & Financial Parser',
      description: 'Pindai file .apk, rekening bank, QRIS, dan link pendek.',
      targetMs: 25,
    ),
    DetectionLayer(
      order: 4,
      name: 'Cognitive AI',
      engine: 'Gemini + Nusantara NLP',
      description: 'Analisis manipulasi psikologis & slang bahasa daerah.',
      targetMs: 300,
    ),
  ];
}
