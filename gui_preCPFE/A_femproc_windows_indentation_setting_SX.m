% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function gui_handle = A_femproc_windows_indentation_setting_SX(gui_bicrystal, activeGrain, varargin)
%% Setting of indentation inputs (tip radius, indentation depth...) + setting of the mesh for a
% single crystal indentation experiment.
% gui_bicrystal: Handle of the Bicrystal GUI
% activeGrain: Number of the active grain in the Bicrystal

% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

%% Initialization
gui_SX = femproc_init;

x0 = 0.025;
hu = 0.05; % height unit
wu = 0.1; % width unit

%% Window setting
gui_SX.handles.gui_SX_win = figure(...
    'NumberTitle', 'off',...
    'Position', figure_position([.58, .30, .6, .9]), ... % [left, bottom, width, height/width]
    'ToolBar', 'figure');
guidata(gcf, gui_SX);

gui_SX.description = 'Indentation of a single crystal - ';

%% Set Matlab and CPFEM configurations
if nargin == 0  
    %[gui_SX.config] = load_YAML_config_file; % done in init
    
    gui_SX.config_map.Sample_IDs   = [];
    gui_SX.config_map.Sample_ID    = [];
    gui_SX.config_map.Material_IDs = [];
    gui_SX.config_map.Material_ID  = [];
    gui_SX.config_map.default_grain_file_type2 = 'random_GF2data.txt';
    gui_SX.config_map.default_reconstructed_boundaries_file = 'random_RBdata.txt';
    gui_SX.config_map.imported_YAML_GB_config_file = 'config_gui_SX_defaults.yaml';
    
    guidata(gcf, gui_SX);
    femproc_load_YAML_BX_config_file(gui_SX.config_map.imported_YAML_GB_config_file, 1);
    gui_SX = guidata(gcf); guidata(gcf, gui_SX);
    gui_SX.GB.active_data = 'SX';
    gui_SX.title_str = set_gui_title(gui_SX, '');
    
else
    gui_SX.flag           = gui_bicrystal.flag;
    gui_SX.config_map     = gui_bicrystal.config_map;
    gui_SX.config         = gui_bicrystal.config;
    gui_SX.GB             = gui_bicrystal.GB;
    gui_SX.GB.active_data = 'SX';
    if activeGrain == 1
        gui_SX.GB.activeGrain     = gui_SX.GB.GrainA;
    elseif activeGrain == 2
        gui_SX.GB.activeGrain     = gui_SX.GB.GrainB;
    end
    gui_SX.title_str = set_gui_title(gui_SX, ['Crystal n�', num2str(gui_SX.GB.activeGrain)]);
end
gui_SX.config.username = get_username;
guidata(gcf, gui_SX);

%% Customized menu
gui_SX.custom_menu = femproc_custom_menu([gui_SX.module_name,'-SX']);
femproc_custom_menu_SX(gui_SX.custom_menu);

%% Plot the mesh axis
gui_SX.handles.hax = axes('Units', 'normalized',...
    'position', [0.5 0.05 0.49 0.9],...
    'Visible', 'off');

%% Initialization of variables
gui_SX.defaults.variables = ReadYaml('config_mesh_SX_defaults.yaml');

%% Creation of string boxes and edit boxes to set indenter and indentation properties
gui_SX.handles.mesh = femproc_mesh_parameters_SX(gui_SX.defaults, x0, hu, wu);

%% Creation of popup menu and slider for loaded AFM indenter topography
gui_SX.handles.indenter_topo = preCPFE_buttons_AFM_indenter_topo(x0, hu, wu);

%% Pop-up menu to select Python executable
gui_SX.handles.pm_Python = femproc_python_popup([2*x0 hu*2.6 wu*3 hu]);

%% Creation of buttons/popup menus... (mesh quality, layout, Python, CPFEM...)
gui_SX.handles.other_setting = preCPFE_buttons_gui(x0, hu, wu);

%% Set GUI handle encapsulation
guidata(gcf, gui_SX);
gui_SX.config.CPFEM.python_executable = femproc_python_select;
guidata(gcf, gui_SX);

%% Run the plot of the meshing
gui_SX.indenter_type = 'default'; guidata(gcf, gui_SX);
femproc_indentation_setting_SX;
gui_SX = guidata(gcf); guidata(gcf, gui_SX);

gui_handle = gui_SX.handles.gui_SX_win;

end
