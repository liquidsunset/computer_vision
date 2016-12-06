% Assignment 2 Daniel Brand 1023077
% Anzahl der Bilder die pro Ordner verwendet werden.
fileCount = 1;
% SIFT bin in Pixel
binSize = 8;
% Ben�tigt um gleichen output zu erzeugen wie normale SIFT Funktion
magnif = 5;
% Clustergr��e f�r k-means
clusterSize = 128;

% Name des �bergeordneten Ordners, befindet sich im Matlab-Root
dirName = 'scene_categories/';
% lesen aller Daten und Ordner im dir
dirData = dir(dirName);
% Filtern der Ordner
dirIndex = [dirData.isdir];

%{
Nur ben�tigt, wenn im root auch Bilder liegen w�rden
fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
        fileList,'UniformOutput',false);
end
%}

% Auslesen aller Unterordner
subDirs = {dirData(dirIndex).name};
% Pr�fen ob valider Unterordner
validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories

% Array indem die Bilder gespeichert werden
imageArray = {};
% Iterieren �ber g�ltige Unterordner
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
        singleImagePath = imagePaths{loopIndex};
        % Voller Pfad ab Matlab-Root f�r das Bild
        fullFilePath = fullfile(nextDir, singleImagePath);
        % Einlesen des Bildes
        I = imread(fullFilePath);
        % Resize des Bildes auf gleiche Gr��e um immer gleiche Anzahl an
        % Deskriptoren zu erhalten
        I = imresize(I,[256 256]);
        % �berpr�fen ob Bild schon Grayscale ist, ansonsten umwandeln
        % + erzeugen von Single-Precision Bild
        if(size(I, 3) == 3)
            I = single(vl_imdown(rgb2gray(I))) ;
        else
            I = single(vl_imdown(I)) ;
        end
        % Smoothen des Bildes
        Is = vl_imsmooth(I, sqrt((binSize/magnif)^2 - .25));
        % Abspeichern des Bildes im Array
        imageArray = [imageArray Is];
        
        loopIndex = loopIndex + 1;
    end
end

descriptors = {};
for image  = imageArray
    % Erzeugen der Deskriptoren pro Bild und abspeichern
    [f, d] = vl_dsift(deal(image{:}), 'size', binSize, 'Fast');
    descriptors = [descriptors, d];
end

concatDesc = [];
for k=1:length(descriptors)
    % Erzeugen einer Matrix mit allen Deskriptoren
    concatDesc = [concatDesc, descriptors{k}];
end

% k-means Clustering
[centers] = vl_kmeans(double(concatDesc), 128);

% Zuweisen des Deskriptors zum n�hsten Cluster Center
knnClusterPoints = {length(descriptors)};
for k=1:length(descriptors)
    desc = double(descriptors{k});
    % Finden der n�hsten Cluster Punkte mit knn
    knn = knnsearch(desc.', centers.');
    knnClusterPoints{k} = knn;
end

% Zeichnen des Histograms, Hier f�r das erste Bild
histogram(knnClusterPoints{1});

