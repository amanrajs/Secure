classdef (Sealed, CaseInsensitiveProperties=true, TruncatedProperties=true) webcamera < hgsetget & dynamicprops
    
    properties(GetAccess = public, SetAccess = private)
        
        Name
    end
    
    
    properties(Access = public, AbortSet)
        Resolution
    end

    properties(Access = private, Hidden)
        CamController
        CamPreviewController
        UniqueID
        CurrentWidth
        CurrentHeight
        IsPreviewing
    end
    
    properties(GetAccess = public, SetAccess = private)   
        AvailableResolutions
    end
    
    properties (Access = private, Hidden)
        % Maintain a map of created objects to gain exclusive access.
        ConnectionMap = containers.Map()
    end
    
    methods(Access = public)
        function obj = webcam(varargin)
            
            try
                % Check if the support package is installed.
                fullpathToUtility = which('matlab.webcam.internal.Utility');
                if isempty(fullpathToUtility) 
                    % Support package not installed - Error.
                    if feature('hotlinks')
                        error('MATLAB:webcam:supportPkgNotInstalled', message('MATLAB:webcam:webcam:supportPkgNotInstalled').getString);
                    end
                end

                % mex file based on the platform
                [~, deviceNames, uniqueIDs] = matlab.webcam.internal.Utility.enumerateWebcams;

                if(isempty(deviceNames))
                    % No devices were found.
                    error('MATLAB:webcam:noWebcams', message('MATLAB:webcam:webcam:noWebcams').getString);
                end

                if(isempty(varargin))
                    devID = uniqueIDs{1};
                    devName = deviceNames{1};
                else
                    if (ischar(varargin{1})) 
                        devName = validateName(varargin{1}, deviceNames);
                        index = ismember(deviceNames, devName);
                        devID = uniqueIDs{index};
                    elseif (isnumeric(varargin{1}))

                       
                        devIndex = varargin{1};
                        validateattributes(devIndex, {'numeric'}, {'scalar', '>=', 1, '<=', length(uniqueIDs), 'nonnan', 'finite'}, 'webcam', 'INDEX', 1);

                        devName = deviceNames{devIndex};
                        devID = uniqueIDs{devIndex};                
                    else
                        error('MATLAB:webcam:invalidArg', message('MATLAB:webcam:webcam:invalidArg').getString);
                    end
                end

                if isKey(obj.ConnectionMap, devName)
                    storedDevID = obj.ConnectionMap(devName);
                    if storedDevID == devID
                        error('MATLAB:webcam:connectionExists', message('MATLAB:webcam:webcam:connectionExists', devName).getString);
                    end
                end

                obj.Name = devName;
                obj.UniqueID = devID;

                obj.CamController = ...
                    matlab.webcam.internal.WebcamController(devName, devID);

                [obj.CurrentWidth, obj.CurrentHeight] = obj.CamController.getCurrentFrameSize;

                dynamicProps = obj.CamController.getDynamicProperties();
                dynPropKeys = dynamicProps.keys;
                dynPropValues = dynamicProps.values;

                for i=1:dynamicProps.size()
                    prop = addprop(obj,dynPropKeys{i});
                    obj.(dynPropKeys{i}) = dynPropValues{i};
                    prop.SetAccess = 'public';
                    prop.Dependent = true;
                    prop.AbortSet = true; 
                    prop.SetMethod = @(obj, value) obj.setDynamicProperty(prop.Name, value);
                    prop.GetMethod = @(obj) obj.getDynamicProperty(prop.Name);
                end

                obj.CamController.open();
                
                if (nargin>1)

                    if ~mod(nargin,2) 
                        error('MATLAB:webcam:unmatchedPVPairs', message('MATLAB:webcam:webcam:unmatchedPVPairs').getString);
                    end

                    for i = 2:2:length(varargin)
                        pName = varargin{i};
                        if(strcmpi(pName,'Name')||strcmpi(pName,'AvailableResolutions'))
                            error('MATLAB:webcam:setReadOnly', message('MATLAB:webcam:webcam:setReadOnly', varargin{i}).getString);
                        end

                        actualPropName = validatestring(pName, fieldnames(set(obj)), 'webcam', upper(pName), i);

                        obj.(actualPropName) = varargin{i+1};
                    end
                end

                

                obj.ConnectionMap(devName) = devID;

                obj.CamPreviewController = matlab.webcam.internal.PreviewController(obj.Name, obj.CamController);
            catch excep
                throwAsCaller(excep);
            end
        end
        
        function [image, timestamp] = snapshot(obj)
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end            
            [image, timestamp] = obj.CamController.getCurrentFrame();
        end
        
                
        function hImage = preview(obj, varargin)
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end
            
            % Invalid number of input arguments.
            narginchk(1, 2);
            
            % Type checking if image handle was passed in.
            if (nargin==2)
                imHandle = varargin{1};
                validateattributes(imHandle, {'matlab.graphics.primitive.Image'}, {'scalar'}, 'preview', 'Image Handle', 2)
            end
            
            % Call controller preview.
            imHandle = obj.CamPreviewController.preview(varargin);
                                   
            % Assign output only if requested.
            if(nargout > 0)
                hImage = imHandle;
            end
        end
        
        function closePreview(obj)
            
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end
            
            obj.CamPreviewController.closePreview();
        end
        
        
        function varargout = set(obj, varargin)
 
          if ~isvalid(obj)
              error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
          end          
          
          settableFields = fieldnames(set@hgsetget(obj));
          switch(nargin)
            case 1
                % S = set(obj)
                fn = fieldnames(obj);
                for ii = 1:length(fn)
                    dPropInfo = obj.findprop(fn{ii});
                    if ~strcmp(dPropInfo.SetAccess, 'public')
                        continue;
                    end
                    val = {set(obj,fn{ii})};
                    if isempty(val{1})
                        st.(fn{ii}) = {};
                    else
                        st.(fn{ii}) = val;
                    end
                end
                varargout = {st};
            case 2
              if isstruct(varargin{1})
                  st = varargin{1};
                  stfn = fieldnames(st);
                  for ii = 1:length(stfn)
                      prop = stfn{ii};
                      prop = validatestring(prop, settableFields, 'webcam', upper(prop));
                      try
                          set@hgsetget(obj,prop,st.(prop));
                      catch ME
                          throwAsCaller(ME);
                      end
                  end
              else 
                  propName = varargin{1};
                  
                  propName = validatestring(propName, settableFields);
                  
                  dPropInfo = obj.findprop(propName);
                  if ~strcmp(dPropInfo.SetAccess, 'public')
                      error('MATLAB:webcam:devicePropReadOnly', message('MATLAB:webcam:webcam:devicePropReadOnly', propName).getString);
                  end
                  
                  if strcmpi(propName, 'Resolution')
                      propEnum = get(obj, 'AvailableResolutions');
                      varargout = {propEnum};
                      return;
                  end
                  
                  varargout = {{}};
                  val = get(obj, propName);
                  if isnumeric(val) % Not an enumeration
                      return;
                  end
                 
                  if ismember(val, {'on', 'off'})
                      propEnum = {'on', 'off'};
                  else
                      propEnum = {'auto', 'manual'};
                  end
                  varargout = {propEnum};
                  return;
              end
            otherwise
               if mod(length(varargin),2)
                    error('MATLAB:webcam:unmatchedPVPairs', message('MATLAB:webcam:webcam:unmatchedPVPairs').getString);
               end
               
               for ii = 1:2:length(varargin)
                  try
                      pName = validatestring(varargin{ii}, settableFields, 'webcam', upper(varargin{ii}));
                      
                      dPropInfo = obj.findprop(pName);
                      if ~strcmp(dPropInfo.SetAccess, 'public')
                          error('MATLAB:webcam:devicePropReadOnly', message('MATLAB:webcam:webcam:devicePropReadOnly', pName).getString);
                      end
                                            
                      set@hgsetget(obj, pName, varargin{ii+1});
                  catch ME
                      throwAsCaller(ME);
                  end
               end
               varargout = {};
          end
        end
        
    end
    
    methods (Access = public, Hidden)
        function delete(obj)
            try
                if (~isempty(obj.CamController)&& isvalid(obj.CamController))
                      obj.CamController.delete();
                      obj.CamController = [];
                end

                if (~isempty(obj.CamPreviewController)&& isvalid(obj.CamPreviewController))
                      obj.CamPreviewController.delete();
                      obj.CamPreviewController = [];
                end

                if isKey(obj.ConnectionMap, obj.Name)
                    remove(obj.ConnectionMap, obj.Name);
                end
            catch excep
                throwAsCaller(excep);
            end
            
        end
        
        function obj = saveobj(obj)
       
        %OBJ = saveobj(OBJ) saves the Webcam for future loading. 
            warnState = warning('OFF', 'MATLAB:structOnObject');
            saveInfo = struct(obj);
            warning(warnState);

            saveInfo = rmfield(saveInfo, 'CamController');
            saveInfo = rmfield(saveInfo, 'CamPreviewController');
            saveInfo = rmfield(saveInfo, 'CurrentWidth');
            saveInfo = rmfield(saveInfo, 'CurrentHeight');
            saveInfo = rmfield(saveInfo, 'IsPreviewing');
            saveInfo = rmfield(saveInfo, 'AvailableResolutions');
            saveInfo = rmfield(saveInfo, 'ConnectionMap');
            saveInfo = rmfield(saveInfo, 'UniqueID');

            obj = saveInfo;
        end        
        
        function closepreview(~)
            error('MATLAB:webcam:invalidClosePreview', message('MATLAB:webcam:webcam:invalidClosePreview').getString);
        end
                
        function value = getDynamicProperty (obj, propName)
            propName = validatestring(propName, properties(obj), 'webcam', propName);
            
            value = obj.CamController.getDynamicProp(propName);
        end
        
        function setDynamicProperty(obj, propName, value)
            try
                propName = validatestring(propName, properties(obj), 'webcam', propName);

                obj.CamController.setDynamicProp(propName, value);
            catch excep
                throwAsCaller(excep);
            end
        end
    end
    
    methods (Access = public, Hidden)
        function c = horzcat(varargin)
            %Horizontal concatenation of Webcam objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = vertcat(varargin)
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = cat(varargin)
            if (nargin > 2)
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            else
                c = varargin{2};
            end
        end

        % Hidden methods from the hgsetget super class.
        function res = eq(obj, varargin)
            res = eq@hgsetget(obj, varargin{:});
        end
        function res =  fieldnames(obj, varargin)
            res = fieldnames@hgsetget(obj,varargin{:});
        end
        function res = ge(obj, varargin)
            res = ge@hgsetget(obj, varargin{:});
        end
        function res = gt(obj, varargin)
            res = gt@hgsetget(obj, varargin{:});
        end
        function res = le(obj, varargin)
            res = le@hgsetget(obj, varargin{:});
        end
        function res = lt(obj, varargin)
            res = lt@hgsetget(obj, varargin{:});
        end
        function res = ne(obj, varargin)
            res = ne@hgsetget(obj, varargin{:});
        end
        function res = findobj(obj, varargin)
            res = findobj@hgsetget(obj, varargin{:});
        end
        function res = findprop(obj, varargin)
            res = findprop@hgsetget(obj, varargin{:});
        end
        function res = addlistener(obj, varargin)
            res = addlistener@hgsetget(obj, varargin{:});
        end
        function res = notify(obj, varargin)
            res = notify@hgsetget(obj, varargin{:});
        end
        
        function res = addprop(obj, varargin)
            res = addprop@dynamicprops(obj, varargin{:});
        end
    end
    
    methods (Access = public, Hidden)    
        function camController = getCameraController(obj)
            camController = obj.CamController;
        end
    end
    methods
        function value = get.Name(obj)
            value = obj.Name;
        end
        
        function value = get.Resolution(obj)
            value = obj.CamController.getResolution();
        end
        
        function set.Resolution(obj, value)
            try
                value = validatestring(value, obj.getAvailableResolutions(), 'webcam', 'Resolution');
                if strcmpi(value, obj.Resolution)
                    return;
                end
                obj.CamController.setResolution(value); %#ok<MCSUP>
                if (isPreviewing(obj))
                    obj.closePreview();
                    obj.preview();
                end
            catch excep
                throwAsCaller(excep);
            end
        end
        
        function values = get.AvailableResolutions(obj)
            values = obj.CamController.getAvailableResolutions;
        end
    end
    
    methods (Access = private)
        function tf = isPreviewing(obj)
            tf = false;
            if ( ~isempty(obj.CamPreviewController) && obj.CamPreviewController.isPreviewing() )
                tf = true;
            end
        end
        
        function resList = getAvailableResolutions(obj)
            resList = obj.CamController.getAvailableResolutions();
        end
    end
    
    methods (Static, Hidden)
        function supportPackageInstaller
       
            hwconnectinstaller.launchInstaller('SupportPackageFor', 'USB Webcams', 'StartAtStep', 'SelectPackage');
        end
        
        function obj = loadobj(inStruct)
        
            try
                obj = webcam(inStruct.Name, 'Resolution', inStruct.Resolution);
            catch
                warning('MATLAB:webcam:cannotCreateObject', message('MATLAB:webcam:webcam:cannotCreateObject').getString);
                obj = webcam.empty();
            end
            
            inStruct = rmfield(inStruct, 'Name');
            inStruct = rmfield(inStruct, 'Resolution');
            
            if ~isempty(fieldnames(inStruct))
                try
                    set(obj, inStruct);
                catch
                    warning('MATLAB:webcam:cannotRestoreProperties', message('MATLAB:webcam:webcam:cannotRestoreProperties').getString);
                end
            end
        end
    end
end

function resolvedName = validateName(deviceName,deviceList)
    partials = deviceList(strncmpi(deviceName,deviceList,numel(deviceName)));
    exacts = 1;
    listStr = deviceList{1};
    for i = 2:numel(deviceList)
        listStr = [listStr ', ' deviceList{i}]; %#ok<AGROW>
    end
    
    if numel(partials) == 0
        error('MATLAB:webcam:invalidName', message('MATLAB:webcam:webcam:invalidName', listStr).getString);
    elseif numel(partials) > 1  
        exacts = find(strcmp(deviceName,partials), 1);
        if isempty(exacts)
            error('MATLAB:webcam:invalidName', message('MATLAB:webcam:webcam:invalidName', listStr).getString);
        end
    end
    resolvedName = partials{exacts};
end
