function sceneFeatures = trainStackedFaceDetector(imgSet)

nFaces = numel(imgSet);
trainingPhotosPerPerson = max(5,min([imgSet.Count]));
testSet = select(imgSet,1:trainingPhotosPerPerson);
allIms = [testSet.ImageLocation];



adjustHistograms = false; %Low-cost way to improve performance
fcnHandle = @(x) detectFASTFeatures(x,...
	'MinQuality',0.025,...
	'MinContrast',0.025); %#ok
extractorMethod = 'SURF';%#ok
metric = 'SAD';

inds = reshape(1:numel(allIms),[],nFaces);
scenePoints = cell(nFaces,1);
sceneFeatures = cell(nFaces,1);
targetSize = 100;
thumbSize = [targetSize,targetSize];
for ii = 1:nFaces
	trainingImage = createMontage(allIms(inds(:,ii)),...
		'montageSize',[size(inds,1),1],...
		'thumbSize',thumbSize);
	if adjustHistograms
		trainingImage = histeq(trainingImage);%#ok
	end
	scenePoints{ii} = fcnHandle(trainingImage);
	[sceneFeatures{ii}, scenePoints{ii}] = extractFeatures(trainingImage, scenePoints{ii},...
		'Method',extractorMethod);
end