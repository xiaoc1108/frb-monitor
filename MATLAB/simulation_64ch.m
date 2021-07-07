% Simulate FPGA system
% Can be used as a reference to compare with FPGA result
% Created: Xiao Chen, 2021/07/03
% Modified: Xiao Chen, 2021/07/03
close all;
clearvars;
clc

%% Parameters (do not modify)
fs = 5e9;                                         % sampling frequency
M = 64;                                             % number of polyphase filterbank channels
D = 32;                                             % polyphase filterbank downsample factor
load('prototypeFIR_coeffs.mat');                                % polyphase filterbank prototype filter coefs

%% Settings
% Signal
nof_target_samples = 8192*16;                          % number of target samples (multiple of D), in this case the target is chirp
f_chirp_start = 20e6;                             % the start frequency of chirp
f_chirp_stop = 80e6;                               % the stop frequency of chirp
f_chirp_width = nof_target_samples/fs-1/fs;         % the width of target signal, in this case the target is chirp

% ADC
actual_analog_range = 1;                            % Vpp = 1

%% generate test data
t = 0:1/fs:nof_target_samples/fs-1/fs;
signal = chirp(t,f_chirp_start,f_chirp_width,f_chirp_stop);
%signal = [zeros(1,nof_target_samples) chirp(t,f_chirp_start,f_chirp_width,f_chirp_stop) zeros(1,nof_target_samples)];
% f = 60e6;
% signal = sin(2*pi*f*t);
analog_level = (actual_analog_range/2)*signal;
digital_code_level = round(analog_level/(actual_analog_range/2)*(2^14)); % should be 2^15, but there is a bug when use 2^15 to generate test signal
digital_code_level = downsample(digital_code_level,16);
nof_samples = length(digital_code_level);
t = 0:1/fs:nof_samples/fs-1/fs;

figure;
plot(t,digital_code_level);
xlabel('time/s');ylabel('digital level');
title('original signal');

N = length(digital_code_level);
N_2 = ceil(N/2);
fax_Hz = (0:N-1)*(fs/N);
fftsig = fft(digital_code_level);
figure;
plot(fax_Hz(1:N_2)/1e6,abs(fftsig(1:N_2))); grid on;
title('original signal magnitude spectrum');
xlabel('frequency/MHz'); ylabel('magnitude');


%% Initialization
% polyphase filterbank prototype filter coefs
h = prototypeFIR_coeffs;
h = round(h*2^15);
h = reshape(h,M,[]);

% polyphase filterbank buffers
input_data_buffer = zeros(M,size(h,2));
fir_data_out = zeros(M,1);
circular_shift_flag = 0;

% clock
nof_clk = nof_samples/D;
mm = 1;
cnt = 1;
pfb_data_out_plot = zeros(D,nof_clk);

%% Digital Signal Processing
for clk = 1:nof_clk
    % PFB
    input_data = fliplr(digital_code_level((clk-1)*D+1:clk*D)).';
    input_data_buffer = [input_data_buffer(D+1:M,:);input_data_buffer(1:D,:)];
    input_data_buffer(1:D,:) = [input_data input_data_buffer(1:D,1:size(h,2)-1)];
    for k=1:M
        fir_data_out(k) = input_data_buffer(k,:)*h(k,:)';
    end
    if(circular_shift_flag == 0)
        circular_shift_flag = 1;
    else
        circular_shift_flag = 0;
        fir_data_out = [fir_data_out(D+1:M); fir_data_out(1:D)];
    end
    
    pfb_data_out = fft(fir_data_out,M);
    %pfb_data_out = abs(real(pfb_data_out(1:D)));
    pfb_data_out = abs(round(real(pfb_data_out(1:D))));
    pfb_data_out_plot(:,clk) = pfb_data_out;
end

%% data analysis
pfb_fc = zeros(1,D);
for k=1:D
    pfb_fc(k) = (k-1)*(fs/M);
end

figure;
for k=1:D
    plot(pfb_data_out_plot(k,:)); hold on;
end
hold off;
xlabel('time/s');ylabel('digital level');
title('polyphase filterbank output');

figure;
for k=1:size(pfb_data_out_plot,2)
    plot(pfb_fc/1e6,pfb_data_out_plot(:,k)); hold on;
end



