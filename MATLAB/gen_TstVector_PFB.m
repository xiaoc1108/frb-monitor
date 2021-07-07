clearvars;
close all;
clc;

%x = 0:8192-1;
fs = 312.5e6;
nof_samples = 8192 * 16;
t = 0: 1/fs: nof_samples/fs - 1/fs;
f = 40e6;
x = sin(2*pi*f*t);
x = floor(x * 2^15);
decimate_factor = 16;
x = downsample(x,16);

max(x)

nof_loop = length(x)/16*decimate_factor;
x = reshape(x,16,[]);
x = flipud(x);

% write test vector to .coe file
fileID = fopen('testVector.txt','w');

m = 1;
for i=1:nof_loop
    if(mod(i,decimate_factor) == 1)
        sample = x(:,m);
        m = m + 1;
    else
        sample = zeros(16,1);
    end
    sample_hex = dec2hex(sample,4);
    str = strcat(sample_hex(1,:),sample_hex(2,:),sample_hex(3,:),...
        sample_hex(4,:),sample_hex(5,:),sample_hex(6,:),...
        sample_hex(7,:),sample_hex(8,:),sample_hex(9,:),...
        sample_hex(10,:),sample_hex(11,:),sample_hex(12,:),...
        sample_hex(13,:),sample_hex(14,:),sample_hex(15,:),...
        sample_hex(16,:));

    fprintf(fileID,'%s',str);
    fprintf(fileID,'\n');

end


fclose(fileID);
