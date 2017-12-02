function imgOut = createStack(cellArrayOfImages,varargin)

narginchk(1,13)
[thumbSize, montageSize, maintainAspectRatio, burnNames, textProperties, includePathnames, customLabels] = parseInputs(varargin{:});
hasCVST = ~isempty(ver('vision'));
includesTruecolor = false;
for ii = 1:numel(cellArrayOfImages)
	testval = imfinfo(cellArrayOfImages{ii});
	if strcmp(testval(1).ColorType,'truecolor')
		includesTruecolor = true;
		break
	end
end

thumbnails = [];
if burnNames || ~isempty(customLabels)
	if hasCVST
		Position = [10 10];
		Fontsize = 18; 
		tmp = cellfun(@(x) strfind(x,'Position'),textProperties,'UniformOutput',false);
		tmp = find(~cellfun(@isempty,tmp));
		if ~isempty(tmp)
			Position = textProperties{tmp+1};
			textProperties([tmp,tmp+1]) = [];
		end
		tmp = cellfun(@(x) strfind(x,'Fontsize'),textProperties,'UniformOutput',false);
		tmp = find(~cellfun(@isempty,tmp));
		if ~isempty(tmp)
			Fontsize = textProperties{tmp+1};
		end
		Linespace = Fontsize + 10;
	else
		warning('createMontage: Burning of names requires a license for Computer Vision System Toolbox.')
	end
end

for ii = 1:numel(cellArrayOfImages)
	[img,map] = imread(cellArrayOfImages{ii});
	if ~isempty(map)
		img = ind2rgb(img,map);
	end
	img = im2uint8(img);
	subImg = makeSubimage(img,maintainAspectRatio,thumbSize);	if includesTruecolor
		[~,~,p] = size(subImg);
		if p~=3, subImg = repmat(subImg,[1 1 3]);end
	end
	if (burnNames || ~isempty(customLabels)) && hasCVST
		tmpName = cellArrayOfImages{ii};
		if includePathnames && isempty(customLabels)
			tmpName = which(tmpName);
			if isempty(tmpName)
				tmpName = cellArrayOfImages{ii};
			end
			tmpName = regexprep(tmpName,'\','\\ ');
			tmpName = linewrap(tmpName,25);
			tmpName = regexprep(tmpName,'\\ ','\\');
			newPosition = [repmat(Position(1),size(tmpName,1),1),...
				Position(2)+(0:size(tmpName,1)-1)'*Linespace];
			subImg = insertText(subImg,newPosition,tmpName,textProperties{:});
		else
			if ~isempty(customLabels)
				tmpName = customLabels{ii};
			else
				[~,tmpName,ext] = fileparts(tmpName);
				tmpName = [tmpName,ext];
			end
			subImg = insertText(subImg,Position,tmpName,textProperties{:});
		end
	end
	thumbnails = cat(4, thumbnails, subImg);
end
tmi = figure('visible','off');
if isempty(montageSize)
	imgOut = montage(thumbnails);
else
	imgOut = montage(thumbnails,'size',montageSize);
end
imgOut = get(imgOut,'cdata');
delete(tmi)
end

function subimg = makeSubimage(I,maintainAspectRatio,thumbSize)
if numel(thumbSize) == 1
	maintainAspectRatio = false;
end
if ~isempty(thumbSize)
	if maintainAspectRatio
		[m,n,~] = size(I);
		pcts = thumbSize./[m,n];
		subimg = imresize(I,min(pcts));
		[m,n,~] = size(subimg);
		if any([m>thumbSize(1),n>thumbSize(2)])
			subimg = subimg(1:min(m,thumbSize(1)),1:min(n,thumbSize(2)),:);
			[m,n,~] = size(subimg);
		end
		subimg = padarray(subimg,[round((thumbSize(1)-m)/2) ceil((thumbSize(2)-n)/2)]);
		subimg = subimg(1:thumbSize(1),1:thumbSize(2),:);
	else
		subimg = imresize(I,thumbSize);
	end
else
	subimg = I;
end
end

function [thumbSize, montageSize, maintainAspectRatio, burnNames, textProperties, includePathnames, customLabels] = parseInputs(varargin)
parser = inputParser;
parser.CaseSensitive = true;
parser.FunctionName  = 'createMontage';
parser.addParameter('thumbSize', [200 200]);
parser.addParameter('montageSize', []);
parser.addParameter('maintainAspectRatio', true);
parser.addParameter('burnNames', false);
parser.addParameter('customLabels',{});
parser.addParameter('textProperties',...
	{'TextColor', 'w',...
	'FontSize', 18,...
	'BoxColor','blue',...
	'BoxOpacity',0.8,...
	'Position', [10 10]});
parser.addParameter('includePathnames',false);
% Parse input
parser.parse(varargin{:});
% Assign outputs
r = parser.Results;
[thumbSize, montageSize, maintainAspectRatio, burnNames,...
	textProperties, includePathnames, customLabels] = ...
	deal(r.thumbSize, r.montageSize, r.maintainAspectRatio, ...
	r.burnNames, r.textProperties, r.includePathnames, r.customLabels);
end

