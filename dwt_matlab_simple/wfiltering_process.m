%%%
% One dwt filtering loop
% Result: entropys and psnrs, and a plot as well (in non-relaitve mode)
% Any number of bands, any filterbanks
% Up to 3 transform layers
%%%

clear all; % Use if you launch wfiltering directly

tictoc = false; % Time perfection measurement
plot_name = 'Simple';

im_name = '../Тестовые изображения/kiel.bmp';

layers = 1;

process_one_band = false;
% if true, it has to be in the last layer and have the following
% coordinates:
bandW = 3;
bandH = 2;
% 2 1
% 3 2
qf_n = 10; % Number of quantizing steps ( !! qf=1/quant_step !! )
qf_best = 0.3;  % Bounds
qf_worst = 0.01;
qf_list = 10.^(linspace(log10(qf_best), log10(qf_worst),qf_n));

% nz_extension for layer
%   == 1.0 is regular quantization
null_zone_extension_1 = 1.0;
null_zone_extension_2 = 1.0;
null_zone_extension_3 = 1.0;
% qf_extension for layer 
%   == 0 means no quantization (no contribition to psnr) 
%               and no contribution to entropy
qf_extension_1 = 1.0;
qf_extension_2 = 1.0;
qf_extension_3 = 1.0;

line_type = 'o-';

% If you don't have psnr() function
psnr=@(or,re,mx)20*log10(mx./rms(double(or(:))-double(re(:))));

if tictoc
    disp(plot_name);
    tic
end

% Halfs of direct (a) and inverse (b) filterbanks
a__= [  12 0.7172150000	0.4821190000	0.1007850000	-0.0572617000	-0.0434293000	-0.0025706500	0.0076218200	0.0016123000	0.0009144900	0.0001070570	-0.0004118280	0.0000812236
        12 0.0000000000	-0.6879050000	0.0528450000	0.1928270000	-0.0239495000	0.0337432000	-0.0031931300	-0.0082939700	0.0008158960	-0.0000712195	0.0002739660	-0.0000540336
        12 0.6853030000	-0.4999470000	0.1461390000	0.0322635000	-0.0249847000	0.0092418300	-0.0046033700	-0.0002193460	-0.0006710620	-0.0000620485	0.0002386880	-0.0000470757];
b__=[   7 0.6636790000	0.4996830000	0.1553180000	-0.0494516000	-0.0573942000	-0.0081058900	0.0123629000
        7 0.0000000000	0.6880630000	0.0473184000	-0.1537010000	-0.0260899000	-0.0047508900	0.0015184900
        7 0.6624620000	-0.5099850000	0.0954987000	0.0783513000	-0.0690810000	-0.0085326700	0.0195878000];

% If no analysis is performed, there is one band
if layers>0
    N=3;
else
    N=1;
end

