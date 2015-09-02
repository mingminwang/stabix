% Copyright 2013 Max-Planck-Institut f�r Eisenforschung GmbH
function gui_handle = A_gui_plotmap
%% Function used to create the GUI

% authors: d.mercier@mpie.de / c.zambaldi@mpie.de

%% Initialization
if isempty(getenv('SLIP_TRANSFER_TBX_ROOT')) == 1
    errordlg('Run the path_management.m script !', 'File Error');
    return
end

%% Set GUI
gui = interface_map_init;

%% Check if MTEX is installed
if ishandle(1)
    gui_main = guidata(1);
    if isfield(gui_main, 'flag')
        if isfield(gui_main.flag, 'installation_mtex')
            if gui_main.flag.installation_mtex == 1
                gui_main_flag = 1;
                gui.flag.installation_mtex = 1;
            else
                gui_main_flag = 0;
            end
        else
            gui_main_flag = 0;
        end
    else
        gui_main_flag = 0;
    end
else
    gui_main_flag = 0;
end

if ~gui_main_flag
    gui.flag.installation_mtex = mtex_check_install;
end

%% Initialization
gui.rdm_TSL_dataset = 0;
gui.flag.newDataFlag = 0;
gui.tol.Tol_angle = 0;
gui.tol.Tol_angle_old = 0;
gui.COORDSYS_eulers = coordinate_convention(0);
gui.calculations.func2plot = 1;
gui.flag.pmparam2plot_value4Grains = 0;
gui.flag.pmparam2plot_value4GB = 0;
gui.flag.pmparam2plot_value4GB_old = 0;
gui.flag.pmparam2plot_value4GB_functype = 0;
gui.flag.pmparam2plot_value4GB_functype_old = 0;
gui.flag.pmlistsslips_ph1_old = 0;
gui.flag.pmlistsslips_ph2_old = 0;
gui.flag.pm_ph1_old = 0;
gui.flag.pm_ph2_old = 0;
gui.flag.pm_NumPh_old = 0;
gui.flag.pm_mat1_old = 0;
gui.flag.pm_mat2_old = 0;
gui.flag.initialization_axis = 1;

%% Importation of data from YAML config file (samples, paths...)
gui.config_map = interface_map_load_YAML_config_file;

gui.config_map.path_to_ebsd_dataExamples = fullfile(get_stabix_root, ...
    'A_gui_plotmap', 'ebsd_dataExamples', '');

%% Importation of data from YAML config file (paths of TSL data)
config_YAML_TSLdata = sprintf('config_gui_EBSDmap_data_path_%s.yaml', ...
    gui.config.username);

if exist(config_YAML_TSLdata, 'file') == 0
    %gui.config_map = struct();
else
    config_map_TSLOIM_data_path = ReadYaml(config_YAML_TSLdata);
    gui.config_map.TSLOIM_data_path_GF2 = ...
        config_map_TSLOIM_data_path.TSLOIM_data_path_GF2;
    gui.config_map.TSLOIM_data_path_RB  = ...
        config_map_TSLOIM_data_path.TSLOIM_data_path_RB;
end

if ~isfield(gui.config_map, 'TSLOIM_data_path_GF2')
    gui.config_map.TSLOIM_data_path_GF2 = ...
        gui.config_map.path_to_ebsd_dataExamples;
end

if ~isfield(gui.config_map, 'TSLOIM_data_path_RB')
    gui.config_map.TSLOIM_data_path_RB = ...
        gui.config_map.path_to_ebsd_dataExamples;
end

%% Window Coordinates Configuration
scrsize = screenSize;   % Get screen size
WX = 0.30 * scrsize(3); % X Position (bottom)
WY = 0.10 * scrsize(4); % Y Position (left)
WW = 0.65 * scrsize(3); % Width
WH = 0.75 * scrsize(4); % Height

x0 = 0.02;
%hu = 0.05; % height unit
wu = 0.3; % width unit

%% Window configuration
gui.handles.TSLinterfWindow = figure('NumberTitle', 'off',...
    'Color', [0.9 0.9 0.9],...
    'toolBar', 'figure',...
    'Position', [WX WY WW WH]);

gui.title_str = set_gui_title(gui, '');

gui.handles.gcf = gui.handles.TSLinterfWindow;
gui_handle = gui.handles.TSLinterfWindow;

%% Customized menu
interface_map_custom_menu;

