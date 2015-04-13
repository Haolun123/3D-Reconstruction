
function y=mygraycodex
%
X_Axis=0;
Y_Axis=1;

%%

pathName = '';
baseFileName_01 = 'Capture';

imgType = '.bmp';

codewidth = 5;

pitchWidth01 = 23;
pitchWidth02 = 40;
%Choose ONLY ONE fringe direction: X_Axis or Y_Axis;
Fringe_Direction=X_Axis;%X_Axis: Horizontal
%Fringe_Direction=Y_Axis;%Y_Axis: Vertical

%%

for i = 1:codewidth;
            
    img2Read = strcat(pathName,baseFileName_01,num2str(i),imgType);
	eval(['img01_' num2str(i,'%02d') ' = imread(img2Read);']);
    j=eval(['img01_' num2str(i,'%02d')]);
	eval(['bw_' num2str(i,'%02d') ' = im2bw(j(:,:,1),0.3);']);
end;
Resolution = size(bw_01);
resX = Resolution(2);
resY = Resolution(1);
G1=zeros(resY,resX);
G2=zeros(resY,resX);
G3=zeros(resY,resX);
G4=zeros(resY,resX);
G5=zeros(resY,resX);
K=zeros(resY,resX);

	    G1=bw_01;
		G2=xor(G1,bw_02);
		G3=xor(G2,bw_03);
		G4=xor(G3,bw_04);
		G5=xor(G4,bw_05);
		K=G1*2^4+G2*2^3+G3*2^2+G4*2+G5;

y=K;

	       