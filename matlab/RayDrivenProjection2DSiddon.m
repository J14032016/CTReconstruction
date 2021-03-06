% Written by Hoyeon Lee
% Reference: "Fast calculation of the exact radilogical path for a
% three-dimensional CT array, Robert L. Siddon, Medical Physics, 12(2)
% (1985).
tic;
%% Input parameters
nx=256;
ny=nx;
ph=phantom(nx);
% ph=recon(:,:,10);
Source_init=[0,1000]; % Initial source position
Detector_init=[0,-500]; % Initial detector position
Origin=[0,0]; % Rotating center
DetectorPixelSize=0.5; % Detector pixel spacing
% DetectorPixelSize=445.059/750; % Detector pixel spacing
NumberOfDetectorPixels=[500 ,1]; % Number of detector rows and chnnels
% NumberOfDetectorPixels=[750 ,1]; % Number of detector rows and chnnels
PhantomCenter=[0,0]; % Center of phantom
PhantomPixelSpacingX=0.5;
PhantomPixelSpacingY=0.5;
nTheta=360;
StartAngle=0;
EndAngle=2*pi;
dir='ccw'; % direction may be counter-clockwise or clockwise


%% Calculating parameters based on input parameters
SAD=sqrt(sum((Source_init-Origin).^2));
SDD=sqrt(sum((Source_init-Detector_init).^2));
% dx=(2*SAD*sin(atan((445.059/2)/SDD)))/512; %phantom pixel spacing
% dy=dx;
dx=PhantomPixelSpacingX; %phantom pixel spacing
dy=-PhantomPixelSpacingY;
% Y index starts from top of the image which has the highest y coordinate
% value, if it changes sign of dy and condition in line 96 should be
% changed


tol_min=1e-6;
tol_max=1e6;
Xplane=(PhantomCenter(1)-size(ph,1)/2+(0:nx))*dx;
Yplane=(PhantomCenter(2)-size(ph,2)/2+(0:ny))*dy;
Xplane=Xplane-dx/2;
Yplane=Yplane-dy/2;
theta=linspace(StartAngle,EndAngle,nTheta+1);
theta=theta(1:end-1);
proj=zeros(NumberOfDetectorPixels(1),nTheta);

% Rotating CCW direction starting from x-axis
% TO Dos:
%   Add direction configurations
%   Reduce discontinuity between angles - this is cause by indexing.
%       From zero to 90 degrees and 270 to 360 degrees, detector has larger number of pixels in
%       bottom/right position from the center and it changes to up/left
%       between 90 to 270 degrees -> Solved
weight_map=zeros([size(ph,1),size(ph,2),nTheta]);

