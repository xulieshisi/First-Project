function plot_figure5_matlab_white
% Native MATLAB redraw from the permittivity model and forward GPR data.
% No reference bitmap is used to construct the plotted surfaces.
base = fileparts(mfilename('fullpath'));
projectRoot = fileparts(base);
out = fullfile(projectRoot,'outputs','f4');
if ~isfolder(out), mkdir(out); end
axisSize = 23; barSize = axisSize-1;
fprintf('Loading model and forward data...\n');
a = load(fullfile(projectRoot,'data','H5_es.mat'),'eps');
dx = 0.025; iz = 1:min(size(a.eps,3),round(3.45/dx));
ix = 1:2:size(a.eps,2); iy = 1:2:size(a.eps,1);
model = double(a.eps(iy,ix,iz));
mx = ix*dx; my = iy*dx; mz = iz*dx; clear a;
fx = double(h5read(fullfile(projectRoot,'data','GPR_Data.h5'),'/xvec'));
fy = double(h5read(fullfile(projectRoot,'data','GPR_Data.h5'),'/yvec'));
t = double(h5read(fullfile(projectRoot,'data','GPR_Data.h5'),'/tvec'));
z = t*0.0695/2; nz = find(z<=3.45,1,'last');
raw = h5read(fullfile(projectRoot,'data','GPR_Data.h5'),'/gprData',[1 1 1],[nz numel(fx) numel(fy)]);
iz = 1:max(1,floor(nz/700)):nz;
forward = permute(double(raw(iz,:,:)),[3 2 1]); fz = z(iz); clear raw;
fprintf('Constructing native 3-D surfaces...\n');
f = figure('Color','w','Visible','off','Units','centimeters', ...
    'Position',[0 0 22 25],'InvertHardcopy','off');
closeFigure = onCleanup(@() close(f));
f.PaperPositionMode = 'auto';
positions = {[0.50 13.25 20 9.1],[0.50 2.65 20 9.1]};
datasets = {model,forward}; xx = {mx,fx}; yy = {my,fy}; zz = {mz,fz};
limits = {[5 20],[-0.2 0.2]};
axesHandles = gobjects(2,1); bars = gobjects(2,1);
for k = 1:2
    ax = axes(f,'Units','centimeters','Position',positions{k},'Color','w');
    axesHandles(k) = ax;
    cutaway(ax,xx{k},yy{k},zz{k},datasets{k});
    view(ax,[115 15]);
    xlim(ax,[min(xx{k}) max(xx{k})]);
    ylim(ax,[min(yy{k}) max(yy{k})]);
    zlim(ax,[min(zz{k}) max(zz{k})]);
    pbaspect(ax,[1.6 2.8 1]); camva(ax,6.8);
    clim(ax,limits{k}); colormap(ax,jet(256));
    set(ax,'ZDir','reverse','FontName','Times New Roman','FontSize',axisSize, ...
        'FontWeight','bold','LineWidth',0.75,'Box','on','Layer','top', ...
        'XGrid','on','YGrid','on','ZGrid','on', ...
        'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on');
    xlabel(ax,'X (m)','FontSize',axisSize,'FontWeight','bold');
    ylabel(ax,'Y (m)','FontSize',axisSize,'FontWeight','bold');
    zlabel(ax,'Z (m)','FontSize',axisSize,'FontWeight','bold');
    title(ax,sprintf('(%c)','a'+k-1),'FontName','Times New Roman', ...
        'FontWeight','bold','FontSize',axisSize);
    cb = colorbar(ax,'eastoutside'); bars(k) = cb;
    cb.FontName='Times New Roman'; cb.FontSize=barSize; cb.FontWeight='bold';
    cb.Label.String='';
    if k==1
        cb.Ticks=5:5:20;
    else
        cb.Ticks=-0.2:0.1:0.2;
        cb.TickLabels={'-0.2','-0.1','0','0.1','0.2'};
    end
    cb.Units='centimeters';
    ax.Position=positions{k};
    cb.Position=[18.70 positions{k}(2)+(9.1-6)/2 .35 6];
    cb.Title.String='';
end
% Figure annotation avoids the colorbar title's narrow-width line wrapping.
titles = {'\epsilon_{r}','V/m'};
for k = 1:2
    p = bars(k).Position;
    annotation(f,'textbox',[(p(1)-1.15)/22 (p(2)+p(4)+.25)/25 2.65/22 .75/25], ...
        'String',titles{k},'Interpreter','tex','EdgeColor','none', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontName','Times New Roman','FontSize',barSize,'FontWeight','bold', ...
        'Margin',0);