%% Choice of material and sample
[gui.handles.Choice_material_title, gui.handles.Choice_material_pm] = ...
    set_popupmenu('Material_ID', [0.02 0.97 0.13 0.02], ...
    1, gui.config_map.Material_IDs, ['gui = guidata(gcf);'...
    'gui.config_map.Material_ID = gui.config_map.Material_IDs(get('...
    'gui.handles.Choice_material_pm, ''Value''));' ...
    'guidata(gcf, gui)']);

if isa(gui.config_map.Material_IDs, 'cell') == 1 ...
        || isa(gui.config_map.Material_ID, 'cell') == 1
    set(gui.handles.Choice_material_pm, 'Value', ...
        find(cell2mat(strfind(gui.config_map.Material_IDs, ...
        gui.config_map.Material_ID))));
end

[gui.handles.Choice_sample_title, gui.handles.Choice_sample_pm] = ...
    set_popupmenu('Sample_ID', [0.16 0.97 0.13 0.02], ...
    1, gui.config_map.Sample_IDs, ['gui = guidata(gcf);' ...
    'gui.config_map.Sample_ID = gui.config_map.Sample_IDs(get(' ...
    'gui.handles.Choice_sample_pm, ''Value''));' ...
    'guidata(gcf, gui)']);

if isa(gui.config_map.Sample_IDs, 'cell') == 1 ...
        || isa(gui.config_map.Sample_ID, 'cell') == 1
    set(gui.handles.Choice_sample_pm, 'Value', ...
        find(cell2mat(strfind(gui.config_map.Sample_IDs, ...
        gui.config_map.Sample_ID))));
end

%% Buttons to create random TSL data
gui.handles.cb_rdm_TSLdata = set_checkbox('Random TSL data', ...
    [0.3 0.97 0.1 0.02], 0, 'interface_map_set_random_data(1);');

gui.handles.scale_rdm_TSLdata = uicontrol(...
    'Units', 'normalized',...
    'Style', 'slider',...
    'Min', 6, 'Max', 200, 'Value', 97,...
    'Position', [0.3 0.94 0.1 0.03],...
    'visible', 'off',...
    'Callback', 'interface_map_set_random_data(2);');

%% Buttons to browse in files
gui.handles.pbFileGF2 = set_pushbutton('1) Import Grain File Type 2', ...
    [0.02 0.91 0.2 0.03], ['gui = guidata(gcf);' ...
    'open_file_GF2();' ...
    'set(gui.handles.Eul_title, ''BackgroundColor'', [1 0 0]);' ...
    'set(gui.handles.pmcoordsyst, ''BackgroundColor'', [1 0 0]);']);

gui.handles.FileGF2 = uicontrol(...
    'Units', 'normalized',...
    'Style', 'edit',...
    'Position', [0.02 0.88 0.2 0.03],...
    'String', 'validation_grain_file_type2.txt');

gui.handles.pbFileRB = set_pushbutton('2) Import Reconstr. Bound. File', ...
    [0.02 0.85 0.2 0.03], ['gui = guidata(gcf);' ...
    'open_file_RB();' ...
    'set(gui.handles.Eul_title, ''BackgroundColor'', [1 0 0]);' ...
    'set(gui.handles.pmcoordsyst, ''BackgroundColor'', [1 0 0]);']);

gui.handles.FileRB = uicontrol(...
    'Units', 'normalized',...
    'Style', 'edit',...
    'Position', [0.02 0.82 0.2 0.03],...
    'String', 'validation_reconstructed_boundaries.txt');

set([gui.handles.FileGF2, gui.handles.FileRB], ...
    'BackgroundColor', [0.9 0.9 0.9],...
    'HorizontalAlignment', 'left');

%% Buttons to import EBSD data using import_wizard
gui.handles.pbFileScanData = set_pushbutton('...or import EBSD file with MTEX', ...
    [0.02 0.76 0.2 0.05], ['gui = guidata(gcf);' ...
    'if gui.flag.installation_mtex == 1;', ...
    'mtex_getEBSDdata;', ...
    'try;',...
    'gui.ebsdMTEX = ebsd; guidata(gcf, gui);', ...
    'mtex_setEBSDdata;', ...
    'catch;', ...
    ['warning_commwin(''Please reload your data and save ',...
    'it as a variable named ebsd !'');'],...
    'end;',...
    'else warning_commwin(''MTEX not installed!'');', ...
    'end;']);

%% Pull-down to select coordinate system
[gui.handles.Eul_title, gui.handles.pmcoordsyst] = ...
    set_popupmenu('Coord. Syst.', [0.23 0.91 0.06 0.02], ...
    1, listCoordSys, ['gui = guidata(gcf);' ...
    'interface_map_set_coordinate_convention;' ...
    'set(gui.handles.Eul_title, ''BackgroundColor'', [0.9 0.9 0.9]);' ...
    'set(gui.handles.pmcoordsyst, ''BackgroundColor'', [0.9 0.9 0.9]);']);

