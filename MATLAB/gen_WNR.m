close all;
clearvars;
clc;
n=64;

for i=1:n/2
    wnr_real(i)=cos(-2*pi*(i-1)/n);  %正变换用到的旋转因子实部
    wnr_imag(i)=sin(-2*pi*(i-1)/n);    %正变换用到的旋转因子虚部
end

wnr_real=wnr_real*2^13;
wnr_real=int16(wnr_real);

wnr_imag=wnr_imag*2^13;
wnr_imag=int16(wnr_imag);

fileID_real = fopen('wnr_real.txt','w');
fileID_imag = fopen('wnr_imag.txt','w');

for i = 1:n/2
    if wnr_real(i) >= 0
        fprintf(fileID_real,"%d: get_wnr_real = 'd%d;\n",i-1, wnr_real(i));
    else
        fprintf(fileID_real,"%d: get_wnr_real = -'d%d;\n",i-1, abs(wnr_real(i)));
    end
    if wnr_imag(i) >= 0
        fprintf(fileID_imag,"%d: get_wnr_imag = 'd%d;\n",i-1, wnr_imag(i));
    else
        fprintf(fileID_imag,"%d: get_wnr_imag = -'d%d;\n",i-1, abs(wnr_imag(i)));
    end
end

fclose(fileID_real);
fclose(fileID_imag);