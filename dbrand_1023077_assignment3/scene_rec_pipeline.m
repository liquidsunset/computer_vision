% Assignment 3 Daniel Brand 1023077
% Kommando für das Hinzufügen von vl_feat:
% run('~/Documents/MATLAB/Add-Ons/vlfeat-0.9.20/toolbox/vl_setup.m')
% Hinzufügen von Liblinear:
% addpath '~/Documents/MATLAB/Add-Ons/liblinear-2.1/matlab'

%{
Alle Tests wurden mit folgenden Parametern durchgeführt:
binSize = 8; stepSize = 8; clusterSize = 1024;

Für den ersten Durchlauf habe ich 7 Gruppen mit jeweils unterschiedlichen
Bilder erzeugt. Eine jede Gruppe besteht aus 24 Bildern für die Trainings-
daten und 6 Bilder für die Testdaten. Daraus folgten folgende Werte für die
Genauigkeit:
Gruppe 1 Accuracy: 56,6%
Gruppe 2 Accuracy: 62,2%
Gruppe 3 Accuracy: 53,3%
Gruppe 4 Accuracy: 45,5%
Gruppe 5 Accuracy: 43,3%
Gruppe 6 Accuracy: 64,4%
Gruppe 7 Accuracy: 60,0%
bei einer Gesamtlaufzeit von 562.591792 seconds.

Für den zweiten Durchlauf wurden 5 Gruppen mit jeweils unterschiedlichen
Bildern erzeugt. Eine jede Gruppe besteht aus 32 Bildern für die Trainings-
daten und 8 Bilder für die Testdaten. Daraus folgten folgende Werte für die
Genauigkeit:
Gruppe 1 Accuracy: 58,3%
Gruppe 2 Accuracy: 55,83%
Gruppe 3 Accuracy: 45,83%
Gruppe 4 Accuracy: 67,5%
Gruppe 5 Accuracy: 57,5%
bei einer Gesamtlaufzeit von 562.641918 seconds.
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
groupCount = 1;
trainigData = 1;
testData = 1;
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
    centerSize = size(centers.', 1);
    
    % *********************************************************************
    % Erzeugen vom Bag-of-Words Indices Histogramm für Trainigns und Test-
    % daten
    
    featuresTraining = zeros(size(descriptorsTraining, 1), centerSize);
    for k=1:length(descriptorsTraining)
        desc = double(descriptorsTraining{k});
        distance = vl_alldist2(centers, desc);
        
        [~, indices] = min(distance);
        for j=1:size(indices, 2)
            featuresTraining(k, indices(j)) = featuresTraining(...
                k, indices(j)) + 1;
        end
        
        featuresTraining(k, :) = featuresTraining(k, :) ...
            / norm(featuresTraining(k, :));
    end
    
    featuresTest = zeros(size(descriptorsTest, 1), centerSize);
    for k=1:length(descriptorsTest)
        desc = double(descriptorsTest{k});
        distance = vl_alldist2(centers, desc);
        
        [~, indices] = min(distance);
        for j=1:size(indices, 2)
            featuresTest(k, indices(j)) = featuresTest(k, indices(j)) + 1;
        end
        
        featuresTest(k, :) = featuresTest(k, :) / norm(featuresTest(k, :));
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