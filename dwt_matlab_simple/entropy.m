function [ ent ] = entropy( array )
%Entropy of an arrray
%   Detailed explanation goes here
    arraynan = isnan(array);
    if any(arraynan(:))
        warning('entropy: nan values are omitted');
    end
    array = array(~arraynan).';
    [C, ~, ic]=unique(array);
    p = (sum(ic==1:numel(C),1)/numel(array));
    ent = -p*log2(p.')*numel(array);
end