% Symmetrical (1) of anti-symmetrical (-1) filter expansion
sym_coef = [1 -1 1];
dir_filter=[a__(:,end:-1:3).*sym_coef.', a__(:,2:end)];
inv_filter=[b__(:,end:-1:3).*sym_coef.', b__(:,2:end)];
% Normalizing
inv_norm = sqrt(sum(inv_filter.^2,2));
dir_filter=dir_filter.*inv_norm;
inv_filter=inv_filter./inv_norm;

% The response of LL to prior shift
delta = sum(dir_filter(1,:))^2; 

% Image taken from test file
original=rgb2gray(importdata(im_name));

% layers = 0;
[h_or, w_or]=size(original);

% DWT layer by layer
dwt_tree = original;
if layers>=1
    dwt_tree = dwt(original, dir_filter, 0);
    [h_1, w_1]=size(dwt_tree{1});     
end
if layers>=2
    dwt_tree{1} = dwt(dwt_tree{1}, dir_filter, 0);
    [h_2, w_2]=size(dwt_tree{1}{1});     
end
if layers>=3
    dwt_tree{1}{1} = dwt(dwt_tree{1}{1}, dir_filter, 0);
    [h_3, w_3]=size(dwt_tree{1}{1}{1});     
end

psnrs = zeros(qf_n, 1);
entropys = zeros(qf_n, 1);
%{
qf_i = 0;
for qf = qf_list % 1/(шаг квантования)
    qf_i = qf_i+1;
    dwt_tree_r = dwt_tree;
    
    if process_one_band || layers == 0     % quantize only the chosen band
        switch layers
            case 0
                qf_this = qf;
                null_zone_extension = 1.0;
                dwt_q = quant_z(dwt_tree_r, qf_this, null_zone_extension);
                dwt_tree_r = dequant_z(dwt_q, qf_this, null_zone_extension);
                entropys(qf_i) = entropy(dwt_q);
            case 1
                qf_this = qf*qf_extension_1;
                dwt_q = quant_z(dwt_tree_r{bandH, bandW}, qf_this, null_zone_extension_1);
                dwt_tree_r{bandH, bandW} = dequant_z(dwt_q, qf_this, null_zone_extension_1);
                entropys(qf_i) = entropy(dwt_q);
            case 2
                qf_this = qf*qf_extension_2;
                dwt_q = quant_z(dwt_tree_r{1}{bandH, bandW}, qf_this, null_zone_extension_2);
                dwt_tree_r{1}{bandH, bandW} = dequant_z(dwt_q, qf_this, null_zone_extension_2);
                entropys(qf_i) = entropy(dwt_q);
            case 3
                qf_this = qf*qf_extension_3;
                dwt_q = quant_z(dwt_tree_r{1}{1}{bandH, bandW}, qf_this, null_zone_extension_3);
                dwt_tree_r{1}{1}{bandH, bandW} = dequant_z(dwt_q, qf_this, null_zone_extension_3);
                entropys(qf_i) = entropy(dwt_q);                
        end
        
    else                        % quantize all band buy band
        
        entropys(qf_i) = 0;
        
        % L3: quantization, storing
        if layers >= 3 && qf_extension_3 ~= 0
            qf_this = qf*qf_extension_3;
            null_zone_extension_this = null_zone_extension_3;
            if layers == 3 
                n_b_v = 1:9;
            else
                n_b_v = 2:9;
            end
            for n_b = n_b_v
                dwt_q = quant_z(dwt_tree_r{1}{1}{n_b}, qf_this, null_zone_extension_this);
                dwt_tree_r{1}{1}{n_b} = dequant_z(dwt_q, qf_this, null_zone_extension_this);
                entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
            end
        end

        % L2: quantization, storing
        if layers >= 2 && qf_extension_2 ~= 0
            qf_this = qf*qf_extension_2;
            null_zone_extension_this = null_zone_extension_2;
            if layers == 2 
                n_b_v = 1:9;
            else
                n_b_v = 2:9;
            end
            for n_b = n_b_v
                dwt_q = quant_z(dwt_tree_r{1}{n_b}, qf_this, null_zone_extension_this);
                dwt_tree_r{1}{n_b} = dequant_z(dwt_q, qf_this, null_zone_extension_this);
                entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
            end
        end

        % L1: quantization, storing
        if layers >= 1 && qf_extension_1 ~= 0
            qf_this = qf*qf_extension_1;
            null_zone_extension_this = null_zone_extension_1;
            if layers == 1
                n_b_v = 1:9;
            else
                n_b_v = 2:9;
            end
            for n_b = n_b_v
                dwt_q = quant_z(dwt_tree_r{n_b}, qf_this, null_zone_extension_this);
                dwt_tree_r{n_b} = dequant_z(dwt_q, qf_this, null_zone_extension_this);
                entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
            end
        end     
    end
    % IDWT layer by layer
    if layers>=3
        dwt_tree_r{1}{1} = idwt(dwt_tree_r{1}{1}, inv_filter, 0, sym_coef, h_2, w_2);
    end
    
    if layers>=2
        dwt_tree_r{1} = idwt(dwt_tree_r{1}, inv_filter, 0, sym_coef, h_1, w_1);
    end
    
    if layers>=1
        dwt_tree_r = idwt(dwt_tree_r, inv_filter, 0, sym_coef, h_or, w_or);
    end
    
    restored = dwt_tree_r;

    psnrs(qf_i) = psnr(original,restored,255);

end
% Plot

plot(entropys,psnrs,'-x','DisplayName', 'lin');
hold on
%}
%%{
%linear
qf_i = 0;
entropys = zeros(qf_n, 1);
for qf = qf_list
    qf_i = qf_i+1;
    dwt_tree_r = dwt_tree;
    qf_this = qf;
    
    if process_one_band == true
        n_b_v = bandH + 3*(bandW-1);
    else
        n_b_v = 1:9;
    end
    
    for n_b = n_b_v
        dbg = dwt_tree_r{n_b}*qf_this;
        maxZN = max(max(dbg));
        minZN = min(min(dbg));
        maxCodebook = round(maxZN);
        minCodebook = round(minZN);
        codebookLin = [minCodebook:1:maxCodebook];
        partitionLin = [minCodebook+0.5:1:maxCodebook-0.5];
        [dwt_q ,index] = imquantize(dbg, partitionLin, codebookLin);
        entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
        dwt_tree_r{n_b} = dwt_q/qf_this;
    end 
    dwt_tree_r = idwt(dwt_tree_r, inv_filter, 0, sym_coef, h_or, w_or);
    psnrs(qf_i) = psnr(original,dwt_tree_r,255);
end

plot(entropys,psnrs,'o-','DisplayName', 'newlin');
hold on
%}

%%{
%lloyds
qf_i = 0;
entropys = zeros(qf_n, 1);
for qf = qf_list
    qf_i = qf_i+1;
    dwt_tree_r = dwt_tree;
    qf_this = qf;
    if process_one_band == true
        n_b_v = bandH + 3*(bandW-1);
    else
        n_b_v = 1:9;
    end
    for n_b = n_b_v
        dbg = dwt_tree_r{n_b}*qf_this;
        maxZN = max(max(dbg));
        minZN = min(min(dbg));
        maxCodebook = ceil(maxZN);
        minCodebook = floor(minZN);
        codebookLin = [minCodebook:1:maxCodebook];
        partitionLin = [minCodebook+0.5:1:maxCodebook-0.5];
        training_set = dbg;
        [M,N] = size(training_set);
        training_set = reshape(training_set,N*M,1);
        [partitionLM, codebookLM] = lloyds(training_set, codebookLin);
        [dwt_q ,index] = imquantize(dbg, partitionLM, codebookLM);
        entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
        dwt_tree_r{n_b} = dwt_q/qf_this;
    end 
    dwt_tree_r = idwt(dwt_tree_r, inv_filter, 0, sym_coef, h_or, w_or);
    psnrs(qf_i) = psnr(original,dwt_tree_r,255);
end

plot(entropys,psnrs,'o-','DisplayName','LM');
hold on
%}
%%{
%newlloyds

qf_i = 0;
entropys = zeros(qf_n, 1);
for qf = qf_list
    qf_i = qf_i+1;
    dwt_tree_r = dwt_tree;
    qf_this = qf;
    if process_one_band == true
        n_b_v = bandH + 3*(bandW-1);
    else
        n_b_v = 1:9;
    end
    for n_b = n_b_v
        dbg = dwt_tree_r{n_b}*qf_this;
        maxZN = max(max(dbg));
        minZN = min(min(dbg));
        maxCodebook = ceil(maxZN);
        minCodebook = floor(minZN);
        codebookLin = [minCodebook:1:maxCodebook];
        partitionLin = [minCodebook+0.5:1:maxCodebook-0.5];
        training_set = dbg;
        [M,N] = size(training_set);
        training_set = reshape(training_set,N*M,1);
        [partitionECVQ, codebookECVQ] = newlloyds(training_set, codebookLin);
        [dwt_q ,index] = imquantize(dbg, partitionECVQ, codebookECVQ);
        entropys(qf_i) = entropys(qf_i) + entropy(dwt_q);
        dwt_tree_r{n_b} = dwt_q/qf_this;
%          PicLloyd = im2uint8(dwt_tree_r{n_b});
%          imshow(PicLloyd,[0,255])
    end 
    dwt_tree_r = idwt(dwt_tree_r, inv_filter, 0, sym_coef, h_or, w_or);
    psnrs(qf_i) = psnr(original,dwt_tree_r,255);
end
plot(entropys,psnrs,'x-','DisplayName', 'ECVQ');
%plot(entropys,psnrs,'x-','DisplayName',sprintf('%d * lambda',i));
hold on
%}
%{
hold on

psnrs = zeros(7, 1);
entropys = zeros(7, 1);

for s = 1:7
    for i = 1:3
         for j = 1:3
             len = 2.^s;
             [M,N] = size(dwt_tree{i, j});
             training_set = dwt_tree{i, j};
             training_set = reshape(training_set,N*M,1);
             [partition, codebook] = lloyds(training_set, len);
             [LP ,index] = imquantize(dwt_tree{i, j}, partition, codebook);
             dwt_tree_q{i, j} = LP;
             PicLloyd = im2uint8(LP);
             entropys(s) = entropys(s) + entropy(index);
%              imshow(PicLloyd,[0,255])
        end
    end
    dwt_tree_r = idwt(dwt_tree_q, inv_filter, 0, sym_coef, h_or, w_or);
    psnrs(s) = psnr(original,dwt_tree_r,255);
end

imshow(dwt_tree_r,[0,255])
plot(entropys,psnrs,line_type,'DisplayName',plot_name);
%}

xlabel('Энтропия, биты');
ylabel('PSNR, dB');
% title(titlelabel);
legend('Location','best');
axis tight
if tictoc 
    toc
end
