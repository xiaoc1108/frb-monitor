close all;
clearvars;
clc;

load('prototypeFIR_coeffs.mat');

coeffs = prototypeFIR_coeffs;
coeffs = round(coeffs*(2^15));

% fileID = fopen('coeffs.txt','w');
% 
% for i = 1:length(coeffs)
%     if(coeffs(i) >= 0)
%         fprintf(fileID,"%d: get_coeffs = 'd%d;\n",i-1, coeffs(i));
%     else
%         fprintf(fileID,"%d: get_coeffs = -'d%d;\n",i-1, abs(coeffs(i)));
%     end
% end
% 
% fclose(fileID);

coeffs = reshape(coeffs,64,[]);
max_input = 2^15-1;
for k=1:64
    max_output(k) = max_input * sum(abs(coeffs(k,:)));
end

max_mamx_output = max(max_output);

bin_x = dec2bin(max_mamx_output);
length(bin_x)