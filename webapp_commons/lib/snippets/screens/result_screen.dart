// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:html' as html;
// import 'dart:typed_data';
// import '../styles.dart';
// import '../service/tercen_service.dart';
// import '../models/project_object.dart';

// class ResultScreen extends StatefulWidget {
//   const ResultScreen({super.key});

//   @override
//   State<ResultScreen> createState() => _ResultScreenState();
// }

// class _ResultScreenState extends State<ResultScreen> {
//   final TercenService _tercenService = TercenService();
//   final Styles _styles = Styles();
  
//   List<ProjectObject> _projectObjects = [];
//   String? _selectedLeafId;
//   bool _isLoading = false;
//   Map<String, bool> _expandedNodes = {};
  
//   // Sample images for demo - in real app these would come from selected analysis
//   final List<String> _sampleImages = [
//     'assets/img/test/Figure_1.png',
//     'assets/img/test/Figure_2.png',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final projectObjects = await _tercenService.fetchProjectObjects();
      
//       setState(() {
//         _projectObjects = projectObjects;
//         _isLoading = false;
//         // Expand root nodes by default
//         for (var obj in projectObjects) {
//           if (obj.parentId == null) {
//             _expandedNodes[obj.id] = true;
//           }
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       if (mounted) {
//         _showErrorDialog('Failed to load project objects: ${e.toString()}');
//       }
//     }
//   }

//   List<ProjectObject> _getChildren(String parentId) {
//     return _projectObjects.where((obj) => obj.parentId == parentId).toList();
//   }

//   List<ProjectObject> _getRootObjects() {
//     return _projectObjects.where((obj) => obj.parentId == null).toList();
//   }

//   bool _isLeaf(String id) {
//     return _getChildren(id).isEmpty;
//   }

//   void _toggleExpansion(String id) {
//     setState(() {
//       _expandedNodes[id] = !(_expandedNodes[id] ?? false);
//     });
//   }

//   void _selectLeaf(String id) {
//     if (_isLeaf(id)) {
//       setState(() {
//         _selectedLeafId = _selectedLeafId == id ? null : id;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     final screenSize = MediaQuery.of(context).size;
//     final mainContentWidth = screenSize.width * 0.99;
    
//     return Container(
//       constraints: BoxConstraints(
//         minHeight: screenSize.height * 0.7,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Column 1: Analysis List and Images
//           Container(
//             constraints: BoxConstraints(
//               minWidth: mainContentWidth * 0.30,
//               maxWidth: mainContentWidth * 0.50,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Row 1: Analysis List Label
//                 Text(
//                   'Analysis List',
//                   style: _styles.labelStyle,
//                 ),
                
//                 const SizedBox(height: 20),
                
//                 // Row 2: Hierarchical List
//                 Container(
//                   constraints: const BoxConstraints(
//                     maxHeight: 300,
//                   ),
//                   child: SingleChildScrollView(
//                     child: _buildHierarchicalList(),
//                   ),
//                 ),
                
//                 const SizedBox(height: 15), // Row 3: Vertical spacing
                
//                 // Row 4: Image Gallery
//                 if (_selectedLeafId != null) ...[
//                   Text(
//                     'Images',
//                     style: _styles.labelStyle,
//                   ),
//                   const SizedBox(height: 10),
//                   SizedBox(
//                     height: 120,
//                     child: _buildImageGallery(),
//                   ),
//                 ],
//               ],
//             ),
//           ),
          
//           const SizedBox(width: 20),
          
//           // Column 2: Empty (Remainder)
//           Expanded(
//             child: Container(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHierarchicalList() {
//     final List<Widget> nodes = [];
//     int rowIndex = 0;
    
//     void buildNodesRecursively(List<ProjectObject> objects, int level) {
//       for (var obj in objects) {
//         nodes.add(_buildTreeNode(obj, level, rowIndex));
//         rowIndex++;
        
//         final isExpanded = _expandedNodes[obj.id] ?? false;
//         if (!_isLeaf(obj.id) && isExpanded) {
//           buildNodesRecursively(_getChildren(obj.id), level + 1);
//         }
//       }
//     }
    
//     buildNodesRecursively(_getRootObjects(), 0);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: nodes,
//     );
//   }

//   Widget _buildTreeNode(ProjectObject obj, int level, int rowIndex) {
//     final isLeaf = _isLeaf(obj.id);
//     final isExpanded = _expandedNodes[obj.id] ?? false;
//     final isSelected = _selectedLeafId == obj.id;
    
//     // Alternating row colors: even rows white, odd rows light blue
//     final backgroundColor = rowIndex % 2 == 0 ? Colors.white : Colors.blue.shade50;

//     return Container(
//       color: backgroundColor,
//       padding: EdgeInsets.only(left: level * 20.0 + 8, right: 8, top: 8, bottom: 8),
//       child: Row(
//             children: [
//               // Expansion/Checkbox area
//               SizedBox(
//                 width: 24,
//                 child: isLeaf
//                     ? Checkbox(
//                         value: isSelected,
//                         onChanged: (value) {
//                           _selectLeaf(obj.id);
//                         },
//                       )
//                     : IconButton(
//                         icon: Icon(
//                           isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
//                           size: 20,
//                         ),
//                         onPressed: () => _toggleExpansion(obj.id),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),
//               ),
              
//               const SizedBox(width: 8),
              
//               // Object name
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () {
//                     if (isLeaf) {
//                       _selectLeaf(obj.id);
//                     } else {
//                       _toggleExpansion(obj.id);
//                     }
//                   },
//                   child: Text(
//                     obj.name,
//                     style: TextStyle(
//                       fontSize: 17, // Increased by 3 points from 14 to 17
//                       fontWeight: (!isLeaf || isSelected) ? FontWeight.bold : FontWeight.normal,
//                       color: isSelected ? Colors.blue : Colors.black,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//   }

//   Widget _buildImageGallery() {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: _sampleImages.length,
//       itemBuilder: (context, index) {
//         final imagePath = _sampleImages[index];
//         return Container(
//           margin: const EdgeInsets.only(right: 8),
//           child: GestureDetector(
//             onTap: () => _showImageDialog(imagePath),
//             child: Container(
//               width: 100,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(4),
//                 child: Image.asset(
//                   imagePath,
//                   width: 100,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     // Fallback for when assets don't exist
//                     return Container(
//                       width: 100,
//                       height: 80,
//                       color: Colors.grey.shade200,
//                       child: const Icon(
//                         Icons.image,
//                         color: Colors.grey,
//                         size: 40,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _showImageDialog(String imagePath) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.8,
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header with download button
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.download),
//                       onPressed: () => _downloadImage(imagePath),
//                       tooltip: 'Download Image',
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Image content
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Image.asset(
//                     imagePath,
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 400,
//                         height: 300,
//                         color: Colors.grey.shade200,
//                         child: const Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.image,
//                               color: Colors.grey,
//                               size: 64,
//                             ),
//                             SizedBox(height: 8),
//                             Text('Image not available'),
//                           ],
//                         ),
//                       );
//                     },
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _downloadImage(String imagePath) async {
//     try {
//       // Load the image asset as bytes
//       final ByteData imageData = await rootBundle.load(imagePath);
//       final Uint8List bytes = imageData.buffer.asUint8List();
      
//       // Extract filename from path
//       final String fileName = imagePath.split('/').last;
      
//       // Create blob and download link for web
//       final html.Blob blob = html.Blob([bytes]);
//       final String url = html.Url.createObjectUrlFromBlob(blob);
      
//       // Create download link and trigger download
//       final html.AnchorElement anchor = html.AnchorElement(href: url)
//         ..setAttribute('download', fileName)
//         ..style.display = 'none';
      
//       html.document.body?.children.add(anchor);
//       anchor.click();
//       html.document.body?.children.remove(anchor);
      
//       // Clean up the object URL
//       html.Url.revokeObjectUrl(url);
      
//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Downloaded: $fileName'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       // Show error message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to download image: ${e.toString()}'),
//             duration: const Duration(seconds: 3),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }