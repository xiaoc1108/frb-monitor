%% Script description
% Script: FRB capture system simulation

% Feature: Do digital signal processing for the input signal,find target
% linear chirp, calculate de-dispersed SNR.

% Input of this script: linear chirp from 725 MHz to 625 MHz

% Script outline: 1.generate input signal; 2.bandpass filtering 3. Downsampling; 4.Use PFB to
% generate spectrum; 5.Moving average; 6.Incoherent-dedispersion; 7.Sum
% channels to find trigger; 8.Triggering and SNR calculation.


%% Script initialization
clc;
clear;
close all;
load('bp_filter');


%% General settings
Vn_rms_init = 0.0721;
Pn_init = ((Vn_rms_init)^2)/50;
trigger_level = 13.2;             % in which SNR level to trigger (in dB) 
threshold = Vn_rms_init*sqrt(10^(trigger_level/10));
trigger_time = 0;               % create a variable to save the time of triggering, default: 0 
trigger_cnt = 0;               % indicate trigger or not, when trigger_cnt>= 3, we have the trigger
snapshot_flag = 0;              % snapshot flag
no_trigger_cnt = 0;            % flag for no trigger 
trigger_number = 0;             % record how many times it was triggered
shift_number = 1;               % check how many times of shift is performed
average_factor = 256;            % moving average span. (only allow odd number), better to be close to power of 2


%% Test program initialization
SNR_db = -3;           %% set the input signal's SNR
R=50;                  %% ADC resistance
SNR_max = 10;          

 % %baseline noise value from the pure noise input scenario
 % % modify these two values if change the input SNR
base_rms = 6.9728e-06;
base_std = 7.0162e-06;

% % calculate Vn rms
%Vn_rms = 0.45/(sqrt(SNR_max*2)+5);
Vn_rms = 0.1;
Pn= (Vn_rms)^2 /R;                 %% unit: W
Pn_dbm = 10*log10(Pn)+30;

% % calculate Vs peak
SN_ratio = 10^(SNR_db/10);
Vs_rms = Vn_rms * sqrt(SN_ratio);
Ps_max = Pn*SN_ratio;
Ps_max_dbm = 10*log10(Ps_max)+30;
Vs_pk = Vs_rms * sqrt(2);                       % peak amplitude of chirp/FRB/sine



%% generate input signal
fs = 5000*1e6;            % 5G Hz Sampling rate
t_samp = 1/fs;         % resulting time sample

fc = 625*10^6; %[Hz], centre frequency                        
T_tot = 5*1e-3;
t = 0:t_samp:T_tot;

sig = chirp(t,725*1e6,T_tot,625*1e6);

length_extra =  length(sig);                                
sig_extra = zeros(1,1*(length_extra-1));                % add an extra length of zeros after chirp signal
sig = [sig sig_extra];
t = 0:t_samp:2*T_tot;

% normalization
sig = 2*(sig-min(sig))/(max(sig)-min(sig))-1;

sig_1 = 1*sin(2*pi*4.8828125*1e6*t);
sig_2 = sin(2*pi*21.9726*1e6*t);

% add noise           
noise = normrnd(0,Vn_rms,[1,length(t)]);   
%noise = normrnd(0,1,[1,length(t)]);        
%noise = zeros(1,length(t));

     sig = sig * Vs_pk;
     %sig = sig_1;
     sig =  sig + noise; 
     %sig = noise;

plotPlus(sig,t,fs,'Input signal');                       % plot in time domain & frequency domain

figure;
spectrogram(sig,256,128,256,fs,'yaxis');         % Time vs frequency     
title('Frequency vs Time: raw signal');

initial_power = mean((sig.^2)/R)
Vrms = sqrt(initial_power*R)
initial_dbm = 10*log10(initial_power/(1*1e-3))

%% bandpass filter

sig = filter(bp,1,sig);
plotPlus(sig,t,fs,'filter result');
after_bp_power = mean((sig.^2)/R)
Vn_rms_bp = sqrt(after_bp_power * R)
bp_dbm = 10*log10(after_bp_power/(1*1e-3))


%% downsampling 
Sample_skip = 16;
sig_downsp =downsample(sig,Sample_skip);                   % downsampling input signal
t_1 = downsample(t,Sample_skip);                           % downsampling time
fs2 = fs/Sample_skip;                                      % New fs 
sig_length = length(sig)/fs2;                              % total time length of the input signal 
plotPlus(sig_downsp,t_1,fs2,'input fake FRB (After downsampling, fs = 312.5 MHz)');    
sig = sig_downsp;


%% M channel PFB setting
M = 128;                                                   % channel number
D = 64;                                                   % decimation number
load('312mhz_128ch_512taps');                                   % load prototype filter coefficients
h = reshape(M*[ coeffs ],M,[]);
NN = 27;
ch_start = 27;
ch_stop = 53;
%h = round(h * 2^15 -1);


fs3 = fs2/D;                                              % New fampling frequency after PFB
t_2 = 0:1/fs3:(round(length(sig)/D)-1)*1/fs3;                       


%% average time

% average time
t_sum = zeros(1,1);
t_average = zeros(1,floor(round(length(sig)/D)/average_factor));
for i = 1: round(length(sig)/D)
    if mod(i,average_factor)~=0 
      t_sum = t_2(i) + t_sum;
    else
        t_sum = t_2(i) + t_sum;
        t_average(i/average_factor) = t_sum/average_factor;
        t_sum = zeros(1,1);
    end
end

f_average = 1/(t_average(2)-t_average(1));



%% Preparation for incoherent dedispersion
% Dedispersion: delay higher frequencies to f_stop

frequencies = zeros(1,M);
for i = 1: M
    frequencies(i) = ((i-1)*(fs3/2/1e6));                    %calculate centre frequencies for each channel
end

% delay calculation: 
delays = zeros(1,M);


for i = 1:M/2
   delays(i) = (5*1e-3) - ((frequencies(i)-100)/(-20000));   %FRB delay
end


delays_in_us = delays/1e-6;
delay_units = zeros(1,M);

for i = 1:M/2                                                              % convert time of delay to clock cycles of delay 
     %delay_units(i) = round(delays(i)/(t_average(2)-t_average(1))); 
     delay_units(i) = round(delays(i)/(t_average(2)-t_average(1))); 
%      if delay_units(i) <0
%          delay_units(i)=0;
%      end
end
delay_units = delay_units +1;



%% Pipeline 2.0
% PFB initialization
inputDat = zeros(D,1);
inputDatBuf = zeros(M,size(h,2));
filtOutBuf = zeros(M,1);
chanOut = zeros(M,1);
chanOutBuf = zeros(M,round(length(sig)/D));
flag = 0;


nof_samples = length(sig);
nof_clk = floor(nof_samples/D);
de_dispersed_data = zeros(D,1);
de_dispersed_data_plot = zeros(D,length(t_average));

% average filterbank
sum_average = zeros(D,1);
fifo_average = cell(D,1);
for k=1:D
    fifo_average{k,1} = zeros(1,average_factor);
end
chanOutBuf_average_plot = zeros(M,length(t_average));
fifo_delay = cell(D,1);
for i=1:D
    fifo_delay{i,1} = zeros(1,delay_units(i));
end
chanOutBuf_sum = zeros(M,1);
flux_plot = zeros(1,length(t_average));
trigger_SNR = zeros(1,length(t_average));                         % vector to store SNR of matched filter result
cnt = 1;


%% PFB loop implementation
for clk=1:nof_clk
    inputDat = fliplr(sig((clk-1)*D+1:clk*D)).';
    inputDatBuf = [inputDatBuf(D+1:M,:);inputDatBuf(1:D,:)];
    inputDatBuf(1:D,:) = [inputDat inputDatBuf(1:D,1:size(h,2)-1)];
    for k=1:M
        filtOutBuf(k) = inputDatBuf(k,:)*h(k,:)';
    end
    if(flag == 0)
        flag = 1;
    else
        flag = 0;
        filtOutBuf = [filtOutBuf(D+1:M);filtOutBuf(1:D)];
    end
%     filtOutBuf = filtOutBuf/(2^10);                 % we have 10bits truncation here in FPGA
%     chanOut = fft(filtOutBuf,M)/(2^8);           % we have 8bits truncation here in FPGA    
    chanOut_1 = fft(filtOutBuf,M)/M;           % we have 8bits truncation here in FPGA    
    %chanOut_1 = fft(filtOutBuf,M);           % we have 8bits truncation here in FPGA    
    %chanOut = abs(chanOut_1);    % get the power spectrum
    chanOut = (chanOut_1);
    
    chanOutBuf(:,clk) = (chanOut);
    
        % average PFB out
    if mod(clk,average_factor)~=0 
      chanOutBuf_sum = chanOut + chanOutBuf_sum;
    else
        chanOutBuf_sum = chanOut + chanOutBuf_sum;
        chanOutBuf_average_data = chanOutBuf_sum/average_factor;
        %chanOutBuf_average_data = floor(chanOutBuf_sum/average_factor);
        chanOutBuf_average_plot(:,clk/average_factor) = chanOutBuf_average_data;
        chanOutBuf_sum = zeros(M,1);
        
    % De-dispersion
    for k=1:D
        fifo_delay{k,1}(length(fifo_delay{k,1})+1) = chanOutBuf_average_data(k);
        fifo_delay{k,1}(1) = [];
        de_dispersed_data(k) = fifo_delay{k,1}(1);
    end    
    cnt = cnt+1;
    de_dispersed_data_plot(:,clk/average_factor) = de_dispersed_data;
    
    
        % Channel Sum
    flux = sum((de_dispersed_data));
    flux_plot(:,(clk/average_factor)) = flux;
  
    %% triggering

% triggering
trigger_SNR(ceil(clk/average_factor)) = 10*log10((flux-(8.5472e-04))/1.8863e-04);
% if trigger_SNR(ceil(clk/average_factor)) >= trigger_level
if trigger_SNR(ceil(clk/average_factor)) >= (trigger_level)
    trigger_cnt = trigger_cnt +1;
    trigger_number = trigger_number +1;              % check how many times of triggers we have 
    no_trigger_cnt = 0;
else 
    trigger_cnt = 0;
    no_trigger_cnt = no_trigger_cnt +1;
end

if trigger_cnt == 3                             % only when we have 3 consecutive triggers, we consider there is a valid trigger
        trigger_time = clk*(1/fs3);               % save the trigger time, unit: s
        %candidate1 = snapshot(sig_downsp,T_tot,sig_length,0.2,trigger_time,fs2,snapshot_flag);  % get candidate
        str = sprintf('-----Possible candidate detected at %d s-----',trigger_time);
        disp(str);
        %figure;
        %spectrogram(candidate1,256,128,256,fs2,'yaxis');         % Time vs frequency     
        %title('Frequency vs Time: candidate snapshot');
end

if no_trigger_cnt == 3
    trigger_time = 0;
    disp('-----No candidate detected-----');
end  

    end

% show percentage of completion
if mod(clk,5/100*nof_clk)==0
percentage = clk/nof_clk * 100;
str_p = sprintf('-----Loop completion: %d%%-----',round(percentage));
disp(str_p);
end

end

%  calculate dispersed sum
dispersed_sum = zeros(1,size(chanOutBuf_average_plot,2));

for i = 1:D
dispersed_sum = dispersed_sum + (chanOutBuf_average_plot(i,:));
end


%  calculate unaveraged dispersed sum
dispersed_sum_unav = zeros(1,size(chanOutBuf,2));

for i = 1:D
dispersed_sum_unav = dispersed_sum_unav + (chanOutBuf(i,:));
end


%% plot results

figure;
for i = 1:D
   plot(t_average*1e3,abs(de_dispersed_data_plot(i,:)).^2);
   hold on;
end 
title('Averaged de-dispersed signal for 128 channels');
xlabel('Time (ms)'); 
ylabel('Power (W)');


figure;
for k=2:D
    plot(t_2*1e3,abs(chanOutBuf(k,:)).^2); hold on;
end
xlabel('Time (ms)');ylabel('Power (W)');
title('polyphase filterbank output');

figure;
plot(t_average*1e3,(abs(flux_plot)));
hold on;
str = sprintf('De-dispersed series when input SNR = %d dB', SNR_db);
title(str);
% p1 =[0,threshold];
% p2 =[t_average(end)*1e3,threshold];
% plot([p1(1),p2(1)],[p1(2),p2(2)],'Color','r','LineWidth',2)
xlabel('Time (ms)'); 
ylabel('Power (W)');



% plot dispersed sum
figure;
plot(t_average*1e3,(abs(dispersed_sum)).^2);
title('Dispersed series');
xlabel('Time (ms)'); 
ylabel('Power (W)');

% plot original signal (dispersed)
figure;
for i = 1:D
   plot(t_average*1e3,abs(chanOutBuf_average_plot(i,:)).^2);
   hold on;
end
title('Averaged dispersed signal for 128 channels');
xlabel('Time (ms)'); 
ylabel('Power (W)');


max_flux_ddp = max(abs(flux_plot).^2);
max_flux_disp = max(abs(dispersed_sum).^2);
max_flux = max(max_flux_ddp,max_flux_disp);

% Final Plot: dispersion vs de-dispersion
figure;
subplot(2,2,1);
% plot dispersed sum
plot(t_average*1e3,abs(dispersed_sum).^2);
title('Dispersed series');
xlabel('Time (ms)'); 
ylabel('Power (W)');
% xlim([0 15]);
ylim([0 1.2*max_flux]);


subplot(2,2,2);
plot(t_average*1e3,abs(flux_plot).^2);
str = sprintf('De-dispersed series');
title(str);
xlabel('Time (ms)'); 
ylabel('Power (W)');
% xlim([0 22]);
ylim([0 1.2*max_flux]);


subplot(2,2,3);
imagesc(t_average*1e3,frequencies,abs(chanOutBuf_average_plot(1:D,:)).^2);
set(gca,'YDir','normal') ;
title('Dispersed signal');
xlabel('Time (ms)'); 
ylabel('Frequency (MHz)');
%xlim([0 10]);


subplot(2,2,4);
imagesc(t_average*1e3,frequencies,abs(de_dispersed_data_plot).^2);
set(gca,'YDir','normal') ;
title('De-dispersed signal');
xlabel('Time (ms)'); 
ylabel('Frequency (MHz)');
%xlim([0 10]);


figure;
subplot(1,2,1);
% plot dispersed sum
plot(t_average*1e3,abs(dispersed_sum).^2);
title('Dispersed series');
xlabel('Time (ms)'); 
ylabel('Power (W)');
% xlim([0 15]);
ylim([0 1.2*max_flux]);


subplot(1,2,2);
plot(t_average*1e3,abs(flux_plot).^2);
str = sprintf('De-dispersed series');
title(str);
xlabel('Time (ms)'); 
ylabel('Power (W)');
% xlim([0 22]);
ylim([0 1.2*max_flux]);


figure;
plot(t_average*1e3,abs(flux_plot).^2);
str = sprintf('De-dispersed series');
title(str);
xlabel('Time (ms)'); 
ylabel('Power (W)');
ylim([0 1.2*max_flux]);


%% check particulate channel result (if necessary)
max_pfb = zeros(1,D);
for i = 9:14
max_pfb(i) = max(max(chanOutBuf(i,:)));
end
max_pfb_value = max(abs(max_pfb)).^2;

%  figure;
%  ha1 = tight_subplot(8,1,[.01 .03],[.1 .01],[.05 .05]);
%  for ii = 1:8 
%      axes(ha1(ii)); 
%      plot(t_2*1e3,(chanOutBuf(15-ii,:)));
%      str2 = sprintf('Ch. %d',Ch_num(ii));
%      ylabel(str2);
%      ylim([0 1.2*max_pfb_value]);
%  end
%  set(ha1(1:7),'XTickLabel',''); 
%   xlabel('Time(ms)'); 
%  set(ha1,'YTickLabel','');
 
%  figure;
%  subplot(3,2,1);
%  plot(t_2*1e3,abs(chanOutBuf(14,:)).^2);       % check channel 14
%  title('Channel 14');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%   subplot(3,2,2);
%  plot(t_2*1e3,abs(chanOutBuf(13,:)).^2);       % check channel 13
%  title('Channel 13');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%    subplot(3,2,3);
%  plot(t_2*1e3,abs(chanOutBuf(12,:)).^2);       % check channel 12
%  title('Channel 12');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%    subplot(3,2,4);
%  plot(t_2*1e3,abs(chanOutBuf(11,:)).^2);       % check channel 11
%  title('Channel 11');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%    subplot(3,2,5);
%  plot(t_2*1e3,abs(chanOutBuf(10,:)).^2);       % check channel 10
%  title('Channel 10');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%    subplot(3,2,6);
%  plot(t_2*1e3,abs(chanOutBuf(9,:)).^2);       % check channel 9
%  title('Channel 9');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);

%    subplot(8,1,7);
%  plot(t_2*1e3,(chanOutBuf(8,:)));       % check channel 8
%  title('Channel 8');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);
% 
%    subplot(8,1,8);
%  plot(t_2*1e3,(chanOutBuf(7,:)));       % check channel 7
%  title('Channel 7');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);


% figure;
% noise_ch50 = chanOutBuf(50,:);
% plotPlus(noise_ch50,t_2,fs3,'noise in channel 50');  

