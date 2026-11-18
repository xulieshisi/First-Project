function rtm_section_3d_6polar_no(x,y,z,data,xslice1,yslice1,zslice1,xslice2,yslice2,zslice2)
% [nx,ny ,nz] = size(data);
dx = x(2)-x(1);
dy = y(2)-y(1);
dz = z(2)-z(1);
[X,Y,Z]=meshgrid(x,y,z);
xslice = xslice1; 
yslice = yslice1; 
zslice = zslice1;
set(0,'DefaultAxesFontname','Times New Roman')
set(0,'DefaultAxesFontWeight','bold')
%% 原始切片:对挖去的正方体进行切片
image=slice(X,Y,Z,data,xslice,yslice,zslice);
set(image,'FaceColor','interp'); 
set(image,'EdgeColor','interp');
set(image,'Tag','V3D:SLICE');
set(image,'Tag','V3D:SLICE');
set(image,'LineStyle','none');

set(gca,'zdir','reverse')
colormap jet
xlim([min(x),max(x)])
ylim([min(y),max(y)])
zlim([min(z),max(z)])
box on
caxis([-10,10])
% axis image
hold on

%% 体切片
nx_s = round(xslice1 / dx);
image=slice(X(:,1:nx_s,:),Y(:,1:nx_s,:),Z(:,1:nx_s,:), ...
    data(:,1:nx_s,:),[],min(y),min(z));
set(image,'FaceColor','interp','EdgeColor','interp');
set(image,'LineStyle','none');
set(gca,'zdir','reverse')

ny_s =round( yslice1 / dy);
image=slice(X(ny_s:end,:,:),Y(ny_s:end,:,:),Z(ny_s:end,:,:), ...
    data(ny_s:end,:,:),max(x),[],min(z));
set(image,'FaceColor','interp','EdgeColor','interp');
set(image,'LineStyle','none');
set(gca,'zdir','reverse')

nz_s = round(zslice1 / dz);
image=slice(X(:,:,nz_s:end),Y(:,:,nz_s:end),Z(:,:,nz_s:end), ...
    data(:,:,nz_s:end),max(x),min(y),[]);
set(image,'FaceColor','interp','EdgeColor','interp');
set(image,'LineStyle','none');
set(gca,'zdir','reverse')
caxis([-10,10])
grid off
%% 透明切片1:外围切片
nxt1_s = round(xslice2 / dx);
nyt1_s = round(yslice2 / dy);
nzt1_s = round(zslice2 / dz);
image=slice(X(:,:,nzt1_s:end),Y(:,:,nzt1_s:end),Z(:,:,nzt1_s:end),data(:,:,nzt1_s:end),xslice2,yslice2,zslice2);
set(image,'FaceColor','interp'); 
set(image,'EdgeColor','interp');
set(image,'Tag','V3D:SLICE');
set(image,'Tag','V3D:SLICE');
set(image,'LineStyle','none');
set(image,'FaceAlpha',0.3);

%% 异常体标定 
% 
% % 红色横状透明切片
% nxt2_s = [40,44]; xt2_s = (nxt2_s)*dx;
% nyt2_s = [17,26]; yt2_s = (nyt2_s)*dx;
% nzt2_s = [12,17]; zt2_s = (nzt2_s)*dx;
% image=slice(X(nyt2_s(1):nyt2_s(2),nxt2_s(1):nxt2_s(2),nzt2_s(1):nzt2_s(2)),...
%             Y(nyt2_s(1):nyt2_s(2),nxt2_s(1):nxt2_s(2),nzt2_s(1):nzt2_s(2)),...
%             Z(nyt2_s(1):nyt2_s(2),nxt2_s(1):nxt2_s(2),nzt2_s(1):nzt2_s(2)),...
%           data(nyt2_s(1):nyt2_s(2),nxt2_s(1):nxt2_s(2),nzt2_s(1):nzt2_s(2)),...
%         xt2_s,yt2_s,zt2_s);
% set(image,'FaceColor','interp'); 
% set(image,'EdgeColor','interp');
% set(image,'Tag','V3D:SLICE');
% set(image,'Tag','V3D:SLICE');
% set(image,'LineStyle','none');
% set(image,'FaceAlpha',1);

% % 红色横状轮廓
% x_r1 = [40,44,44,40,40,44,44,40]*dx;
% y_r1 = [26,26,17,17,26,26,17,17]*dy;
% z_r1 = [12,12,12,12,17,17,17,17]*dz;
% vertices_matrix1 = ones(8,3);
% vertices_matrix1(:,1) = x_r1;
% vertices_matrix1(:,2) = y_r1;
% vertices_matrix1(:,3) = z_r1;
% % vertices_matrix = [ 0 0 0;1 0 0;1 1 0;0 1 0;0 0.5 1;1 0.5 1;1 1.5 1;0 1.5 1];
% faces_matrix1 = [1 2 6 5;  2 3 7 6;3 4 8 7;4 1 5 8;1 2 3 4;5 6 7 8];
% h1 = patch('Vertices',vertices_matrix1,'Faces',faces_matrix1,...
%     'FaceVertexCData',hsv(8), ...
%     'FaceColor','none','EdgeColor','white', 'EdgeAlpha',0.5,...
%     'LineStyle','--','LineWidth',0.5);
% view(3)
% hold on

xlabel('x(m)','FontSize',12,'FontWeight','bold');
ylabel('y(m)','FontSize',12,'FontWeight','bold');
zlabel('z(m)','FontSize',12,'FontWeight','bold');
l1 = light;
l1.Position = [1 0 -1];
l2 = light;
l2.Position = [0 -1 0];
l3 = light;
l3.Position = [-1 0 -1];
end