function [ restored ] = idwt( dwt_ca, inv_filter, shift, sym_coef, h_or, w_or )
%Inverse DWT
%   Only for odd positive-symmetric filters
%   sym_coef for adequate symmetry of extension:
%       +1 for positive-symmertic filters
%       -1 for negative-symmetric filters
%   h_or, w_or for final crop
%   Input:  NxN matrix of cells containing transform values
%   Output: matrix of monochrome original values

    N = size(inv_filter, 1);
    inv_len=size(inv_filter,2);
    inv_len_h = (inv_len-1)/2;
    extension = inv_len_h;
    [h_dwt, w_dwt]=size(dwt_ca{1,1});

    for n=1:N
        for m=1:N
            % interpolation
            dwt_z{m,n}(1:N:1+N*(h_dwt-1),1:N:1+N*(w_dwt-1))=dwt_ca{m,n};
            % extension (for operation near bounds)
            dwt_ext{m,n}=[  dwt_z{m,n}(extension+1:-1:1+1,:)*sym_coef(m); dwt_z{m,n}; dwt_z{m,n}(end-1:-1:end-extension,:)*sym_coef(m)];
            dwt_ext{m,n}=[dwt_ext{m,n}(:,extension+1:-1:1+1)*sym_coef(n), dwt_ext{m,n}, dwt_ext{m,n}(:,end-1:-1:end-extension)*sym_coef(n)];
            % vertical 
            dwt_f_half_2ext{m,n}=conv2(dwt_ext{m,n},inv_filter(m,:).');
            % crop extension
            dwt_f_half_ext{m,n}=dwt_f_half_2ext{m,n}(1+extension+inv_len_h:end-(extension+inv_len_h),:);
        end
        % half-sum initializaion
        dwt_f_half_sum_ext{n}=zeros(size(dwt_f_half_ext{1,1}));
        for m=1:N
            dwt_f_half_sum_ext{n} = dwt_f_half_sum_ext{n}+dwt_f_half_ext{m,n};
        end
        % vertical 
        dwt_f_ext{n}=conv2(dwt_f_half_sum_ext{n},inv_filter(n,:));
        % crop extension
        dwt_f{n}=dwt_f_ext{n}(:,1+extension+inv_len_h:end-(extension+inv_len_h));
    end
    % full-sum initialization
    dwt_f_sum = zeros(size(dwt_f{1}));
    for n=1:N
        dwt_f_sum = dwt_f_sum+dwt_f{n};
    end
    % final crop (exclude copied pixels)
    restored = dwt_f_sum(1:h_or,1:w_or)+shift;

end

