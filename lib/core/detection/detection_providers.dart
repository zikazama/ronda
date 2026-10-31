import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/reputation.dart';
import '../../features/report/application/community_reporter.dart';
import '../../features/report/application/report_service.dart';
import '../cloud/cloud_gateway.dart';
import '../geo/geo_index.dart';
import '../geo/location_service.dart';
import 'cognitive_analyzer.dart';
import 'detection_pipeline.dart';
import 'spam_directory.dart';
import 'threat_list_store.dart';

final spamDirectoryProvider = Provider<SpamDirectory>(
  (ref) => FirestoreSpamDirectory(ref.watch(cloudGatewayProvider)),
);

final cognitiveAnalyzerProvider = Provider<CognitiveAnalyzer>(
  (ref) => GeminiAnalyzer(ref.watch(cloudGatewayProvider)),
);

final detectionPipelineProvider = Provider<DetectionPipeline>(
  (ref) => DetectionPipeline(
    store: ref.watch(threatListStoreProvider),
    directory: ref.watch(spamDirectoryProvider),
    analyzer: ref.watch(cognitiveAnalyzerProvider),
  ),
);

final communityReporterProvider = Provider<CommunityReporter>(
  (ref) => CommunityReporter(ref.watch(cloudGatewayProvider)),
);

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(
    store: ref.watch(threatListStoreProvider),
    reporter: ref.watch(communityReporterProvider),
    reputation: ref.read(reputationProvider.notifier),
    location: ref.watch(locationServiceProvider),
    geo: () => ref.read(geoIndexProvider),
  ),
);