%  figure;
%  plot(t_2*1e3,abs(chanOutBuf(14,:).^2));       % check channel 14
%  title('PFB result: Channel 14');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value]);

%% check particulate channel result (if necessary)
max_pfb_av = zeros(1,D);
for i = 1:D
max_pfb_av(i) = max(max(chanOutBuf_average_plot(i,:)));
end
max_pfb_value_av = max(abs(max_pfb_av)).^2;


%   figure;
% ha2 = tight_subplot(8,1,[.01 .03],[.1 .01],[.05 .05]);
%  for ii = 1:8 
%      axes(ha2(ii)); 
%      plot(t_average*1e3,(chanOutBuf_average_plot(ch_stop+1-ii,:)));
%      str2 = sprintf('Ch. %d',Ch_num(ii));
%      ylabel(str2);
%      ylim([0 1.2*max_pfb_value_av]);
%  end
%  set(ha2(1:7),'XTickLabel',''); 
%   xlabel('Time(ms)'); 
%  set(ha2,'YTickLabel','');
 
% figure;
%  subplot(3,2,1);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(14,:)).^2);       % check channel 14
%  title('Ch14 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);
% 
%   subplot(3,2,2);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(13,:)).^2);       % check channel 13
%  title('Ch13 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);
% 
%    subplot(3,2,3);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(12,:)).^2);       % check channel 12
%  title('Ch12 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);
% 
%    subplot(3,2,4);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(11,:)).^2);       % check channel 11
%  title('Ch11 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);
% 
%    subplot(3,2,5);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(10,:)).^2);       % check channel 10
%  title('Ch10 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);
% 
%    subplot(3,2,6);
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(9,:)).^2);       % check channel 9
%  title('Ch9 with averaging');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);

% % 
% %    subplot(8,1,7);
% %  plot(t_average*1e3,(chanOutBuf_average_plot(8,:)));       % check channel 8
% %  title('Channel 8');
% %  xlabel('Time(ms)'); 
% % ylabel('Power (W)');
% % ylim([0 1.2*max_pfb_value_av]);
% % 
% %    subplot(8,1,8);
% %  plot(t_average*1e3,(chanOutBuf_average_plot(7,:)));       % check channel 7
% %  title('Channel 7');
% %  xlabel('Time(ms)'); 
% % ylabel('Power (W)');
% % ylim([0 1.2*max_pfb_value_av]);

% figure;
%  plot(t_average*1e3,abs(chanOutBuf_average_plot(14,:)).^2);       % check channel 14
%  title('PFB result with averaging: Channel 14');
%  xlabel('Time(ms)'); 
% ylabel('Power (W)');
% ylim([0 1.2*max_pfb_value_av]);

%% dispersed series SNR calculation
[M_dispersed,I_dispersed] = max(abs(dispersed_sum));
start_index_dispersed = I_dispersed + round(4*1e-3/(1/f_average));
stop_index_dispersed = length(dispersed_sum);

% baseline of the Dispersed time series: rms&std
base_rms_dispersed = rms(dispersed_sum(start_index_dispersed:stop_index_dispersed));
base_std_dispersed = std(dispersed_sum(start_index_dispersed:stop_index_dispersed));

% SNR
Mean_disp = mean(abs(dispersed_sum(1:round(2.8*1e-3/(1/f_average)))));
disp_SNR = (Mean_disp - base_rms_dispersed)/base_std_dispersed
disp_SNR_dB = 10*log10(disp_SNR)


%% de-dispersed SNR calculation

[MM,I] = max(abs(flux_plot).^2);
I = 96;
MM = abs(flux_plot(I).^2);


% start_index = I + round(1*1e-3/(1/f_average));
% stop_index = length(flux_plot);
% %baseline of the De-dispersed time series: rms&std
% base_rms = rms(flux_plot(start_index:stop_index).^2);
% base_std = std(flux_plot(start_index:stop_index).^2);

% SNR
ddp_SNR_max = (MM - base_rms)/base_std
ddp_SNR_max_dB = 10*log10(ddp_SNR_max)


%% power calculation

% power_perChannel = zeros(M,1);
% for i = 1:M
%    power_perChannel(i) = mean(abs(chanOutBuf_average_plot(i,:)).^2/R); 
% end
% 
% mean_power = mean(power_perChannel)
% input_power = mean((sig.^2)/R)
% ideal_power = input_power/M
% sum_power = sum(power_perChannel)