import 'package:intl/intl.dart';
import 'package:webapp_utils/functions/logger.dart';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:webapp_utils/functions/string_utils.dart';
import 'package:webapp_utils/services/app_user.dart';
import 'package:webapp_utils/services/project_data_service.dart';

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
  sci.FolderDocument? _folder;

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

  Future<String> getFolderId() async {
    if (_folder == null) {
      try {
        _folder = await _getOrCreateFolder();
      } catch (e) {
        throw sci.ServiceError(
            500, "folder.getOrCreate", "Error creating or getting folder: $e");
      }
      _folder = await _getOrCreateFolder();
    }
    return _folder!.id;
  }

  Future<String> getFolderName() async {
    if (_folder == null) {
      try {
        _folder = await _getOrCreateFolder();
      } catch (e) {
        throw sci.ServiceError(
            500, "folder.getOrCreate", "Error creating or getting folder: $e");
      }
      _folder = await _getOrCreateFolder();
    }
    return _folder!.name;
  }

  Future<sci.FolderDocument> _getOrCreateFolder() async {
    if (_folder != null) {
      //Folder has already been created
      return _folder!;
    }

    final factory = tercen.ServiceFactory();
    if (folderId != null && folderId!.isNotEmpty) {
      // Folder ID has been provided, just return the folder
      final folderNode = ProjectDataService()
          .folderTreeRoot
          .getNodeInDescendantsByDocId(folderId!);
      if (folderNode == null) {
        throw sci.ServiceError(404, "folder.get",
            "Folder with ID $folderId not found in the project.");
      }
      return folderNode.document as sci.FolderDocument;
    }
    if (folderName == null &&
        nRandomChars == 0 &&
        addTimestamp == false &&
        prefixes.isEmpty &&
        suffixes.isEmpty) {
      // Will not create a new folder, return the parent folder ID
      final folderNode = ProjectDataService()
          .folderTreeRoot
          .getNodeInDescendantsByDocId(parentFolderId);
      if (folderNode == null) {
        throw sci.ServiceError(404, "folder.get",
            "Folder with ID $folderId not found in the project.");
      }
      return folderNode.document as sci.FolderDocument;
    }

    final folderNameFinal = _buildFolderName();

    //Search for existing folder with the same name
    final folderCheck =
        await _checkIfFolderExists(parentFolderId, folderNameFinal);
    if (folderCheck.id.isNotEmpty) {
      Logger().log(
          level: Logger.FINER,
          message: "Folder $folderNameFinal already exists, reusing it.");
      return folderCheck;
    }

    Logger()
        .log(level: Logger.FINER, message: "Creating folder $folderNameFinal.");
    final folder = sci.FolderDocument()
      ..name = folderNameFinal
      ..acl = (sci.Acl()..owner = AppUser().teamname)
      ..projectId = AppUser().projectId
      ..folderId = parentFolderId;

    metas.forEach((meta) {
      folder.addMeta(meta.key, meta.value);
    });

    return await factory.folderService.create(folder);
  }

  Future<sci.FolderDocument> _checkIfFolderExists(
      String parentId, String folderName) async {
    return ProjectDataService().getFolder(folderName, parentId: parentId) ??
        sci.FolderDocument();
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
