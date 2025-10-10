// import 'package:intl/intl.dart';
// import 'package:webapp_utils/functions/logger.dart';

import 'package:intl/intl.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_core/runner/utils/functions/string_utils.dart';
import 'package:webapp_core/service/project_data_service.dart';
// import 'package:webapp_utils/functions/string_utils.dart';
// import 'package:webapp_utils/services/app_user.dart';
// import 'package:webapp_utils/services/project_data_service.dart';

enum TimestampPosition { prefix, suffix }

class WorkflowFolderConfig {
  final String parentFolderId;
  final String? folderName;
  final String? folderId;
  final bool addTimestamp;
  final String nameJoiner;
  final List<String> prefixes;
  final List<String> suffixes;
  final List<sci.Pair> metas;
  final TimestampPosition timestampPosition;
  late final DateFormat timestampFormat;

  final int nRandomChars;

  WorkflowFolderConfig({
    this.folderId,
    this.parentFolderId = "",
    this.folderName,
    this.addTimestamp = false,
    this.nameJoiner = "_",
    this.prefixes = const [],
    this.suffixes = const [],
    this.metas = const [],
    this.timestampPosition = TimestampPosition.prefix,
    DateFormat? timestampFormat,
    this.nRandomChars = 0,
  }) {
    this.timestampFormat = timestampFormat ?? DateFormat("yyyy.MM.dd");
  }

  Future<String> getFolderId(
      {required String projectId, required String owner}) async {
    return (await  ProjectDataService().getOrCreateFolder(projectId: projectId, folderName: _buildFolderName(), owner: owner)).id;
  }

  Future<String> getFolderName(
      {required String projectId, required String owner}) async {

      return (await  ProjectDataService().getOrCreateFolder(projectId: projectId, folderName: _buildFolderName(), owner: owner)).name;
  }




  String _buildFolderName() {
    final folderNameParts = <String>[];

    if (addTimestamp && timestampPosition == TimestampPosition.prefix) {
      folderNameParts.add(timestampFormat.format(DateTime.now()));
    }

    folderNameParts.addAll(prefixes);

    if (folderName != null && folderName!.isNotEmpty) {
      folderNameParts.add(folderName!);
    }

    if (nRandomChars > 0) {
      folderNameParts.add(StringUtils.getRandomString(nRandomChars));
    }

    folderNameParts.addAll(suffixes);

    if (addTimestamp && timestampPosition == TimestampPosition.prefix) {
      folderNameParts.add(timestampFormat.format(DateTime.now()));
    }
    return folderNameParts.join(nameJoiner);
  }
}