%% Forward projection
for angle_index=1:nTheta
    if(strcmp(dir,'ccw'))
    elseif(strcmp(dir,'cw'))
    end
    SourceX=-SAD*sin(theta(angle_index)); % source coordinate
    SourceY=SAD*cos(theta(angle_index));
    DetectorX=(SDD-SAD)*sin(theta(angle_index));  % center of detector coordinate
    DetectorY=-(SDD-SAD)*cos(theta(angle_index));
    DetectorLength=(floor(-NumberOfDetectorPixels(1)/2):floor(NumberOfDetectorPixels(1)/2))*DetectorPixelSize;
    if(abs(tan(theta(angle_index)))<=tol_min)
        DetectorIndex=[DetectorX+DetectorLength; repmat(DetectorY,1,size(DetectorLength,2))];
    elseif(tan(theta(angle_index))>=tol_max)
        DetectorIndex=[repmat(DetectorX,1,size(DetectorLength,2)); DetectorY+DetectorLength];
    else
        xx=sqrt(DetectorLength.^2./(1+tan(theta(angle_index))^2));
        yy=tan(theta(angle_index))*sqrt(DetectorLength.^2./(1+tan(theta(angle_index))^2));
        DetectorIndex=[DetectorX+sign(DetectorLength).*xx;...
            DetectorY+sign(DetectorLength).*yy];
    end
    if(DetectorY>0)
        DetectorIndex=DetectorIndex(:,end:-1:1);
    end
    DetectorIndex=DetectorIndex(:,1:end-1); % The index pointing center of detector pixels
    for detector_index=1:size(DetectorIndex,2)
        alpha_x=(Xplane-SourceX)/(DetectorIndex(1,detector_index)-SourceX);
        alpha_y=(Yplane-SourceY)/(DetectorIndex(2,detector_index)-SourceY);
        alpha_min=max([0,min(alpha_x(1),alpha_x(end)),min(alpha_y(1),alpha_y(end))]);
        alpha_max=min([1,max(alpha_x(1),alpha_x(end)),max(alpha_y(1),alpha_y(end))]);
        if(alpha_min>=alpha_max)
            continue;
        end
        if(SourceX==DetectorIndex(1,detector_index))
            alpha_x=[];
        elseif(SourceX<DetectorIndex(1,detector_index))
            i_min=ceil((nx+1)-(Xplane(end)-alpha_min*(DetectorIndex(1,detector_index)-SourceX)-SourceX)/dx);
            i_max=floor(1+(SourceX+alpha_max*(DetectorIndex(1,detector_index)-SourceX)-Xplane(1))/dx);
            alpha_x=alpha_x(i_min:i_max);
        else
            i_min=ceil((nx+1)-(Xplane(end)-alpha_max*(DetectorIndex(1,detector_index)-SourceX)-SourceX)/dx);
            i_max=floor(1+(SourceX+alpha_min*(DetectorIndex(1,detector_index)-SourceX)-Xplane(1))/dx);
            alpha_x=alpha_x(i_max:-1:i_min);
        end
        if(SourceY==DetectorIndex(2,detector_index))
            alpha_y=[];
        elseif(SourceY>DetectorIndex(2,detector_index))
            j_min=ceil((ny+1)-(Yplane(end)-alpha_min*(DetectorIndex(2,detector_index)-SourceY)-SourceY)/dy);
            j_max=floor(1+(SourceY+alpha_max*(DetectorIndex(2,detector_index)-SourceY)-Yplane(1))/dy);
            alpha_y=alpha_y(j_min:j_max);
        else
            j_min=ceil((ny+1)-(Yplane(end)-alpha_max*(DetectorIndex(2,detector_index)-SourceY)-SourceY)/dy);
            j_max=floor(1+(SourceY+alpha_min*(DetectorIndex(2,detector_index)-SourceY)-Yplane(1))/dy);
            alpha_y=alpha_y(j_max:-1:j_min);
        end
        alpha=uniquetol(sort([alpha_min,alpha_x,alpha_y,alpha_max]),tol_min/alpha_max);
        l=zeros(length(alpha)-1,1);
        d12=sqrt((SourceX-DetectorIndex(1,detector_index))^2+(SourceY-DetectorIndex(2,detector_index))^2);
        for i=1:length(l)
            l(i)=d12*(alpha(i+1)-alpha(i));
            alpha_mid=(alpha(i+1)+alpha(i))/2;
            xx=(SourceX+alpha_mid*(DetectorIndex(1,detector_index)-SourceX)-Xplane(1))/dx;
            yy=(SourceY+alpha_mid*(DetectorIndex(2,detector_index)-SourceY)-Yplane(1))/dy;
            if(abs(xx)<=tol_min)
                xx=0;
            end
            if(abs(yy)<=tol_min)
                yy=0;
            end
            index_x=floor(xx+1);
            index_y=floor(yy+1);
            proj(detector_index,angle_index)=proj(detector_index,angle_index)+l(i)*ph(index_y,index_x);
            weight_map(index_y,index_x,angle_index)=weight_map(index_y,index_x,angle_index)+l(i);
        end
    end
end
toc