%% Setting of Scale Unit
[gui.handles.Unit_title, gui.handles.pm_unit] = set_popupmenu('Unit', ...
    [0.23 0.85 0.06 0.02], 2, listLengthUnit, 'interface_map_plotmap(0);');

%% Settings of phase / material / slip families
h = uibuttongroup('visible','on', 'Position',[x0 0.49 wu 0.23]);

% Setting of the number of Phases (1 or 2)
[gui.handles.NumPh_title, gui.handles.NumPh] = set_inputs_boxes(...
    'Number of Phases', [0.02 0.73 0.14 0.02], '2', '', 0.75);

% Plot and Setting of Material and Structure
str_callbackMatStr1 = ['gui = guidata(gcf);' ...
    'material = get_value_popupmenu(gui.handles.pmMat1, listMaterial);' ...
    'phase = get_value_popupmenu(gui.handles.pmStruct1, listPhase);'];

str_callbackMatStr2 = ['gui = guidata(gcf);' ...
    'material = get_value_popupmenu(gui.handles.pmMat2, listMaterial);' ...
    'phase = get_value_popupmenu(gui.handles.pmStruct2, listPhase);'];

str_callbackMat = ['[lattice_parameters, flag_error] = ' ...
    'check_material_phase(material, phase);' ...
    'if ~flag_error;' ...
    'set(gui.handles.pmparam2plot4GB, ''Value'', 1);' ...
    'set(gui.handles.pmparam2plot4Grains, ''Value'', 1);' ...
    'gui.flag.new_slip_families = 1;' ...
    'guidata(gcf, gui);' ...
    'interface_map_plotmap;'...
    'end'];

str_callbackStruct = ['[lattice_parameters, flag_error] = ' ...
    'check_material_phase(material, phase);' ...
    'if ~flag_error;', ...
    'set(gui.handles.pmparam2plot4GB, ''Value'', 1);' ...
    'set(gui.handles.pmparam2plot4Grains, ''Value'', 1);' ...
    'gui.flag.new_slip_families = 1;' ...
    'guidata(gcf, gui);' ...
    'interface_map_plotmap(1,1);' ...
    'end',];

callback_material_1 = [str_callbackMatStr1, str_callbackMat];
callback_material_2 = [str_callbackMatStr2, str_callbackMat];
callback_slipstwins_1 = [str_callbackMatStr1, str_callbackStruct];
callback_slipstwins_2 = [str_callbackMatStr2, str_callbackStruct];

[gui.handles.Mat1, gui.handles.pmMat1, gui.handles.Struct1,...
    gui.handles.pmStruct1, gui.handles.listslips1, ...
    gui.handles.pmlistslips1] = interface_map_material('#1', ...
    [0.025 0.88 0.45 0.1], ...
    callback_material_1, callback_slipstwins_1, h);

[gui.handles.Mat2, gui.handles.pmMat2, gui.handles.Struct2, ...
    gui.handles.pmStruct2, gui.handles.listslips2, ...
    gui.handles.pmlistslips2] = interface_map_material('#2', ...
    [0.525 0.88 0.45 0.1], ...
    callback_material_2, callback_slipstwins_2, h);

% FIXME --> removed initialization of popupmenu to set slip transmission
% parameter to plot ==> impossible to do a multiple selection of slip
% systems in the list...
%     'set(gui.handles.pmparam2plot4GB, ''Value'', 1);' ...
%     'set(gui.handles.pmparam2plot4Grains, ''Value'', 1);' ...

% callback_material = ['gui = guidata(gcf);' ...
%     'gui.flag.new_slip_families = 1;' ...
%     'guidata(gcf, gui);' ...
%     'interface_map_plotmap;'];
%
% callback_slipstwins = ['gui = guidata(gcf);' ...
%     'gui.flag.new_slip_families = 1;' ...
%     'guidata(gcf, gui);' ...
%     'interface_map_plotmap(1,1);'];
%
% [gui.handles.Mat1, gui.handles.pmMat1, gui.handles.Struct1,...
%     gui.handles.pmStruct1, gui.handles.listslips1, ...
%     gui.handles.pmlistslips1] = interface_map_material('#1', ...
%     [0.025 0.88 0.45 0.1], ...
%     callback_material, callback_slipstwins);
%
% [gui.handles.Mat2, gui.handles.pmMat2, gui.handles.Struct2, ...
%     gui.handles.pmStruct2, gui.handles.listslips2, ...
%     gui.handles.pmlistslips2] = interface_map_material('#2', ...
%     [0.525 0.88 0.45 0.1], ...
%     callback_material, callback_slipstwins);

