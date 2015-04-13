
function y=phaseplate
%
X_Axis=0;
Y_Axis=1;

%%

pathName = '';
baseFileName_01 = 'plate';

imgType = '.bmp';
stepNum01=4;

%Choose ONLY ONE fringe direction: X_Axis or Y_Axis;
Fringe_Direction=X_Axis;%X_Axis: Horizontal
%Fringe_Direction=Y_Axis;%Y_Axis: Vertical


%%

shiftedPhase01 = 2*pi/stepNum01;


        for i = 1:stepNum01;
            
            img2Read = strcat(pathName,baseFileName_01,num2str(i),imgType);
            eval([ 'j' ' = imread(img2Read);']);
          eval([ 'img01_' num2str(i,'%02d') '=double(j(:,:,1));']);
            
        end;
          
        size_img_read = size(img01_01);
        resY = size_img_read(1);
        resX = size_img_read(2);

%%
%Phase Retrieval
        
        sinTerm01 = zeros(resY,resX);
        cosTerm01 = zeros(resY,resX);
        
        for i = 1:stepNum01;
            
            eval(['sinTerm01 = sinTerm01 + img01_' num2str(i,'%02d') ' * sin(shiftedPhase01 * i) ;' ]);
            eval(['cosTerm01 = cosTerm01 + img01_' num2str(i,'%02d') ' * cos(shiftedPhase01 * i) ;' ]);           
            
        end;

        phase_Wrapped01 = atan2(sinTerm01,cosTerm01);
        
        modulation01 = (2/stepNum01) * sqrt(sinTerm01.^2+cosTerm01.^2);
 
        figHandle = figure;
        set(figHandle, 'name','Phase_Wrapped');
        imshow(phase_Wrapped01(:,:),[]),title('Phase_Wrapped');
        
     
R=phase_Wrapped01;        
x=2*pi;
T=graycodeplate;
for i=1:resX;
    for j=1:resY-1;
        if T(j,i)==T(j+1,i)&&R(j+1,i)-R(j,i)>=pi;
            T(j+1,i)=T(j+1,i)-1;
        else if T(j,i)==T(j+1,i)+1&&R(j+1,i)-R(j,i)<pi;
                T(j+1,i)=T(j+1,i)+1;
            else if T(j,i)==T(j+1,i)-1;;
                    T(j+1,i)=T(j,i);
                end;
            end;
        end;
    end;
end;
phase=phase_Wrapped01+x*T;
figHandle = figure;
        set(figHandle, 'name','Phase_Wrapped');
        imshow(phase(:,:),[]),title('Phase_plate');
y=phase;