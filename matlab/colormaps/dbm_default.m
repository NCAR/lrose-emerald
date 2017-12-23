%Default colormap for reflectivity values

function x = dbm_default(n);


if nargin==1 & isempty(n)
    n = size(get(gcf,'Colormap'),1);
end;

cmap = [...
   77,77,77;...
   176,48,96;...
   153,50,204;...
   0,0,255;...
   65,105,225;...
   0,191,255;...
   0,250,154;...
   34,139,34;...
   190,190,190;...
   238,154,73;...
   255,215,0;...
   255,255,0;...
   255,140,105;...
   255,99,71;...
   255,64,64;...
   255,0,0;...
   255,48,48
    ];

cmap=cmap./255;

if nargin < 1
    n = size(cmap,1);
end;

x = interp1(linspace(0,1,size(cmap,1)),cmap(:,1),linspace(0,1,n)','linear');
x(:,2) = interp1(linspace(0,1,size(cmap,1)),cmap(:,2),linspace(0,1,n)','linear');
x(:,3) = interp1(linspace(0,1,size(cmap,1)),cmap(:,3),linspace(0,1,n)','linear');

x = min(x,1);
x = max(x,0);