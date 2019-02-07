function [x, V, VV, loglik] = kalman_filter(y, A, C, Q, R, init_x, init_V, varargin)

[os T] = size(y);
ss = size(A,1); % size of state space

% set default params
model = ones(1,T);
u = [];
B = [];
ndx = [];

args = varargin;
nargs = length(args);
for i=1:2:nargs
  switch args{i}
   case 'model', model = args{i+1};
   case 'u', u = args{i+1};
   case 'B', B = args{i+1};
   case 'ndx', ndx = args{i+1};
   otherwise, error(['unrecognized argument ' args{i}])
  end
end

x = zeros(ss, T);
V = zeros(ss, ss, T);
VV = zeros(ss, ss, T);

loglik = 0;
for t=1:T
  m = model(t);
  if t==1
    %prevx = init_x(:,m);
    %prevV = init_V(:,:,m);
    prevx = init_x;
    prevV = init_V;
    initial = 1;
  else
    prevx = x(:,t-1);
    prevV = V(:,:,t-1);
    initial = 0;
  end
  if isempty(u)
    [x(:,t), V(:,:,t), LL, VV(:,:,t)] = ...
  kalman_update(A(:,:,m), C(:,:,m), Q(:,:,m), R(:,:,m), y(:,t), prevx, prevV, 'initial', initial);
  else
    if isempty(ndx)
      [x(:,t), V(:,:,t), LL, VV(:,:,t)] = ...
    kalman_update(A(:,:,m), C(:,:,m), Q(:,:,m), R(:,:,m), y(:,t), prevx, prevV, ...
      'initial', initial, 'u', u(:,t), 'B', B(:,:,m));
    else
      i = ndx{t};
      % copy over all elements; only some will get updated
      x(:,t) = prevx;
      prevP = inv(prevV);
      prevPsmall = prevP(i,i);
      prevVsmall = inv(prevPsmall);
      [x(i,t), smallV, LL, VV(i,i,t)] = ...
    kalman_update(A(i,i,m), C(:,i,m), Q(i,i,m), R(:,:,m), y(:,t), prevx(i), prevVsmall, ...
      'initial', initial, 'u', u(:,t), 'B', B(i,:,m));
      smallP = inv(smallV);
      prevP(i,i) = smallP;
      V(:,:,t) = inv(prevP);
    end
  end
  loglik = loglik + LL;
end

