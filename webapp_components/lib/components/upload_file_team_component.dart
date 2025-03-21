import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:webapp_components/components/upload_multi_file_component.dart';
import 'package:webapp_utils/services/file_data_service.dart';

class UploadFile {
  String filename;
  bool uploaded;

  UploadFile(this.filename, this.uploaded);
}

class UploadFileTeamComponent extends UploadFileComponent {
  late final String Function() fileOwnerCallback;
  late final String Function() projectIdCallback;

  UploadFileTeamComponent(super.id, super.groupId, super.componentLabel,
      super.projectId, super.fileOwner,
      {super.folderId = "",
      super.maxHeight = 400,
      super.maxWidth,
      super.allowedMime,
      super.showUploadButton = true,
      super.fetchProjectFiles});

  void setProjectOwnerCallback(
      String Function() projectIdCallback, String Function() ownerCallback) {
    this.projectIdCallback = projectIdCallback;
    fileOwnerCallback = ownerCallback;
  }

  @override
  Future<void> doUpload(BuildContext context) async {
    if (showUploadButton) {
      openDialog(context);
      log("File upload in progress. Please wait.",
          dialogTitle: "File Uploading");
    }

    var fileService = FileDataService();

    for (int i = 0; i < htmlFileList.length; i++) {
      DropzoneFileInterface file = htmlFileList[i];

      if (showUploadButton) {
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }

      var bytes = await dvController.getFileData(file);

      var fileId = await fileService.uploadFile(
          file.name, projectIdCallback(), fileOwnerCallback(), bytes,
          folderId: folderId);

      uploadedFileIds.add(fileId);
      uploadedFilenames.add(file.name);
    }

    for (int i = 0; i < platformFileList.length; i++) {
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      if (showUploadButton) {
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }

      var fileId = await fileService.uploadFile(
          file.name, projectIdCallback(), fileOwnerCallback(), bytes,
          folderId: folderId);
      uploadedFileIds.add(fileId);
      uploadedFilenames.add(file.name);
    }

    notifyListeners();
    if (showUploadButton) {
      closeLog();
    }
  }
}
