function y = nanvarXT(x,w,dim)
%NANVARXT Variance, ignoring NaNs with matrix weighting
%   Y = NANVAR(X) returns the sample variance of the values in X, treating
%   NaNs as missing values.  For a vector input, Y is the variance of the
%   non-NaN elements of X.  For a matrix input, Y is a row vector
%   containing the variance of the non-NaN elements in each column of X.
%   For N-D arrays, NANVAR operates along the first non-singleton dimension
%   of X.
%
%   NANVAR normalizes Y by N-1 if N>1, where N is the sample size of the 
%   non-NaN elements.  This is an unbiased estimator of the variance of the
%   population from which X is drawn, as long as X consists of independent,
%   identically distributed samples, and data are missing at random.  For
%   N=1, Y is normalized by N. 
%
%   Y = NANVAR(X,1) normalizes by N and produces the second moment of the
%   sample about its mean.  NANVAR(X,0) is the same as NANVAR(X).
%
%   Y = NANVAR(X,W) computes the variance using the weight vector OR MATRIX
%   W.  If vetor the length of W must equal the length of the dimension
%   over which NANVAR operates, and its non-NaN elements must be
%   nonnegative.  If matrix, must be equal in size to X .Elements of X
%   corresponding to NaN elements of W are ignored.
%
%   Y = NANVAR(X,W,DIM) takes the variance along dimension DIM of X.
%
%   See also VAR, NANSTD, NANMEAN, NANMEDIAN, NANMIN, NANMAX, NANSUM.
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
%
% This file is part of FocalAdhesionPackage.
% 
% FocalAdhesionPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FocalAdhesionPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FocalAdhesionPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

%   Copyright 1984-2010 The MathWorks, Inc.
%   $Revision: 1.1.8.2 $  $Date: 2010/10/08 17:25:19 $

if nargin < 2 || isempty(w), w = 0; end

sz = size(x);
if nargin < 3 || isempty(dim)
    % The output size for [] is a special case when DIM is not given.
    if isequal(x,[]), y = NaN(class(x)); return; end

    % Figure out which dimension sum will work along.
    dim = find(sz ~= 1, 1);
    if isempty(dim), dim = 1; end
elseif dim > length(sz)
    sz(end+1:dim) = 1;
end

% Need to tile the mean of X to center it.
tile = ones(size(sz));
tile(dim) = sz(dim);

if isequal(w,0) || isequal(w,1)
    % Count up non-NaNs.
    n = sum(~isnan(x),dim);

    if w == 0
        % The unbiased estimator: divide by (n-1).  Can't do this when
        % n == 0 or 1, so n==1 => we'll return zeros
        denom = max(n-1, 1);
    else
        % The biased estimator: divide by n.
        denom = n; % n==1 => we'll return zeros
    end
    denom(n==0) = NaN; % Make all NaNs return NaN, without a divideByZero warning

    x0 = x - repmat(nanmean(x, dim), tile);
    y = nansum(abs(x0).^2, dim) ./ denom; % abs guarantees a real result

% Weighted variance
else
    
    if ~isequal(size(w),size(x))
        %If vector of weights was specified, replicate to matrix
        if numel(w) ~= sz(dim)
            error(message('stats:nanvar:InvalidSizeWgts'));
        elseif ~(isvector(w) && all(w(~isnan(w)) >= 0))
            error(message('stats:nanvar:InvalidWgts'));
        end
        % Embed W in the right number of dims.  Then replicate it out along the
        % non-working dims to match X's size.
        wresize = ones(size(sz)); wresize(dim) = sz(dim);
        wtile = sz; wtile(dim) = 1;
        w = repmat(reshape(w, wresize), wtile);
    end        

    % Count up non-NaNs.
    n = nansum(~isnan(x).*w,dim);

    x0 = x - repmat(nansum(w.*x, dim) ./ n, tile);
    y = nansum(w .* abs(x0).^2, dim) ./ n; % abs guarantees a real result
end