end
drawnow;
for k=1:2, axesHandles(k).Position=positions{k}; end
prefix=fullfile(out,'f4');
savefig(f,[prefix '.fig']);
fprintf('Exporting native figure...\n');
exportgraphics(f,[prefix '.pdf'],'ContentType','image','Resolution',150);
print(f,[prefix '.emf'],'-dmeta');
fprintf('Saved PDF, EMF, and editable FIG:\n%s.pdf\n%s.emf\n%s.fig\n',prefix,prefix,prefix);
end

function cutaway(ax,x,y,z,data)
hold(ax,'on');
sx=min(max(14,min(x)),max(x));
sy=min(max(1,min(y)),max(y));
sz=min(max(3.25,min(z)),max(z));
[~,nx]=min(abs(x-sx)); [~,ny]=min(abs(y-sy)); [~,nz]=min(abs(z-sz));
% The same sections and geometry as the original Figure 5.
plane(ax,x,y,z,data,'y',sy,'cutwall',1);
plane(ax,x,y,z,data,'z',sz,'bottom',1);
plane(ax,x(1:nx),y,z,data(:,1:nx,:),'y',min(y),'cutwall',1);
plane(ax,x(1:nx),y,z,data(:,1:nx,:),'z',min(z),'top',1);
plane(ax,x,y(1:ny),z,data(1:ny,:,:),'x',max(x),'front',1);
plane(ax,x,y(1:ny),z,data(1:ny,:,:),'z',min(z),'top',1);
plane(ax,x,y,z(nz:end),data(:,:,nz:end),'x',max(x),'front',1);
plane(ax,x,y,z(nz:end),data(:,:,nz:end),'y',min(y),'cutwall',1);
plane(ax,x,y,z,data,'y',max(y),'transparent',.3);
plane(ax,x,y,z,data,'z',max(z),'transparent',.3);
% The x=sx YZ profile is the broad visible face in the reference figure.
% Keep its interpolated CData unshaded; applying the front-face material here
% makes the entire profile unnaturally dark under the three finite lights.
plane(ax,x,y,z,data,'x',sx,'profile',1);
light(ax,'Position',[1 0 -1],'Style','infinite');
light(ax,'Position',[0 -1 0],'Style','infinite');
light(ax,'Position',[-1 0 -1],'Style','infinite');
end

function h = plane(ax,x,y,z,data,direction,value,role,alpha)
% Interpolate only the selected 2-D section, without a full-volume meshgrid.
switch direction
    case 'x'
        c = section(data,x,value,2);
        [Y,Z]=meshgrid(y,z); X=ones(size(Y))*value; C=squeeze(c).';
    case 'y'
        c = section(data,y,value,1);
        [X,Z]=meshgrid(x,z); Y=ones(size(X))*value; C=squeeze(c).';
    case 'z'
        c = section(data,z,value,3);
        [X,Y]=meshgrid(x,y); Z=ones(size(X))*value; C=squeeze(c);
end
h = surf(ax,X,Y,Z,C,'FaceColor','interp','EdgeColor','none', ...
    'FaceAlpha',alpha,'Tag',['Figure5:' role],'FaceLighting','flat');
switch role
    case 'profile'
        % Preserve the data-to-jet colors on the broad exposed profile.
        set(h,'FaceLighting','none');
    case 'front'
        set(h,'AmbientStrength',.55,'DiffuseStrength',.60,'SpecularStrength',.08);
    case 'cutwall'
        set(h,'AmbientStrength',.40,'DiffuseStrength',.10,'SpecularStrength',0);
    case 'transparent'
        set(h,'FaceLighting','none');
    case 'top'
        set(h,'AmbientStrength',.3,'DiffuseStrength',.6,'SpecularStrength',.9);
    otherwise
        set(h,'AmbientStrength',.6,'DiffuseStrength',.4,'SpecularStrength',.05);
end
end

function c = section(data,coordinates,value,dimension)
coordinates=coordinates(:);
lo=find(coordinates<=value,1,'last');
if isempty(lo), lo=1; end
hi=min(lo+1,numel(coordinates));
weight=0;
if hi~=lo, weight=(value-coordinates(lo))/(coordinates(hi)-coordinates(lo)); end
index={':',':',':'}; index{dimension}=lo; c=data(index{:});
if weight>0
    index{dimension}=hi; c=(1-weight)*c+weight*data(index{:});
end
end