% To have a bcc phase for material #1 and fcc phase for material #2
set(gui.handles.pmStruct2, 'Value', 2);

%% Stress Tensor
gui.handles.StressTensorStr = uicontrol(...
    'Units', 'normalized',...
    'Style', 'text',...
    'Position', [0.02 0.46 0.11 0.02],...
    'HorizontalAlignment', 'center',...
    'String', 'Stress tensor :');

callback_stress_tensor = ['gui = guidata(gcf);' ...
    'set(gui.handles.pmparam2plot4GB, ''Value'', 1);' ...
    'set(gui.handles.pmparam2plot4Grains, ''Value'', 1);' ...
    'guidata(gcf, gui);' ...
    'interface_map_plotmap(0);'];

gui.handles.stressTensor = set_stress_tensor( ...
    0.02, 0.440, 0.03, 0.02, callback_stress_tensor);

%% GB Map Plot settings
gui.handles.cbgrnum = set_checkbox('Grain Number', ...
    [0.02 0.35 0.12 0.02], 0, 'interface_map_plotmap(0);');

gui.handles.cbgbnum = set_checkbox('GB Number', ...
    [0.02 0.33 0.12 0.02], 0, 'interface_map_plotmap(0);');

gui.handles.cbphase = set_checkbox('Phase', ...
    [0.02 0.31 0.12 0.02], 0, 'interface_map_plotmap(0);');

gui.handles.cbunitcell = set_checkbox('Unit Cells', ...
    [0.02 0.29 0.12 0.02], 1, 'interface_map_plotmap(0);');

gui.handles.cbdatavalues = set_checkbox('Plot of values', ...
    [0.02 0.27 0.12 0.02], 0, 'interface_map_plotmap(0);');

gui.handles.cbsliptraces = set_checkbox('Plot of Slip Traces', ...
    [0.15 0.35 0.12 0.02], 1, 'interface_map_plotmap(0);');

listpm = {'None'; ...
    'm'' (highest values)'; ...
    'm'' (lowest values)';...
    'm'' with slips with highest Schmid factors'; ...
    'm'' with slips with highest resolved shear stress';...
    'Max-10% of highest values of m'''; ...
    'Min+10% of lowest values of m''';...
    'Misorientation';'C-axis Misor.';...
    'Max residual Burgers vector'; ...
    'Min residual Burgers vector';...
    'N-factor max'; ...
    'N-factor min';...
    'lambda max'; ...
    'lambda min';...
    'Max GB Schmid Factor';...
    'Other Function'};

[gui.handles.param2Scale4GBs, gui.handles.pmparam2plot4GB] = ...
    set_popupmenu('GB parameter to plot', [0.02 0.24 0.12 0.02], ...
    1, listpm, 'interface_map_plotmap(1,1);');

listpm = {'None';...
    'Slip with highest Generalized Schmid Factor';...
    'Slip with highest Resolved Shear Stress';...
    'Plot of slip trace for Slip with highest Generalized Schmid Factor'};

[gui.handles.param2Scale4Grains, gui.handles.pmparam2plot4Grains] = ...
    set_popupmenu('Grain parameter to plot', [0.15 0.24 0.12 0.02], ...
    1, listpm, 'interface_map_plotmap(1,1);');

%% Legend of slip traces (colors used for slips plotted inside unit cells for each grain)
gui.handles.pmlegend = uicontrol(...
    'Units', 'normalized',...
    'Style', 'popupmenu',...
    'Position', [0.15 0.33 0.12 0.02],...
    'Value', 2,...
    'Callback', 'interface_map_plotmap(0);');

%% Scalebar for the size of unit cells
gui.handles.scale_unitcell_str = uicontrol(...
    'Units', 'normalized',...
    'Style', 'text',...
    'Position', [0.15 0.29 0.12 0.02],...
    'String', 'Size of Unit Cells');

gui.handles.scale_unitcell_bar = uicontrol(...
    'Units', 'normalized',...
    'Style', 'slider',...
    'Min', 0, 'Max', 2, 'Value', 1,...
    'Position', [0.15 0.27 0.12 0.02],...
    'Callback', 'interface_map_plotmap(0);');

%% Plot of a specific bicrystal
[gui.handles.GB2plot, gui.handles.numGB2plot] = set_inputs_boxes(...
    'GB number to plot', [0.02 0.16 0.12 0.02], '1', '', 0.7);

