function [partition, codebook, distor, rel_distor] = newlloyds(training_set, ini_codebook, tol, plot_flag)
%LLOYDS Optimize quantization parameters using the Lloyd algorithm.
%   [PARTITION, CODEBOOK] = LLOYDS(TRAINING_SET, INI_CODEBOOK) optimizes the
%   scalar quantization PARTITION and CODEBOOK based on the provided training
%   vector TRAINING_SET using the Lloyd algorithm. The data in the variable
%   TRAINING_SET should be typical data for the message source to be quantized.
%   INI_CODEBOOK is the initial guess of the codebook values. The optimized
%   CODEBOOK has the same vector size as INI_CODEBOOK. When INI_CODEBOOK is a
%   scalar integer instead of vector, it is the length of the desired CODEBOOK
%   vector. PARTITION is a vector of length equal to CODEBOOK vector length 
%   minus 1. The optimization will be terminated if the relative distortion
%   is less than 10^(-7).
%
%   [PARTITION, CODEBOOK] = LLOYDS(TRAINING_SET, INI_CODEBOOK, TOL) provides the
%   tolerance in the optimization.
%
%   [PARTITION, CODEBOOK, DISTORTION] = LLOYDS(...) outputs the final distortion
%   value.
%
%   [PARTITION, CODEBOOK, DISTORTION, REL_DISTORTION] = LLOYDS(...) outputs the
%   relative distortion value in terminating the computation.
%
%   See also QUANTIZ, DPCMOPT.


% validation verification and format conversion.
narginchk(2,4);

    min_training = min(training_set);
    max_training = max(training_set);
    codebook = sort(ini_codebook);
    len_codebook = length(codebook);

if nargin < 3
    tol = 0.01;
end

% initial partition
partition = (codebook(2 : len_codebook) + codebook(1 : len_codebook-1)) / 2;

% distortion computation, initialization
[index, waste2, distor] = quantiz(training_set, partition, codebook);
last_distor = 0;

rel_distor = distor;
ter_cond2 = eps * max_training;
if distor > ter_cond2
    epsilon = abs(distor - last_distor)/distor;
else
    rel_distor = distor;
end

j = 0;
%%{
codebookLM = codebook;
partitionLM = partition;
for j = 1:3
        % using the centroid condition, find the optimal codebook.
    for i = 0 : len_codebook-1
        waste1 = find(index == i);
        if ~isempty(waste1)
            codebookLM(i+1) = mean(training_set(waste1));
        else
            if i == 0
                tmp = training_set(training_set <= partitionLM(1));
                if isempty(tmp)
                  codebookLM(1) = (partitionLM(1) + min_training) / 2;
                else
                  codebookLM(1) = mean(tmp);
                end
            elseif i == len_codebook - 1
                tmp = training_set(training_set >= partitionLM(i));
                if isempty(tmp)
                  codebookLM(i+1) = (max_training + partitionLM(i)) / 2;
                else
                  codebookLM(i+1) = mean(tmp);
                end
            else
                tmp = training_set(training_set >= partitionLM(i));
                tmp = tmp(tmp <= partitionLM(i+1));
                if isempty(tmp)
                  codebookLM(i+1) = (partitionLM(i+1) + partitionLM(i)) / 2;
                else
                  codebookLM(i+1) = mean(tmp);
                end
            end
        end
    end

    % compute sorted partition
    partitionLM = sort((codebookLM(2 : len_codebook) + codebookLM(1 : len_codebook-1)) / 2);
    [index, waste2, distor] = quantiz(training_set, partitionLM, codebookLM);
    entropyLM(j) = entropy(index);
    distorLM(j) = distor;
end
lambda = abs((distorLM(2) - distorLM(1))/(entropyLM(2) - entropyLM(1)));
%}
J = 0;
while (epsilon > tol) %&& (rel_distor > ter_cond2)
%for j = 1:100
    % using the centroid condition, find the optimal codebook.
    otr = [min_training - 1, partition, max_training + 1];
    dbstop if error
    [p,ind] = histc(training_set, otr);
    p = sum(p,2)'/numel(training_set);
    p(end)=[];
    lgp = log2(p);
    l = logical(lgp==-inf);
    lgp(l) = -2^16;
    for i = 0 : len_codebook-1
        waste1 = find(index == i);
        if ~isempty(waste1)
            codebook(i+1) = mean(training_set(waste1));
        else
            if i == 0
                tmp = training_set(training_set <= partition(1));
                if isempty(tmp)
                  codebook(1) = (partition(1) + min_training) / 2;
                else
                  codebook(1) = mean(tmp);
                end
            elseif i == len_codebook - 1
                tmp = training_set(training_set >= partition(i));
                if isempty(tmp)
                  codebook(i+1) = (max_training + partition(i)) / 2;
                else
                  codebook(i+1) = mean(tmp);
                end
            else
                tmp = training_set(training_set >= partition(i));
                tmp = tmp(tmp <= partition(i+1));
                if isempty(tmp)
                  codebook(i+1) = (partition(i+1) + partition(i)) / 2;
                else
                  codebook(i+1) = mean(tmp);
                end
            end
        end
    end
    lp = (codebook(2 : len_codebook) + codebook(1 : len_codebook-1)) / 2;
    lv = lgp(2 : len_codebook) - lgp(1 : len_codebook - 1);
    ln = codebook(2 : len_codebook) - codebook(1 : len_codebook-1);
    
    % compute sorted partition
    partition = sort(lp - lambda*lv/ln);
    

    % testing condition
    last_distor = distor;
    [index, waste2, distor] = quantiz(training_set, partition, codebook);
    H = entropy(index);
    last_J = J;
    % if J > ter_cond2
         J = distor + lambda*H;
         epsilon = abs(last_J - J)/J;
   %  else
    %     rel_distor = distor;
  %   end
end
