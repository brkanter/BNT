%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adapted from toolbox: http://www.cs.ubc.ca/~murphyk/Software/Kalman/kalman.html
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x, V] = kalman2D(ph, Q, R)
  ss = 6; % state size
  os = 2; % observation size
  F = [1 1 .5 0 0 0;
       0 1  1 0 0 0;
       0 0  1 0 0 0;
       0 0  0 1 1 .5;
       0 0  0 0 1 1;
       0 0  0 0 0 1];  %the system matrix
  H = [1 0 0 0 0 0;
       0 0 0 1 0 0];   % the observation matrix

  initx = 1*[ph(1,1); ph(1,3)-ph(1,1); ph(1,3)+ph(1,1)-2*ph(1,2); ph(2,1); ph(2,3)-ph(2,1); ph(2,3)+ph(2,1)-2*ph(2,2)];
  initV = 5*eye(ss);

  dims=size(Q,1)/2;
  F=F([(1:dims) 3+(1:dims)],[ (1:dims) 3+(1:dims)]);
  H=H(:,[(1:dims) 3+(1:dims)]);
  initx=initx([(1:dims) 3+(1:dims)]);
  initV=initV([(1:dims) 3+(1:dims)],[ (1:dims) 3+(1:dims)]);


  [x, V] = kalman_smoother(ph, F, H, Q, R, initx, initV);
