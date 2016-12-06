% Daniel Brand, 1023077

% Bild laden
imageSource = imread('harris.jpg');
% Bild in Grauwert-Bild konvertieren mit double Werte
image2DoubleAndGrayScale = rgb2gray(im2double(imageSource));

% Die Harris-Funktion über das Bild berechnen mit geeignetem Sigma
harrisCornerImage = vl_harris(image2DoubleAndGrayScale, 6);

% Uns interessieren nur die lokalen Maxima
idx = vl_localmax(harrisCornerImage);

% Speichern der Werte mit Koordinaten im Bild
[rows,cols] = ind2sub( size(image2DoubleAndGrayScale), idx );

% Einzeichnen der gefundenen Ecken bzw Maxima in das Originalbild
figure1 = figure; axis image; colormap(gray);
image(imageSource);
hold on;
h = plot(cols, rows, 'ro','MarkerSize', 8);

saveas(figure1,'dotted_harris.jpg')