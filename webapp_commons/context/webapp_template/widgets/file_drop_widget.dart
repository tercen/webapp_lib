import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileDropWidget extends StatefulWidget {
  final PlatformFile? selectedFile;
  final Function(PlatformFile?) onFileSelected;
  final VoidCallback onSelectFile;

  const FileDropWidget({
    super.key,
    this.selectedFile,
    required this.onFileSelected,
    required this.onSelectFile,
  });

  @override
  State<FileDropWidget> createState() => _FileDropWidgetState();
}

class _FileDropWidgetState extends State<FileDropWidget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 250,
        maxWidth: 350,
        minHeight: 100,
        maxHeight: 120,
      ),
      child: GestureDetector(
        onTap: widget.onSelectFile,
        child: DragTarget<String>(
          onWillAccept: (data) {
            setState(() {
              _isDragOver = true;
            });
            return true;
          },
          onLeave: (data) {
            setState(() {
              _isDragOver = false;
            });
          },
          onAcceptWithDetails: (details) {
            setState(() {
              _isDragOver = false;
            });
            _handleFileDrop();
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isDragOver ? Colors.purple : Colors.grey[400]!,
                  style: BorderStyle.solid,
                  width: _isDragOver ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _isDragOver ? Colors.purple.withOpacity(0.1) : Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 40,
                    color: _isDragOver ? Colors.purple : Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        widget.selectedFile?.name ?? 'Drop PDF here or click to select',
                        style: TextStyle(
                          color: _isDragOver ? Colors.purple : Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleFileDrop() {
    // In a real implementation, this would handle the dropped file
    // For now, we'll simulate file selection
    debugPrint('File dropped - would handle drag and drop here');
    widget.onSelectFile();
  }
}