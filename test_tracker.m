%tester tracker
srcFiles = dir(strcat(source_filepath,'\*.tif'));
%read video info
%vr=VideoReader(pathname_video);
numFrames=numel(srcFiles);

%initialize tracker 
binR=16;  %16bins
binG=16;
binB=16;
binColor=[binR, binG, binB];
patchcenter=zeros(2, numFrames);
patchsize=zeros(2, numFrames);
nIt_max=20;
eps_ms=0.05;
kernelType=2;   %1-Gaussian 2-'Epanechnikov'
bandwidth=1;

stop=0
start=0
pauseImg=0
dis_flag=0
saveTraj=0
%define template frame
global mask;
global frameindex_template ;
global RoiPos
global tra_final
if isempty(frameindex_template)
    frameindex_template=1
end
if frameindex_template==0
    frameindex_template=1
end

img_template=imread(strcat(source_filepath,'\',srcFiles(frameindex_template).name));
if size(img_template,3)==3
    
else
   if  isa(img_template, 'uint16') 
img_temp=img_template/256;
img_temp=uint8(img_temp);
   else
img_temp=img_template;
   end
img_template=zeros(size(img_template, 1), size(img_template,2), 3);
img_template=img_temp;
img_template(:,:,1)=img_temp;
img_template(:,:,2)=img_temp;
img_template(:,:,3)=img_temp;
end
[T,left,top,H,W] = Select_patch(img_template,0);
patchcenter_template = round([left+W/2; top+H/2]);
patchsize_template = [W; H];
 
%weight kernel, profile
[kernelMask, kernelProfileMask] = compute_kernelEllipse(patchsize_template, kernelType); 

%template 
hist_template=compute_hist(double(img_template), patchcenter_template, binColor, kernelMask);
%figure(1); clf; imagesc(img_template(:,:,1)); colormap(gray); hold on; ellipse(patchcenter_template(1),patchcenter_template(2),0,patchsize_template(1)/2,patchsize_template(2)/2,20,'.', 5);

%track target 
trace=zeros(5, numFrames);
if isempty(tra_final)
    tra_final=zeros(2, numFrames);
end


trace(:, frameindex_template)=[patchcenter_template; patchsize_template; 1];


for frameindex = frameindex_template+1:numFrames
    
    %read test frame
   
    img_test=imread(strcat(source_filepath,'\',srcFiles(frameindex).name));
    
   
    
    if size(img_test,3)==3
        
    else
        if  isa(img_test, 'uint16')
            img_testtemp=img_test/256;
            img_testtemp=uint8(img_testtemp);
        else
            img_testtemp=img_test;
        end
    %img_test=img_test/256;
%     img_test=img_test;
%     img_temp=zeros(size(img_test,1), size(img_test,2), 3);
%    img_temp(:,:,1)=img_test;
%     img_temp(:,:,2)=img_test;
%     img_temp(:,:,3)=img_test;
%     img_test=img_temp;
%     
    %img_testtemp=img_test;
img_test=zeros(size(img_template, 1), size(img_template,2), 3);
img_test=img_testtemp;
img_test(:,:,1)=img_testtemp;
img_test(:,:,2)=img_testtemp;
img_test(:,:,3)=img_testtemp;

    end
%     img_test=img_test/256;
%     img_temp=zeros(size(img_test,1), size(img_test,2), 3);
%     img_temp(:,:,1)=img_test;
%     img_temp(:,:,2)=img_test;
%     img_temp(:,:,3)=img_test;
%     img_test=img_temp;


    
   
    
    %mean shift optimizer 
    [centerNew, sizeNew, traj, nIt]=meanshift_tracking(hist_template, double(img_test), ...
                            trace(1:2,frameindex-1), trace(3:4,frameindex-1),... 
                            kernelMask, kernelProfileMask, ...
                            binColor, nIt_max, eps_ms);
                        
                        
  
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                     
    
    %store results
    patchcenter(:,frameindex)=centerNew;
    patchsize(:,frameindex)=sizeNew;
    
    trace(:, frameindex)=[centerNew; sizeNew; traj(3,nIt)];
  
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %boundary check
    if(centerNew(1,1)<15||centerNew(1,1)>size(img_template,1)-15||centerNew(2,1)<15||centerNew(2,1)>size(img_template,2)-15)
    [r1,c1]=find(trace(1,:));
    [r2,c2]=find(tra_final(1,:));
    if isempty(c2)
    tra_final=trace(1:2,c1(1):c1(end));  %#ok<*NASGU>
    else
    tra_final(:,c1(1):c1(end))=trace(1:2,c1(1):c1(end));  
    if c1(end)< size(trace,2)
    tra_final(:,(c1(end)+1):size(tra_final,2))=trace(1:2,(c1(end)+1):size(tra_final,2));  
    end
    end
        break
    end
    %%%%%%%%%%%%%%Creat Buttons on the figure 
    SliderFrame = uicontrol('Style','slider','Position',[40 20 400 25],'Min',1,...
        'Max',numFrames,'Value',frameindex,'SliderStep',[1/numFrames  2/numFrames],'Callback',@(hObject,callbackdata)slider(hObject,trace,numFrames,srcFiles,source_filepath));%@(hObject,callbackdata)slider(frameindex,num
    pause(.2);
    StartButton = uicontrol('Style','pushbutton','Position',[450 20 40 25],'string','start ','Callback','mask=[];frameindex_template=[];test_tracker');
    ReselectButton = uicontrol('Style','pushbutton','Position',[500 20 60 25],'string','reselect ','Callback','test_tracker');
    StopButton = uicontrol('Style','pushbutton','Position',[570 20 40 25],'string','stop','Callback','stop=1');
    PauseButton = uicontrol('Style','pushbutton','Position',[620 20 40 25],'string','pause','Callback','pauseImg=1');
    RoiButton=uicontrol('Style','pushbutton','Position',[670 20 40 25],'string','roi','Callback','h = imfreehand(gca),RoiPos = getPosition(h),currentImg=imshow(img_test);,mask = createMask(h,currentImg);');
    ResumeButton = uicontrol('Style','pushbutton','Position',[720 20 40 25],'string','resume','Callback','pauseImg=0');
    SaveTrajectoryButton = uicontrol('Style','pushbutton','Position',[770 20 50 25],'string','savetraj','Callback',@(hObject,callbackdata)saveTrajectory(hObject,result_path,partile_name,frameindex_template,frameindex,trace(1,frameindex_template), trace(2,frameindex_template)));
    
    
     %%%%%%%%%check whether the pause button is pushed or not
    while pauseImg==1
        pause(0.1);
        
    end
    
    
%%%% if roi button is pused display ROI otherwise display entire image
% if isempty(mask) 
    
    
    imagesc(img_test), colormap(gray);
    axis off
    hold on
    
% else
%      
%      img_test_gray=rgb2gray(img_test);
%      ROI=double(mask).*double(img_test_gray);
%      imagesc(ROI), colormap(gray);
%      axis off
%      hold on
% end
    %check the distance from the selected paritcle to the boundary of ROI
    if ~isempty(mask)
        plot(RoiPos(:,1),RoiPos(:,2),'b-')
    for i=1:size(RoiPos(:,1))
        distance=(trace(1,frameindex)-RoiPos(i,1))^2+(trace(2, frameindex)-RoiPos(i,2))^2;
        if distance<50
            dis_flag=dis_flag+1;
            break
        end
    end
    if dis_flag>0
        break
    end
    end
    
    %%check memory condition and clear images in memory
    user=memory;
    if user.MemUsedMATLAB>user.MemAvailableAllArrays/3
        close(2)
        height = size(img_test,1);
        width = size(img_test,2);
        scrsz = get(0,'ScreenSize');
        figure (2)
        set(2,'Name','Target Selection','Position',...
            [scrsz(3)/2-(width-200)/2 scrsz(4)/2-(height-200)/2 width-200 height-200],...
            'MenuBar','figure');
    end
   
    
    %pause off
    %ellipse(patchcenter(1,frameindex-1), patchcenter(2,frameindex-1),0, patchsize(1,frameindex-1)/2, patchsize(2,frameindex-1)/2,20,'g.', 5);
    %ellipse(patchcenter(1,frameindex), patchcenter(2,frameindex),0, patchsize(1,frameindex)/2, patchsize(2,frameindex)/2,20,'b.', 5);
    plot(patchcenter(1,frameindex), patchcenter(2,frameindex), 'rs','LineWidth',2, 'MarkerSize', 5);
    if frameindex>5
    plot(trace(1,frameindex-5:frameindex),trace(2,frameindex-5:frameindex),'rs','LineWidth',2, 'MarkerSize', 5);
    %lineX=[trace(1,frameindex-5),trace(1,frameindex-3),trace(1,frameindex)]
    %lineY=[trace(2,frameindex-5),trace(2,frameindex-3),trace(2,frameindex)]
    %line(lineX,lineY,)
    end
    title(strcat(int2str(frameindex), '/', int2str(numFrames)));
    
    %%%%%%%%%check whether the stop button is pushed or not
    if stop==1
    [r1,c1]=find(trace(1,:));
    [r2,c2]=find(tra_final(1,:));
    if isempty(c2)
    tra_final=trace(1:2,c1(1):c1(end));  
    else
    tra_final(:,c1(1):c1(end))=trace(1:2,c1(1):c1(end));  
    if c1(end)< size(trace,2)
    tra_final(:,(c1(end)+1):size(tra_final,2))=trace(1:2,(c1(end)+1):size(tra_final,2));  
    end
    end
    
    break
    end
end
%save
% save the coordinate of the selected particle to a txt file

% fileName=strcat(result_path,'\',partile_name,'_',num2str(frameindex),'.txt');
% fp=fopen(fileName,'w');
%         for k=1:size(trace,2) 
%             fprintf(fp, '%d %d \r\n', trace(1,k), trace(2,k));
%         end
%         
% fclose(fp);

 




