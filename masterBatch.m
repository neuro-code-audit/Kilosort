addpath(genpath('D:\GitHub\KiloSort2')) % path to kilosort folder
addpath('D:\GitHub\npy-matlab')

pathToYourConfigFile = 'D:\GitHub\KiloSort2\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
run(fullfile(pathToYourConfigFile, 'configFile384.m'))

chanMapList = {'neuropixPhase3A_kilosortChanMap', ...
    'neuropixPhase3B1_kilosortChanMap', 'neuropixPhase3B2_kilosortChanMap'};

    fdir = {'Loewi\posterior', 'Loewi\frontal', 'WillAllen', ...
    'Waksman\ZO', 'Waksman\K1',\ZNP1', ...
    'Josh\probeA', 'Josh\probeF', 'Josh\probeD'};
NTOT = [384 384 385 385 385 385 385 385 385 384 384 384];
iMap = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];

% common options for every probe

ops.trange      = [0 Inf]; % TIME RANGE IN SECONDS TO PROCESS

% find the binary file in this folder
rootrootZ = 'F:\Spikes\';

% path to whitened, filtered proc file (on a fast SSD)
rootH = 'H:\DATA\Spikes\temp\';
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD


for j = 1 %1:numel(fdir)    
    ops.chanMap = fullfile(pathToYourConfigFile, [chanMapList{iMap(j)} '.mat']);
    ops.NchanTOT    = NTOT(j); % total number of channels in your recording
    rootZ = fullfile(rootrootZ, fdir{j});
    
    fs = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
    fname = fs(1).name;
    ops.fbinary     = fullfile(rootZ,  fname);
    ops.rootZ = rootZ;
    
    % preprocess data to create temp_wh.dat
    rez = preprocessDataSub(ops);
    
    % pre-clustering to re-order batches by depth
    fname = fullfile(rootZ, 'rez.mat');    
    if exist(fname, 'file')
        % just load the file if we already did this
        dr = load(fname);
        rez.iorig = dr.rez.iorig;
        rez.ccb = dr.rez.ccb;
        rez.ccbsort = dr.rez.ccbsort;
    else
        rez = clusterSingleBatches(rez);
        save(fname, 'rez', '-v7.3');
    end

    % main optimization
    rez = learnAndSolve8b(rez);

    % final splits
    rez = splitAllClusters(rez);
    
    % this saves to Phy
    rezToPhy(rez, rootZ);
    
    % discard features in final rez file (too slow to save)
    rez.cProj = [];
    rez.cProjPC = [];
    
    % save final results as rez2 
    fname = fullfile(rootZ, 'rez2.mat');
    save(fname, 'rez', '-v7.3');
    
%     loadManualSorting;
end

