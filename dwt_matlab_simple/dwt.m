function [ dwt_ca ] = dwt( array, dir_filter, shift )
%Direct DWT
%   Only for odd filters
%   Input:  matrix of monochrome original values
%   Output: NxN matrix of cells containing transform values

    N = size(dir_filter, 1);
    dir_len=size(dir_filter,2);
    dir_len_h = (dir_len-1)/2;
    extension = dir_len_h;

    [h_or, w_or]=size(array);
    % image dimensions decremented by one have to divisible by N (for decimation)
    h_c = ceil( (h_or-1)/N )*N+1 ;
    w_c = ceil( (w_or-1)/N )*N+1 ;
    original_c=array-shift;
    % extrapolation by copying
    original_c(h_or+1:h_c,:)=repmat(original_c(h_or,:), h_c-h_or, 1);
    original_c(:,w_or+1:w_c)=repmat(original_c(:,w_or), 1, w_c-w_or);
    % extension is needed to perform operation near bounds (odd mirrored)
    original_ext = original_c([extension+1:-1:1+1, 1:end, end-1:-1:end-extension],[extension+1:-1:1+1, 1:end, end-1:-1:end-extension]);

    for n=1:N
        % horizontal
        dwt_half_2ext{n}=conv2(original_ext,dir_filter(n,:));
        % crop extension near bounds
        dwt_half_ext{n}=dwt_half_2ext{n}(:,1+extension+dir_len_h:end-(extension+dir_len_h));
        % dicimation
        dwt_half_ext{n}=dwt_half_ext{n}(:,1:N:end);
        for m=1:N
            % vertical
            dwt_ext{m,n}=conv2(dwt_half_ext{n},dir_filter(m,:).');
            % crop extension near bounds
            dwt_ca{m,n}=dwt_ext{m,n}(1+extension+dir_len_h:end-(extension+dir_len_h),:);
            % dicimation
            dwt_ca{m,n}=dwt_ca{m,n}(1:N:end,:);
        end
    end

end

