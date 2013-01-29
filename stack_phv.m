% Program to stack phase velocity maps from each event

clear;

phase_v_path = './eikonal/'
phvmatfiles = dir([phase_v_path,'/*.mat']);

setup_parameters

periods = parameters.periods;
lalim = parameters.lalim;
lolim = parameters.lolim;
gridsize = parameters.gridsize;
mincsnum = parameters.mincsnum;
min_phv_tol = parameters.min_phv_tol;
max_phv_tol = parameters.max_phv_tol;

xnode=lalim(1):gridsize:lalim(2);
ynode=lolim(1):gridsize:lolim(2);
Nx=length(xnode);
Ny=length(ynode);
[xi yi]=ndgrid(xnode,ynode);

for ip=1:length(periods)
	avgphv(ip).sumV = zeros(Nx,Ny);
	avgphv(ip).sumweight = zeros(Nx,Ny);
	avgphv(ip).GV_std = zeros(Nx,Ny);
end
GV_mat = zeros(Nx,Ny,length(phvmatfiles),length(periods));

for ie = 1:length(phvmatfiles)
	temp = load([phase_v_path,phvmatfiles(ie).name]);
	eventphv = temp.eventphv;
	disp(eventphv(1).id);
	for ip=1:length(periods)
		for j=1:Ny
			for i=1:Nx
				if eventphv(ip).GV(i,j) < min_phv_tol
					eventphv(ip).GV(i,j) = min_phv_tol;
				end
				if eventphv(ip).GV(i,j) > max_phv_tol
					eventphv(ip).GV(i,j) = max_phv_tol;
				end
				GV_mat(:,:,ie,ip) = eventphv(ip).GV;
				if ~isnan(eventphv(ip).GV(i,j)) && eventphv(ip).goodnum > mincsnum
					avgphv(ip).sumV(i,j) = avgphv(ip).sumV(i,j) + eventphv(ip).GV(i,j)*eventphv(ip).raydense(i,j);
					avgphv(ip).sumweight(i,j) = avgphv(ip).sumweight(i,j) + eventphv(ip).raydense(i,j);
				end
			end
		end
	end
end

for ip=1:length(periods)
	avgphv(ip).GV = avgphv(ip).sumV ./ avgphv(ip).sumweight;
end

% Calculate std:
for ip=1:length(periods)
	for i = 1:Nx
		for j=1:Ny
			avgphv(ip).GV_std(i,j) = nanstd(GV_mat(i,j,:,ip));
		end
	end
end

N=3; M = floor(length(periods)/N)+1;
figure(89)
clf
for ip = 1:length(periods)
	subplot(M,N,ip)
	ax = worldmap(lalim, lolim);
	set(ax, 'Visible', 'off')
	h1=surfacem(xi,yi,avgphv(ip).GV);
	% set(h1,'facecolor','interp');
%	load pngcoastline
%	geoshow([S.Lat], [S.Lon], 'Color', 'black','linewidth',2)
	title(['Periods: ',num2str(periods(ip))],'fontsize',15)
	avgv = nanmean(avgphv(ip).GV(:));
	if isnan(avgv)
		continue;
	end
	r = 0.1;
	caxis([avgv*(1-r) avgv*(1+r)])
	colorbar
	load seiscmap
	colormap(seiscmap)
end
drawnow;

figure(90)
clf
for ip = 1:length(periods)
	subplot(M,N,ip)
	ax = worldmap(lalim, lolim);
	set(ax, 'Visible', 'off')
	h1=surfacem(xi,yi,avgphv(ip).GV_std);
	% set(h1,'facecolor','interp');
%	load pngcoastline
%	geoshow([S.Lat], [S.Lon], 'Color', 'black','linewidth',2)
	title(['Periods: ',num2str(periods(ip))],'fontsize',15)
	colorbar
	load seiscmap
	colormap(seiscmap)
end
drawnow;
