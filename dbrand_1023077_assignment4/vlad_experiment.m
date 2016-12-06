% Assignment 4 Daniel Brand 1023077
% Kommando für das Hinzufügen von vl_feat:
% run('~/Documents/MATLAB/Add-Ons/vlfeat-0.9.20/toolbox/vl_setup.m')
% Hinzufügen von Liblinear:
% addpath '~/Documents/MATLAB/Add-Ons/liblinear-2.1/matlab'

%{
Image Pipeline mit vlad anstatt Fisher-Vectoren
Ergebnisse sind im Fisher-Vector File
%}

% *************************************************************************
% Initialisierungs Variablen
% SIFT bin in Pixel
binSize = 8;
% Step Size
stepSize = 8;

% Clustergröße für k-means
clusterSize = 1024;

% Anzahl der Bilder die pro Ordner verwendet werden. Test + Trainingsdaten
% + Anzahl der Durchläufe mit unterschiedlichen Bildern.
groupCount = 5;
trainigData = 32;
testData = 8;
fileCount = trainigData + testData;

% Array mit den Genauigkeiten pro Durchlauf
accuracyArray = [];

% *************************************************************************
% Einlesen der unterschiedlichen Bilder sowie erstellen unterschiedlicher
% Gruppen von Bildern

% Name des übergeordneten Ordners, befindet sich im Matlab-Root
dirName = 'scene_categories/';
% lesen aller Daten und Ordner im dir
dirData = dir(dirName);
% Filtern der Ordner
dirIndex = [dirData.isdir];

%{
Nur benötigt, wenn im root auch Bilder liegen würden
fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
        fileList,'UniformOutput',false);
end
%}

% Auslesen aller Unterordner
subDirs = {dirData(dirIndex).name};
% Prüfen ob valider Unterordner
validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories

tic;

for groupLoop=0:(groupCount - 1)
    % Array indem die Bilder gespeichert werden
    imageArrayTraining = {};
    imageArrayTest = {};
    % Iterieren über gültige Unterordner
    for iDir = find(validIndex)
        % Ordnerpfad
        nextDir = fullfile(dirName,subDirs{iDir});
        % Suchen nach allen JPG Bildern im Subordner
        filePattern = sprintf('%s/*.jpg', nextDir);
        % Auslesen aller Daten + Pfad zu den Bildern
        baseFileNames = dir(filePattern);
        % Abspeichern der Bilderpfade
        imagePaths = {baseFileNames.name};
        
        loopIndex = 1;
        while(loopIndex <= fileCount)
            % Pfad eines Bildes
            singleImagePath = imagePaths{loopIndex + fileCount*groupLoop};
            % Voller Pfad ab Matlab-Root für das Bild
            fullFilePath = fullfile(nextDir, singleImagePath);
            % Einlesen des Bildes
            I = imread(fullFilePath);
            % Resize des Bildes auf gleiche Größe um immer gleiche Anzahl an
            % Deskriptoren zu erhalten
            I = imresize(I,[256 256]);
            % Überprüfen ob Bild schon Grayscale ist, ansonsten umwandeln
            % + erzeugen von Single-Precision Bild
            if(size(I, 3) == 3)
                I = single(vl_imdown(rgb2gray(I))) ;
            else
                I = single(vl_imdown(I)) ;
            end
            
            % Abspeichern des Bildes im Array
            if(loopIndex <= trainigData)
                imageArrayTraining = [imageArrayTraining I];
            else
                imageArrayTest = [imageArrayTest I];
            end
            loopIndex = loopIndex + 1;
        end
    end
    
    % *************************************************************************
    % Erstellen der Features (Descriptors) für die Bilddaten
    
    descriptorsTraining = {};
    for k=1:length(imageArrayTraining)
        imageTraining = imageArrayTraining{k};
        [f, d] = vl_dsift(imageTraining, 'size', binSize, 'step', ...
            stepSize, 'fast');
        descriptorsTraining = [descriptorsTraining; d];
    end
    
    descriptorsTest = {};
    for k=1:length(imageArrayTest)
        imageTest = imageArrayTest{k};
        [f, d] = vl_dsift(imageTest, 'size', binSize, 'step', ...
            stepSize, 'fast');
        descriptorsTest = [descriptorsTest; d];
    end
    
    % Erzeugen einer Matrix mit allen Deskriptoren der Trainingsdaten
    concatDesc = [];
    for k=1:length(descriptorsTraining)
        concatDesc = [concatDesc, descriptorsTraining{k}];
    end
    
    % *********************************************************************
    % Clustering der Trainingsdeskriptoren
    
    [centers, ~] = vl_kmeans(double(concatDesc), clusterSize);
    
    % *********************************************************************
    % kdTree erzeugen für VLAD
    kdtree = vl_kdtreebuild(centers) ;
    
    
    % *********************************************************************
    % Erzeugen von VLAD Encoding Vectoren
    
    featuresTraining = [];
    for k=1:length(descriptorsTraining)
        desc = double(descriptorsTraining{k});
        nn = vl_kdtreequery(kdtree, centers, desc) ;
        assignments = zeros(clusterSize,length(desc));
        assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
        enc = vl_vlad(desc,centers,assignments);
        featuresTraining = [featuresTraining; enc.'];
    end
    
    featuresTest = [];
    for k=1:length(descriptorsTest)
        desc = double(descriptorsTest{k});
        nn = vl_kdtreequery(kdtree, centers, desc) ;
        assignments = zeros(clusterSize,length(desc));
        assignments(sub2ind(size(assignments), nn, 1:length(nn))) = 1;
        enc = vl_vlad(desc,centers,assignments);
        featuresTest = [featuresTest; enc.'];
    end
    
    % *********************************************************************
    % Erzeugen der Labels für Training und Test
    
    trainingLabel = zeros(size(descriptorsTraining, 1), 1);
    loopCount = 1;
    for k=1:length(find(validIndex))
        for i=1:trainigData
            trainingLabel(loopCount, 1) = k;
            loopCount = loopCount + 1;
        end
    end
    
    testLabel = zeros(size(descriptorsTest, 1), 1);
    loopCount = 1;
    for k=1:length(find(validIndex))
        for i=1:testData
            testLabel(loopCount, 1) = k;
            loopCount = loopCount + 1;
        end
    end
    
    % *********************************************************************
    % Trainieren und Testen des linearen Classifiers
    
    model = train(trainingLabel, sparse(featuresTraining));
    [predictions, accuracy, ~] = predict(testLabel, ...
        sparse(featuresTest), model);
    accuracyArray = [accuracyArray accuracy];
    
end

disp(accuracyArray);
toc;