gui.handles.pbGBplot = set_pushbutton('PLOT BICRYSTAL', ...
    [0.15 0.15 0.12 0.045], 'A_gui_plotGB_Bicrystal(guidata(gcf));');

%% GB and Grain numbers
[gui.handles.Grain_totalnumber_title, gui.handles.Grain_totalnumber_value] ...
    = set_inputs_boxes('Number of Grains :', [0.42 0.97 0.13 0.02], ...
    '', '', 0.8);

[gui.handles.GB_totalnumber_title, gui.handles.GB_totalnumber_value] = ...
    set_inputs_boxes('Number of GBs :', [0.42 0.94 0.13 0.02], ...
    '', '', 0.8);

%% Scalebar for the number of total grain boundaries (smoothing)
gui.handles.scale_gb_segments_str = uicontrol(...
    'Units', 'normalized',...
    'Style', 'text',...
    'Position', [0.42 .91 0.13 0.02],...
    'String', 'Grain boundaries smoothing');

gui.handles.scale_gb_segments_bar = uicontrol(...
    'Units', 'normalized',...
    'Style', 'slider',...
    'Min', 0, 'Max', 180, 'Value', 0,...
    'Position', [0.42 .89 0.13 0.02],...
    'Callback', 'interface_map_plotmap(1,1);');

%% Button to save new GBs dataset (after smoothing for example)
gui.handles.pbsave_newGBs = set_pushbutton('SAVE GBs', ...
    [0.75 0.93 0.13 0.03], 'interface_map_save_TSL_data;');

%% Setting of microstructure map Axis...
[gui.handles.titlecolorbar, gui.handles.pmcolorbar] = ...
    set_popupmenu('Style of Colorbar', [0.57 0.97 0.13 0.02], ...
    1, listColormap, 'interface_map_plotmap(0);');

[gui.handles.titlecolorbar_loc, gui.handles.pmcolorbar_loc] = ...
    set_popupmenu('Location of Colorbar', [0.57 0.92 0.13 0.02], ...
    5, listLocation, 'interface_map_plotmap(0);');

%% Date
gui.handles.date_str_interface = uicontrol(...
    'Units', 'normalized',...
    'Style', 'text',...
    'String', datestr(datenum(clock),'mmm.dd,yyyy HH:MM'),...
    'Position', [0.75 0.97 0.13 0.025]);

%% Save figure
gui.handles.pbsavefigure = set_pushbutton('SAVE FIGURE', ...
    [0.75 0.89 0.13 0.03], ['gui = guidata(gcf);' ...
    'save_figure(gui.config_map.pathname_reconstructed_boundaries_file,' ...
    'gui.handles.AxisGBmap); set(gui.handles.TSLinterfWindow,' ...
    '''Color'', [1 1 1]*.9);']);

%% EBSD Map
gui.handles.PlotMapAxis = axes('Position', [0.94 0.94 0.02 0.02]);

gui.handles.AxisGBmap = axes('Position', [0.375 0.078 0.6 0.75]);

set(gcf, 'CurrentAxes', gui.handles.AxisGBmap);

%% Clear all & Save & Quit & Help
gui.handles.pbhelp = set_pushbutton('HELP', ...
    [0.02 0.09 0.19 0.05], ['gui = guidata(gcf);' ...
    'webbrowser(gui.config.doc_path_root);']);

gui.handles.pbclearall = set_pushbutton('RESET', ...
    [0.02 0.03 0.06 0.05], 'close_windows(gcf); A_gui_plotmap;');

gui.handles.pbsav = set_pushbutton('SAVE DATA', ...
    [0.085 0.03 0.06 0.05], 'uisave();');

gui.handles.pbclose = set_pushbutton('CLOSE', ...
    [0.15 0.03 0.06 0.05], 'close_windows(gcf);');

%% Encapsulation of data
gui.flag.initialization_axis = 1;
guidata(gcf, gui);

%% Set materials and slips families
interface_map_material_definition;
interface_map_list_slips(gui.handles.pmStruct1, gui.handles.pmStruct2, ...
    gui.handles.pmlistslips1, gui.handles.pmlistslips2, 2, 1, 1);

%% Initialization of the EBSD map interface
interface_map_set_coordinate_convention;

set(gui.handles.pmparam2plot4GB, 'Value', 2);
interface_map_plotmap(1,1);

%% Encapsulation of data
gui = guidata(gcf); guidata(gcf, gui);

%% Set logo of the GUI
java_icon_gui;

end