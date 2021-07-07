close all;
clearvars;
clc

x = 0:63;

bin_x = dec2bin(x);

flip_bin_x = fliplr(bin_x);

y = bin2dec(flip_bin_x);

fileID = fopen('fft_input_reorganization.txt','w');

for i = 1:length(y)
    fprintf(fileID,"assign xm_real[0][%d] = data_in[%d * 16 +: 16];\n",i-1, y(i));
end

fclose(fileID);



