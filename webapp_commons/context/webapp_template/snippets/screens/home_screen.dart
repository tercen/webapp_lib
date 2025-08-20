import 'package:flutter/material.dart';
import '../../../../model/id_label.dart';
import '../../widgets/tooltip_widget.dart';
import '../../../../service/api_service.dart';
import '../../../../service/project_service.dart';
import '../styles.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _projectController = TextEditingController();
  final FocusNode _projectFocusNode = FocusNode();

  
  List<IdLabel> _projects = [];
  List<IdLabel> _teams = [];
  IdLabel _selectedTeam = IdLabel(id: "", label: "", kind: "team");
  List<String> _filteredProjectNames = [];
  bool _isLoading = false;
  bool _showAutocomplete = false;
  String hovered = "";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _projectController.addListener(_onProjectTextChanged);
    _projectFocusNode.addListener(_onProjectFocusChanged);
  }

  @override
  void dispose() {
    _projectController.dispose();
    _projectFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadProjectsForTeam(String teamName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await ProjectService().fetchProjects(teamName, filterByOwner: true);
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
      
      // Don't clear the project input field when team changes
      // Update the autocomplete dropdown based on new projects
      _onProjectTextChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Failed to load projects: ${e.toString()}');
      }
    }
  }


  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teams = await ApiService().fetchTeamsForCurrentUser();
      final selectedTeam = ProjectService().hasProject ? ProjectService().projectOwner : teams.first.id;
      
      // Load projects for the selected team
      final projects = await ProjectService().fetchProjects(selectedTeam);
      
      setState(() {
        _projects = projects;
        _teams = teams;
        _selectedTeam = IdLabel(id: selectedTeam, label: selectedTeam);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        //TODO Move error dialog to a top level error processing, or, at least, use a generic error handling class
        _showErrorDialog('Failed to load initial data: ${e.toString()}');
      }
    }
  }


  void _onProjectTextChanged() {
    final text = _projectController.text.toLowerCase();
    setState(() {
      if (text.isEmpty) {
        // Show all projects when field is empty but focused
        _filteredProjectNames = _projects.map((project) => project.label ).where((name) => name.isNotEmpty).toList();
        _showAutocomplete = _projectFocusNode.hasFocus && _filteredProjectNames.isNotEmpty;
      } else {
        // Filter projects when user types
        _filteredProjectNames = _projects
            .where((project) => project.label.toLowerCase().contains(text))
            .map((project) => project.label)
            .toList();
        _showAutocomplete = _filteredProjectNames.isNotEmpty;
      }
    });
  }

  void _onProjectFocusChanged() {
    if (_projectFocusNode.hasFocus) {
      // Show autocomplete when field gains focus
      _onProjectTextChanged();
    } else {
      // Add a small delay to allow tap to register before hiding autocomplete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_projectFocusNode.hasFocus) {
          setState(() {
            _showAutocomplete = false;
          });
        }
      });
    }
  }

  void _selectProjectFromAutocomplete(String projectName) {
    // Force the text update and hide autocomplete
    _projectController.text = projectName;
    setState(() {
      _showAutocomplete = false;
    });
    
    // Remove focus to prevent autocomplete from reopening
    _projectFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final mainContentWidth = screenSize.width * 0.99;
    
    return Container(
      constraints: BoxConstraints(
        minHeight: screenSize.height * 0.7,
      ),
      child: Column(
        children: [
          // Row 1: Project
          _buildRow(
            context,
            mainContentWidth,
            [
              _buildProjectLabel(),
              _buildProjectInput(),
              _buildEmptyWidget(),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Row 2: Team
          _buildRow(
            context,
            mainContentWidth,
            [
              _buildTeamLabel(),
              _buildTeamSelector(),
              _buildEmptyWidget(),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Row 3: Load Project Button
          _buildRow(
            context,
            mainContentWidth,
            [
              _buildLoadProjectButton(),
              _buildEmptyWidget(),
              _buildEmptyWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, double totalWidth, List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Column 1: 10% minimum, 12% maximum
        Container(
          constraints: BoxConstraints(
            minWidth: totalWidth * 0.10,
            maxWidth: totalWidth * 0.12,
          ),
          alignment: Alignment.centerLeft,
          child: children[0],
        ),
        
        const SizedBox(width: 20),
        
        // Column 2: 25% maximum
        Container(
          constraints: BoxConstraints(
            maxWidth: totalWidth * 0.25,
          ),
          alignment: Alignment.centerLeft,
          child: children[1],
        ),
        
        const SizedBox(width: 20),
        
        // Column 3: Remainder
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: children[2],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Project',
          style: Styles.labelStyle,
        ),
        const SizedBox(width: 4),
        const TooltipWidget(
          message: 'If project does not exist, a new one will be created.',
        ),
      ],
    );
  }

  Widget _buildProjectInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(
            minWidth: 200,
            maxWidth: 300,
          ),
          child: TextField(
            controller: _projectController,
            focusNode: _projectFocusNode,
            decoration: const InputDecoration(
              hintText: 'Project Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (value) {
              if (_showAutocomplete && _filteredProjectNames.isNotEmpty) {
                _selectProjectFromAutocomplete(_filteredProjectNames[0]);
              }
            },
            onChanged: (value) {
              // Handle text changes for autocomplete
            },
          ),
        ),
        if (_showAutocomplete) _buildAutocompleteDropdown(),
      ],
    );
  }

  Widget _buildAutocompleteDropdown() {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 300,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
        color: Styles.appBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _filteredProjectNames.map((name) {
          return MouseRegion(
            onEnter: (_) => setState(() => hovered = name),
            onExit: (_) => setState(() => hovered = ""),
            child: GestureDetector(
              onTap: () {
                _selectProjectFromAutocomplete(name);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hovered == name ? Styles.inactiveBackground.withOpacity(0.1) : Colors.transparent,
                ),
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamLabel() {
    return Text(
      'Team',
      style: Styles.labelStyle,
    );
  }

  Widget _buildTeamSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _selectedTeam.label.isEmpty ? 'No team selected' : _selectedTeam.label,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showTeamDialog,
          child: const Icon(
            Icons.group,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadProjectButton() {
    return ElevatedButton(
      onPressed: _loadProject,
      style: Styles.buttonStyle,
      child: const Text('Load Project'),
    );
  }

  Widget _buildEmptyWidget() {
    return const SizedBox.shrink();
  }


  Future<void> _showTeamDialog() async {
    String searchQuery = '';
    var filteredTeams = List.from(_teams);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Team'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search teams...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchQuery = value.toLowerCase();
                        
                        filteredTeams = _teams
                            .where((team) => team.label.toLowerCase().contains(searchQuery))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredTeams.length,
                      itemBuilder: (context, index) {
                        final team = filteredTeams[index];
                        return ListTile(
                          title: Text(team.name),
                          selected: _selectedTeam == team,
                          onTap: () async {
                            setState(() {
                              _selectedTeam = team;
                            });
                            Navigator.of(context).pop();
                            
                            // Load projects for the newly selected team
                            await _loadProjectsForTeam(team.name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadProject() async {
    final projectName = _projectController.text.trim();
    
    if (projectName.isEmpty) {
      _showErrorDialog('Please enter a project name.');
      return;
    }

    // Check if project exists
    final projectExists = await ProjectService().projectExists(projectName, _selectedTeam.id);

    if (!projectExists) {
      // Project doesn't exist, show confirmation dialog
      final shouldCreate = await _showCreateProjectDialog();
      if (!shouldCreate) return;
    }

    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up Project'),
            ],
          ),
        ),
      );
    }

    try {
      // Simulate project loading
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        _showSuccessDialog('Project loaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        _showErrorDialog('Failed to load project: ${e.toString()}');
      }
    }
  }

  Future<bool> _showCreateProjectDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: const Text('This will create a new project'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}