tic
global gather_day gather_rebalance

% to change assumed gather day:
% 1) uncomment all part right below
% 2) insert "end" statement for this loop where needed in the text
% 2.a) uncomment / insert row for saving "Comparison" storage variable where needed
% 3) uncomment all required sections (at least 3-6) in this file
% 4) comment asset pricing sections in Lustig and Menkhoff files

% for gday_number = 1 % 0:1:25
gather_day = 0; % days since past month end (last business day up to set date is taken)
% % options:
% % a) 1
% % b) gday_number
% run FX_strategies;
% run Menkhoff_et_al_2011; % this command can also execute scripts in other directories
gather_rebalance = 1; % collect data rebalanced at frequency 'gather_rebalance' in terms of original periods

close all
warning off all
clc
clearvars -except gather_day gday_number gather_rebalance Desc_gross Desc_net % previously used: clear all

% Filter countries series:
% 0 - no filter (use all XS)
% 1 - developed
% 2 - developing
% 10 - G10
filter_XS = 0;
% Filter forecast series since euro introduction:
% 0 - no filter, use individual countries and eurozone together
% 1 - eurozone only
% 2 - countries only
since_euro = 1;

year_vec = 1993:2013;
cd_old = cd;
MAD_variables = {'RG';'PI';'CA';'FX';'IR'};

% flexible variables:
issue_year = 1993; % 1993, 1995
issue_month = 7; % 7, 5
ext = 'eps'; % 'jpg' 'png' 'eps'
% remove outliers from the forecast data, options:
% 'yes - adhoc' - for authors own procedure
% 'yes - TS' - for SEATS / TRAMO
% 'no'
robust_to_outliers = 'yes - adhoc';
robust_to_seasonality = 'no';
lag_for_innovations = 2;

% load previously saved .mat files
subdir = 'Data\Output\'; % subdirectory where all .mat files are kept
files = dir(strcat(subdir,'*.mat'));
for j = 1:length(files)
    load(strcat(subdir,files(j).name));
end
clear files j subdir

G10 = {'BELGIUM' 'CANADA' 'EUROZONE' 'FRANCE' 'GERMANY' 'ITALY' 'JAPAN' 'NETHERLANDS' 'SWEDEN' 'SWITZERLAND' 'UNITED KINGDOM'}; % ex-US which is the 11th in the block of G10
developed = {'AUSTRALIA' 'BELGIUM' 'CANADA' 'DENMARK' 'EUROZONE' 'FRANCE' 'GERMANY' 'ITALY' 'JAPAN' 'NETHERLANDS' 'NEW ZEALAND' 'NORWAY' 'SWEDEN' 'SWITZERLAND' 'UNITED KINGDOM'}; % as defined in Lustig et al. (2011) and Menkhoff et al. (2012), developing are then defined as the rest of currencies
G10 = strrep(G10,' ','_');
developed = strrep(developed,' ','_');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. (MAD factor construction) get all data in from excel files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data(1:length(year_vec),1:12) = struct('numbers',[],'text',[]);
%
% for i = 1:length(year_vec)
%     year_str = strcat(cd_old,'\Data\BLUECHIP\',num2str(year_vec(i)));
%     cd(year_str);
%     files = dir('*.xlsx');
%
%     for j = 1:length(files)
%         [A1 B1] = xlsread(files(j).name,1);
%         [A2 B2] = xlsread(files(j).name,2);
%         Data(i,str2double(files(j).name(1:2))).numbers = [A1; A2];
%         Data(i,str2double(files(j).name(1:2))).text = [B1; B2(2:end,:)];
%     end
% end
% cd(cd_old);
% clear A1 A2 B1 B2 files i j year_str

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. (MAD factor construction) clean data stage 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % % correct the names of the countries in .xlsx
% % Name_storage = {'CANADA'; 'JAPAN'; 'MEXICO'; 'UNITED KINGDOM'; 'GERMANY'; 'TAIWAN'; 'SOUTH KOREA'; 'FRANCE'; 'NETHERLANDS'; 'BELGIUM'; 'SINGAPORE'; 'HONG KONG'; 'AUSTRALIA'; 'ITALY'; 'CHINA'; 'SWITZERLAND'; 'BRAZIL'};
% % % create variations
% % Name_storage_modified = [];
% % for j = 1:size(Name_storage)
% %     Name_storage_modified = [Name_storage_modified; {lower(Name_storage{j}(1:5))}];
% % end
% %
% % for i = 1:length(year_vec)
% %     year_str = strcat(cd_old,'\Data\BLUECHIP\',num2str(year_vec(i)));
% %     cd(year_str);
% %     files = dir('*.xlsx');
% %
% %     for j = 1:length(files)
% %         for m = 1:2
% %             [A1 B1] = xlsread(files(j).name,m);
% %             k = 2;
% %             while k <= size(B1,1)
% %                 for l = 1:length(Name_storage_modified)
% %                     if ~isempty(cell2mat(strfind(lower(B1(k,1)),char(Name_storage_modified(l)))))
% %                         if ~any(strcmp(B1(k,1),Name_storage(l)))
% %                             xlswrite(files(j).name,Name_storage(l),m,strcat('A',num2str(k)));
% %                         end
% %                         break;
% %                     end
% %                 end
% %                 k = k + 7;
% %             end
% %         end
% %     end
% % end
% % cd(cd_old);
% % clear A1 B1 Name_storage Name_storage_modified files i j k year_str l m
%
% % sort out problem so that all required numbers go in numeric matrix
% Problem_storage1 = [];
% for i = 1:length(year_vec)
%     for j = 1:12
%         k = 1;
%         while k <= size(Data(i,j).numbers,1)
%             if any(any(isnan(Data(i,j).numbers([(k+2):(k+3)],:)), 2))
%                 Problem_storage1 = [Problem_storage1; i j k];
%             end
%             k = k + 7;
%         end
%     end
% end
% % checked exceptions: (1,7,43)
%
% % check that sizes of the table are standardised
% % rows...
% Problem_storage2 = [];
% for i = 1:length(year_vec)
%     for j = 1:12
%         if ~(size(Data(i,j).numbers,1) == 105 || size(Data(i,j).numbers,1) == 112)
%             Problem_storage2 = [Problem_storage2; i j];
%         end
%     end
% end
% % checked exceptions: (1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(6,10){data for whole month is missing},(15,12)
% % columns...
% Problem_storage3 = [];
% for i = 1:length(year_vec)
%     for j = 1:12
%         if size(Data(i,j).numbers,2) ~= 10
%             Problem_storage3 = [Problem_storage3; i j];
%         end
%     end
% end
%
% % check for consistency of country names
% Problem_storage4 = [];
% for i = 1:length(year_vec)
%     for j = 1:12
%         k = 2;
%         while k <= size(Data(i,j).text,1)
%             if ~any(strcmp(Data(i,j).text(k,1),Problem_storage4))
%                 Problem_storage4 = [Problem_storage4; Data(i,j).text(k,1), i, j, k];
%             end
%             k = k + 7;
%         end
%     end
% end
% clear i j k
%
% % Rogue forecasts for Australia FX in May 05 (negative) => put NaNs
% % instead for BOTTOM
% Data(13,5).numbers(100,7) = Data(13,6).numbers(103,7);
% Data(13,5).numbers(101:102,7) = NaN;
%
% % (Assume) rogue forecast for Australia GDP in Jul 98 (inconsistent with top and bottom) => put NaN instead
% Data(6,7).numbers(100,1) = NaN;
% % (Assume) rogue forecast for Italy CPI in Jan 97 (inconsistent with top and bottom) => put NaN instead
% Data(5,1).numbers(100,3) = NaN;
% % (Assume) rogue forecast for Canada BoP in Oct 93 (inconsistent with top
% % and bottom) => put all figure with minus sign instead
% Data(1,10).numbers(2:3,6) = -Data(1,10).numbers(2:3,6);
% % (Assume) rogue forecast for Japan BoP in May 03 (both) (inconsistent with top and bottom) => put NaN instead
% Data(11,5).numbers(16,5:6) = NaN;
% % (Assume) rogue forecast for Australia BoP in May 03 (both) (inconsistent with top and bottom) => put NaN instead
% Data(11,5).numbers(100,5:6) = NaN;
% % (Assume) rogue forecast for China BoP in Jan 97 (inconsistent with top and bottom) => put NaN instead
% Data(5,1).numbers(88,5) = NaN;
% % (Assume) rogue forecast for Brazil BoP in Jul 96 (inconsistent with top and bottom) => put NaN instead
% Data(4,7).numbers(95,6) = NaN;
% % (Assume) rogue forecast for Eurozone BoP in Oct 03 (inconsistent with top and bottom) => put NaN instead
% Data(11,10).numbers(107,6) = NaN;
% % (Assume) rogue forecast for Mexico FX in Sep 93 (inconsistent with top and bottom) => put NaN instead
% Data(1,9).numbers(16,7) = NaN;
% % (Assume) rogue forecast for Belgium FX in Feb 97 (inconsistent with top and bottom) => put NaN instead
% Data(5,2).numbers(79,7) = NaN;
% % (Assume) rogue forecast for Mexico interest in Jan 97 (inconsistent with top and bottom) => put NaN instead
% % in bottom one most likely
% Data(5,1).numbers(18,9) = NaN;
% % (Assume) rogue forecast for Australia interest in Jan 06 (inconsistent with top and bottom) => put NaN instead
% % in bottom one most likely
% Data(14,1).numbers(102,10) = NaN;
%
% save 'Data\OUTPUT\BCEI_Data' Data Problem_storage4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Get forecasts in and clean data stage 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% winsor = 1; % use winsor-th highest extreme from adjusted CONSENSUS to substitute for more extreme cases (for both top and bottom)
% 
% % Get required FX spot rates for later manipulation
% date_temp = fts2mat(SPOT_MID_ts('01/05/99').('EUROZONE'));
% SPOT_MID_ts = toannual(SPOT_MID_ts);
% SPOT_MID_ts('12/31/98').('EUROZONE') = date_temp;
% clear date_temp
% 
% % Get required countries' GDP in USD timeseries in for later manipulation
% [GDP_ALL GDP_ALL_txt] = xlsread('Data\IMF\All country GDP (current prices, USD).xlsx','Sheet1');
% [GDP_EU GDP_EU_txt] = xlsread('Data\IMF\Euro country GDP (current prices, USD).xlsx','Sheet1');
% GDP_EU_ts = fints(datenum(GDP_EU(1:end-1,1),12,31),nansum(GDP_EU(1:end-1,2:end),2),'EUROZONE','annual');
% GDP_ALL_txt(1,find(strcmp('KOREA',GDP_ALL_txt(1,:)))) = {'SOUTH KOREA'};
% GDP_ALL_txt(1,find(strcmp('HONG KONG SAR',GDP_ALL_txt(1,:)))) = {'HONG KONG'};
% GDP_ALL_txt(1,find(strcmp('SLOVAK REPUBLIC',GDP_ALL_txt(1,:)))) = {'SLOVAKIA'};
% GDP_ALL_txt(1,find(strcmp('TAIWAN PROVINCE OF CHINA',GDP_ALL_txt(1,:)))) = {'TAIWAN'};
% GDP_ALL_txt(1,2:end) = strrep(GDP_ALL_txt(1,2:end),' ','_');
% GDP_ALL_txt(1,2:end) = strrep(GDP_ALL_txt(1,2:end),'-','_');
% GDP_ALL_ts = [fints(datenum(GDP_ALL(1:end-1,1),12,31),GDP_ALL(1:end-1,2:end),GDP_ALL_txt(1,2:end),'annual') GDP_EU_ts];
% 
% % Get forecasts in
% clear FORECAST
% B_fin_missed = [];
% FORECAST(1:size(Data(1,7).numbers,2)) = struct('LM_CONSENSUS',[],'CONSENSUS',[],'BOTTOM',[],'TOP',[]);
% date1 = busdate(datenum(1999,1,1+gather_day),-1);
% date2 = busdate(datenum(2000,1,1+gather_day),-1);
% for h = 1:size(Data(1,7).numbers,2)
%     FORECAST_TOP = cell((length(year_vec)*12+1),size(Problem_storage4,1));
%     FORECAST_BOTTOM = cell((length(year_vec)*12+1),size(Problem_storage4,1));
%     FORECAST_CONSENSUS = cell((length(year_vec)*12+1),size(Problem_storage4,1));
%     FORECAST_LM_CONSENSUS = cell((length(year_vec)*12+1),size(Problem_storage4,1));
%     count = 2;
%     for i = 1:length(year_vec)
%         for j = 1:12
%             if (gather_day + 1) < 10
%                 day_str = strcat('0',num2str(gather_day + 1));
%             else
%                 day_str = num2str(gather_day + 1);
%             end
%             if j < 10
%                 month_str = strcat('0',num2str(j));
%             else
%                 month_str = num2str(j);
%             end
%             year_str = num2str(year_vec(i));
% 
%             date = strcat(day_str,'/',month_str,'/',year_str(3:4));
%             date = datestr(busdate(datenum(date,'dd/mm/yy'),-1),'dd/mm/yy');
%             FORECAST_TOP(1+(i-1)*12 + j,1) = {date};
%             FORECAST_BOTTOM(1+(i-1)*12 + j,1) = {date};
%             FORECAST_CONSENSUS(1+(i-1)*12 + j,1) = {date};
%             FORECAST_LM_CONSENSUS(1+(i-1)*12 + j,1) = {date};
% 
%             if ~isempty(Data(i,j).numbers)
%                 k = 2;
%                 while k <= size(Data(i,j).text,1)
%                     if ~any(strcmp(Data(i,j).text(k,1),FORECAST_TOP(1,:))) && ~any(strcmp(Data(i,j).text(k,1),B_fin_missed))
%                         FORECAST_TOP(1,count) = Data(i,j).text(k,1);
%                         FORECAST_BOTTOM(1,count) = Data(i,j).text(k,1);
%                         FORECAST_CONSENSUS(1,count) = Data(i,j).text(k,1);
%                         FORECAST_LM_CONSENSUS(1,count) = Data(i,j).text(k,1);
% 
%                         FORECAST_TOP(1+(i-1)*12 + j,count) = {Data(i,j).numbers(k+1,h)};
%                         FORECAST_BOTTOM(1+(i-1)*12 + j,count) = {Data(i,j).numbers(k+2,h)};
%                         FORECAST_CONSENSUS(1+(i-1)*12 + j,count) = {Data(i,j).numbers(k,h)};
%                         FORECAST_LM_CONSENSUS(1+(i-1)*12 + j,count) = {Data(i,j).numbers(k+3,h)};
% 
%                         count = count + 1;
%                     elseif ~any(strcmp(Data(i,j).text(k,1),B_fin_missed))
%                         FORECAST_TOP(1+(i-1)*12 + j,find(strcmp(Data(i,j).text(k,1),FORECAST_TOP(1,:)))) = {Data(i,j).numbers(k+1,h)};
%                         FORECAST_BOTTOM(1+(i-1)*12 + j,find(strcmp(Data(i,j).text(k,1),FORECAST_BOTTOM(1,:)))) = {Data(i,j).numbers(k+2,h)};
%                         FORECAST_CONSENSUS(1+(i-1)*12 + j,find(strcmp(Data(i,j).text(k,1),FORECAST_CONSENSUS(1,:)))) = {Data(i,j).numbers(k,h)};
%                         FORECAST_LM_CONSENSUS(1+(i-1)*12 + j,find(strcmp(Data(i,j).text(k,1),FORECAST_LM_CONSENSUS(1,:)))) = {Data(i,j).numbers(k+3,h)};
%                     end
%                     k = k + 7;
%                 end
%             end
%         end
%     end
% 
%     % remove unnecessary rows if needed
%     FORECAST_TOP([2:7 249:253],:) = [];
%     FORECAST_BOTTOM([2:7 249:253],:) = [];
%     FORECAST_CONSENSUS([2:7 249:253],:) = [];
%     FORECAST_LM_CONSENSUS([2:7 249:253],:) = [];
% 
%     % put NaNs in empty cells
%     [a b] = size(FORECAST_TOP);
%     for i = 2:a
%         for j = 2:b
%             if isempty(cell2mat(FORECAST_TOP(i,j)))
%                 FORECAST_TOP(i,j) = {NaN};
%             end
%             if isempty(cell2mat(FORECAST_BOTTOM(i,j)))
%                 FORECAST_BOTTOM(i,j) = {NaN};
%             end
%             if isempty(cell2mat(FORECAST_CONSENSUS(i,j)))
%                 FORECAST_CONSENSUS(i,j) = {NaN};
%             end
%             if isempty(cell2mat(FORECAST_LM_CONSENSUS(i,j)))
%                 FORECAST_LM_CONSENSUS(i,j) = {NaN};
%             end
%         end
%     end
%     FORECAST_TOP(1,2:end) = strrep(FORECAST_TOP(1,2:end),' ','_');
%     FORECAST_TOP(1,2:end) = strrep(FORECAST_TOP(1,2:end),'-','_');
%     FORECAST_LM_CONSENSUS(1,2:end) = FORECAST_TOP(1,2:end);
%     FORECAST_CONSENSUS(1,2:end) = FORECAST_TOP(1,2:end);
%     FORECAST_BOTTOM(1,2:end) = FORECAST_TOP(1,2:end);
% 
%     % Instead of indiv time series EUROZONE countries make one since 1999
%     for i = 2:size(FORECAST_TOP,1)
%         if (h >= 7) && (h <= 10) && (datenum(FORECAST_TOP(i,1),'dd/mm/yy') == date1)
%             FORECAST_LM_CONSENSUS(i:end,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_LM_CONSENSUS(i:end,find(strcmp('GERMANY',FORECAST_TOP(1,:))));
%             FORECAST_CONSENSUS(i:end,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_CONSENSUS(i:end,find(strcmp('GERMANY',FORECAST_TOP(1,:))));
%             FORECAST_BOTTOM(i:end,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_BOTTOM(i:end,find(strcmp('GERMANY',FORECAST_TOP(1,:))));
%             FORECAST_TOP(i:end,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_TOP(i:end,find(strcmp('GERMANY',FORECAST_TOP(1,:))));
% 
%             FORECAST_LM_CONSENSUS(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_CONSENSUS(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_BOTTOM(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_TOP(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
% 
%             FORECAST_LM_CONSENSUS(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_CONSENSUS(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_BOTTOM(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_TOP(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
% 
%             country_list = {'GERMANY','FRANCE','NETHERLANDS','BELGIUM','ITALY'};
%             for j = 1:length(country_list)
%                 FORECAST_LM_CONSENSUS(i:end,find(strcmp(country_list(j),FORECAST_LM_CONSENSUS(1,:)))) = {NaN};
%                 FORECAST_CONSENSUS(i:end,find(strcmp(country_list(j),FORECAST_CONSENSUS(1,:)))) = {NaN};
%                 FORECAST_BOTTOM(i:end,find(strcmp(country_list(j),FORECAST_BOTTOM(1,:)))) = {NaN};
%                 FORECAST_TOP(i:end,find(strcmp(country_list(j),FORECAST_BOTTOM(1,:)))) = {NaN};
%             end
%             break;
%         elseif (h < 7) && (datenum(FORECAST_TOP(i,1),'dd/mm/yy') == date2)
%             FORECAST_LM_CONSENSUS(i:i+5,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_LM_CONSENSUS(i:i+5,find(strcmp('EURO_11',FORECAST_TOP(1,:))));
%             FORECAST_CONSENSUS(i:i+5,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_CONSENSUS(i:i+5,find(strcmp('EURO_11',FORECAST_TOP(1,:))));
%             FORECAST_BOTTOM(i:i+5,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_BOTTOM(i:i+5,find(strcmp('EURO_11',FORECAST_TOP(1,:))));
%             FORECAST_TOP(i:i+5,find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_TOP(i:i+5,find(strcmp('EURO_11',FORECAST_TOP(1,:))));
% 
%             FORECAST_LM_CONSENSUS([i+6:i+46,i+48:i+70],find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_LM_CONSENSUS([i+6:i+46,i+48:i+70],find(strcmp('EUROLAND',FORECAST_TOP(1,:))));
%             FORECAST_CONSENSUS([i+6:i+46,i+48:i+70],find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_CONSENSUS([i+6:i+46,i+48:i+70],find(strcmp('EUROLAND',FORECAST_TOP(1,:))));
%             FORECAST_BOTTOM([i+6:i+46,i+48:i+70],find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_BOTTOM([i+6:i+46,i+48:i+70],find(strcmp('EUROLAND',FORECAST_TOP(1,:))));
%             FORECAST_TOP([i+6:i+46,i+48:i+70],find(strcmp('EUROZONE',FORECAST_TOP(1,:)))) = FORECAST_TOP([i+6:i+46,i+48:i+70],find(strcmp('EUROLAND',FORECAST_TOP(1,:))));
% 
%             FORECAST_LM_CONSENSUS(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_CONSENSUS(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_BOTTOM(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
%             FORECAST_TOP(:,find(strcmp('EURO_11',FORECAST_TOP(1,:)))) = [];
% 
%             FORECAST_LM_CONSENSUS(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_CONSENSUS(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_BOTTOM(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             FORECAST_TOP(:,find(strcmp('EUROLAND',FORECAST_TOP(1,:)))) = [];
%             break;
%         end
%     end
% 
%     % Switch necessary FX rates to USD/FCU view from FCU/USD (FCU - foreign currency unit)
%     if (h == 7) || (h == 8)
%         country_list = {'UNITED_KINGDOM','AUSTRALIA','EUROZONE'};
%         for i = 2:length(FORECAST_TOP(1,:))
%             if ~any(strcmp(FORECAST_TOP(1,i),country_list))
%                 temp_LM_CONSENSUS = 1 ./ cell2mat(FORECAST_LM_CONSENSUS(2:end,i));
%                 temp_CONSENSUS = 1 ./ cell2mat(FORECAST_CONSENSUS(2:end,i));
%                 temp_BOTTOM = 1 ./ cell2mat(FORECAST_TOP(2:end,i));
%                 temp_TOP = 1 ./ cell2mat(FORECAST_BOTTOM(2:end,i));
% 
%                 FORECAST_LM_CONSENSUS(2:end,i) = mat2cell(temp_LM_CONSENSUS,ones(size(temp_LM_CONSENSUS)));
%                 FORECAST_CONSENSUS(2:end,i) = mat2cell(temp_CONSENSUS,ones(size(temp_CONSENSUS)));
%                 FORECAST_BOTTOM(2:end,i) = mat2cell(temp_BOTTOM,ones(size(temp_BOTTOM)));
%                 FORECAST_TOP(2:end,i) = mat2cell(temp_TOP,ones(size(temp_TOP)));
%             end
%         end
%     end
%     clear count date i j k day_str month_str year_str a b i j country_list temp_LM_CONSENSUS temp_CONSENSUS temp_BOTTOM temp_TOP
% 
%     FORECAST_LM_CONSENSUS(3:end,1) = FORECAST_LM_CONSENSUS(2:end-1,1);
%     FORECAST_LM_CONSENSUS(2,:) = [];
%     % due to missing month get forecasts in from the month before
%     % % row with missing info
%     % find(all(isnan(cell2mat(FORECAST_BOTTOM(2:end,2:end))),2))
%     if mod(h,2) ~= 0
%         FORECAST_LM_CONSENSUS(find(all(isnan(cell2mat(FORECAST_LM_CONSENSUS(2:end,2:end))),2))+1,2:end) = FORECAST_LM_CONSENSUS(find(all(isnan(cell2mat(FORECAST_LM_CONSENSUS(2:end,2:end))),2)),2:end);
%     else
%         FORECAST_LM_CONSENSUS(find(all(isnan(cell2mat(FORECAST_BOTTOM(2:end,2:end))),2)),2:end) = FORECAST_LM_CONSENSUS(find(all(isnan(cell2mat(FORECAST_BOTTOM(2:end,2:end))),2))-1,2:end);
%     end
%     FORECAST_CONSENSUS(find(all(isnan(cell2mat(FORECAST_CONSENSUS(2:end,2:end))),2))+1,2:end) = FORECAST_CONSENSUS(find(all(isnan(cell2mat(FORECAST_CONSENSUS(2:end,2:end))),2)),2:end);
%     FORECAST_BOTTOM(find(all(isnan(cell2mat(FORECAST_BOTTOM(2:end,2:end))),2))+1,2:end) = FORECAST_BOTTOM(find(all(isnan(cell2mat(FORECAST_BOTTOM(2:end,2:end))),2)),2:end);
%     FORECAST_TOP(find(all(isnan(cell2mat(FORECAST_TOP(2:end,2:end))),2))+1,2:end) = FORECAST_TOP(find(all(isnan(cell2mat(FORECAST_TOP(2:end,2:end))),2)),2:end);
% 
%     % Transform FX forecasts to be consistent with the form of real GDP growth
%     % and inflation
%     if h == 7
%         country_list = fieldnames(SPOT_MID_ts);
%         country_list = country_list(4:end)';
%         SPOT_MID_ts = rmfield(SPOT_MID_ts,setdiff(country_list,FORECAST_TOP(1,2:end)));
%         country_list = intersect(FORECAST_TOP(1,2:end),country_list);
%         i = 2;
%         while i <= (size(FORECAST_TOP,2))
%             if ~any(strcmp(FORECAST_TOP(1,i),country_list))
%                 B_fin_missed = [B_fin_missed, FORECAST_TOP(1,i)];
%                 FORECAST_LM_CONSENSUS(:,i) = [];
%                 FORECAST_CONSENSUS(:,i) = [];
%                 FORECAST_BOTTOM(:,i) = [];
%                 FORECAST_TOP(:,i) = [];
%             else
%                 i = i + 1;
%             end
%         end
%         clear i country_list
%         FORECAST_CONSENSUS_temp = FORECAST_CONSENSUS; % copy of short run FX consensus
%         [a b] = size(FORECAST_TOP);
%         year_lim = 1992;
%         date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%         for i = 2:a
%             for j = 2:b
%                 if datenum(FORECAST_TOP(i,1),'dd/mm/yy') < date_lim
%                     if i < a
%                         if datenum(FORECAST_TOP(i+1,1),'dd/mm/yy') < date_lim
%                             FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                         else
%                             FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / cell2mat(FORECAST_CONSENSUS_temp(i,j)) - 1)*100};
%                         end
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                 else
%                     year_lim = year_lim + 1;
%                     if i < a
%                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(SPOT_MID_ts(find(year(SPOT_MID_ts.dates) == year_lim)).(FORECAST_TOP(1,j))) - 1)*100};
%                     date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%                 end
%             end
%         end
%         clear SPOT_MID_ts
%     end
%     if h == 8
%         [a b] = size(FORECAST_TOP);
%         for i = 2:a
%             for j = 2:b
%                 if i < a
%                     FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / cell2mat(FORECAST_CONSENSUS_temp(i,j)) - 1)*100};
%                 end
%                 FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / cell2mat(FORECAST_CONSENSUS_temp(i,j)) - 1)*100};
%                 FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / cell2mat(FORECAST_CONSENSUS_temp(i,j)) - 1)*100};
%                 FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / cell2mat(FORECAST_CONSENSUS_temp(i,j)) - 1)*100};
%             end
%         end
%         clear FORECAST_CONSENSUS_temp
%     end
% 
%     % Transform CA forecasts
%     if h == 5
%         country_list = fieldnames(GDP_ALL_ts);
%         country_list = country_list(4:end)';
%         GDP_ALL_ts = rmfield(GDP_ALL_ts,setdiff(country_list,FORECAST_TOP(1,2:end)));
%         country_list = intersect(FORECAST_TOP(1,2:end),country_list);
%         i = 2;
%         while i <= (size(FORECAST_TOP,2))
%             if ~any(strcmp(FORECAST_TOP(1,i),country_list))
%                 B_fin_missed = [B_fin_missed, FORECAST_TOP(1,i)];
%                 FORECAST_LM_CONSENSUS(:,i) = [];
%                 FORECAST_CONSENSUS(:,i) = [];
%                 FORECAST_BOTTOM(:,i) = [];
%                 FORECAST_TOP(:,i) = [];
%             else
%                 i = i + 1;
%             end
%         end
%         clear i country_list
%         FORECAST_CONSENSUS_temp = FORECAST_CONSENSUS;
%         [a b] = size(FORECAST_TOP);
%         year_lim = 1992;
%         date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%         for i = 2:a
%             for j = 2:b
%                 if datenum(FORECAST_TOP(i,1),'dd/mm/yy') < date_lim
%                     if i < a
%                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                 else
%                     year_lim = year_lim + 1;
%                     if i < a
%                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%                 end
%             end
%         end
%     end
%     if h == 6
%         [a b] = size(FORECAST_TOP);
%         year_lim = 1992;
%         date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%         
%         for i = 2:a
%             for j = 2:b
%                 if datenum(FORECAST_TOP(i,1),'dd/mm/yy') < date_lim
%                     if i < a
%                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                 else
%                     year_lim = year_lim + 1;
%                     if i < a
%                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     end
%                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j))))*100};
%                     date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%                 end
%             end
%         end
%         % % previous version which uses (1+GDPgrowth_CONSENSUS) to come up with forecast of GDP level at the end of current year which ultimately gets used to scale LR CA forecast
%         %         for i = 2:a
%         %             for j = 2:b
%         %                 if datenum(FORECAST_TOP(i,1),'dd/mm/yy') < date_lim
%         %                     if i < a
%         %                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     end
%         %                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                 else
%         %                     year_lim = year_lim + 1;
%         %                     if i < a
%         %                         FORECAST_LM_CONSENSUS(i,j) = {(cell2mat(FORECAST_LM_CONSENSUS(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     end
%         %                     FORECAST_CONSENSUS(i,j) = {(cell2mat(FORECAST_CONSENSUS(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     FORECAST_BOTTOM(i,j) = {(cell2mat(FORECAST_BOTTOM(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     FORECAST_TOP(i,j) = {(cell2mat(FORECAST_TOP(i,j)) / ((1 + cell2mat(FORECAST(1,1).CONSENSUS(i,find(strcmp(FORECAST_TOP(1,j),FORECAST(1,1).CONSENSUS(1,:)))))/100) * fts2mat(GDP_ALL_ts(find(year(GDP_ALL_ts.dates) == year_lim)).(FORECAST_TOP(1,j)))))*100};
%         %                     date_lim = busdate(datenum(year_lim+2,1,1+gather_day),-1);
%         %                 end
%         %             end
%         %         end
%         clear FORECAST_CONSENSUS_temp
%     end
% 
%     % visual data analysis & outlier removal
%     if mod(h,2) == 0
%         forecast_handle = 'Long run-';
%     else
%         forecast_handle = 'Short run-';
%     end
%     figure;
%     for i = 2:size(FORECAST_TOP,2)
%         CONSENSUS_outliers = {};
% 
%         %         % plot original series
%         %         plot(datenum(FORECAST_CONSENSUS(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_CONSENSUS(2:end,i)),'b');
%         %         hold on
%         %         plot(datenum(FORECAST_BOTTOM(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_BOTTOM(2:end,i)),'r');
%         %         plot(datenum(FORECAST_TOP(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_TOP(2:end,i)),'g');
%         %         legend('CONSENSUS', 'Bottom 3 Avg.','Top 3 Avg.','Location','SouthOutside');
%         %         xlabel('time');
%         %         ylabel('Forecasts');
%         %         title(strcat(forecast_handle,FORECAST_TOP(1,i),{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
%         %         datetick('x','yy','keepticks');
%         %         hold off
%         %         % check for inconsistency between forecasts
%         %         fprintf('CONSENSUS < bottom:\n');
%         %         FORECAST_TOP(find(cell2mat(FORECAST_CONSENSUS(2:end,i)) < cell2mat(FORECAST_BOTTOM(2:end,i)))+1,1)
%         %         fprintf('CONSENSUS > top:\n');
%         %         FORECAST_TOP(find(cell2mat(FORECAST_TOP(2:end,i)) < cell2mat(FORECAST_CONSENSUS(2:end,i)))+1,1)
%         %         fprintf('bottom > top:\n');
%         %         FORECAST_TOP(find(cell2mat(FORECAST_TOP(2:end,i)) < cell2mat(FORECAST_BOTTOM(2:end,i)))+1,1)
%         %         pause;
% 
%         % try to identify short-lived "dodgy" jumps
%         % was able to identify "well" for stationary series on real GDP growth, inflation, and short interest rates
%         fprintf('extreme short-lived jumps:\n');
% 
%         % CASE 2 - use winsorisation where some number (1 to winsor-1)
%         % highest deviations from consensus of top and bottom are changed
%         % to winsor-th largest deviation. Prior to that CONSENSUS is
%         % adjusted for outliers consistent with procedure above:
%         % identify abnormal deviations of CONSENSUS and substitute for
%         % "normalised". Food for thought - here correct is to use CONSENSUS
%         % and not LM_CONSENSUS for TOP / BOTTOM adjustments because last 
%         % month TOP and BOT are not available (the last month figures could
%         % reflect not just mistakes but also forecasts not previously 
%         % available)
%         multiplier = 3;
%         current_CONSENSUS = cell2mat(FORECAST_CONSENSUS(3:end-1,i));
%         previous_CONSENSUS = cell2mat(FORECAST_CONSENSUS(2:end-2,i));
%         next_CONSENSUS = cell2mat(FORECAST_CONSENSUS(4:end,i));
%         overall_CONSENSUS = cell2mat(FORECAST_CONSENSUS(find(~isnan(cell2mat(FORECAST_CONSENSUS(2:end,i))))+1,i));
%         CONSENSUS_outliers = FORECAST_CONSENSUS(find(...
%             ((current_CONSENSUS-previous_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (current_CONSENSUS-next_CONSENSUS > multiplier*std(overall_CONSENSUS))) |...
%             ((previous_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (next_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)))...
%             )+2,1) % note: can't simply put abs() since there might be intermediary points (between "high up" and "high down")
%         if strcmp(robust_to_outliers,'yes - adhoc')
%             if ~isempty(CONSENSUS_outliers)
%                 CONSENSUS_temp = FORECAST_CONSENSUS(2:end,i);
%                 CONSENSUS_censored = previous_CONSENSUS + sign(current_CONSENSUS-previous_CONSENSUS)*multiplier*std(overall_CONSENSUS);
%                 CONSENSUS_censored = mat2cell(CONSENSUS_censored,ones(size(CONSENSUS_censored,1),1),ones(1,size(CONSENSUS_censored,2)));
%                 CONSENSUS_temp(find(...
%                     ((current_CONSENSUS-previous_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (current_CONSENSUS-next_CONSENSUS > multiplier*std(overall_CONSENSUS))) |...
%                     ((previous_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (next_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)))...
%                     )+1,1) = CONSENSUS_censored(find(...
%                     ((current_CONSENSUS-previous_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (current_CONSENSUS-next_CONSENSUS > multiplier*std(overall_CONSENSUS))) |...
%                     ((previous_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)) & (next_CONSENSUS-current_CONSENSUS > multiplier*std(overall_CONSENSUS)))...
%                     ),1);
%                 diff_temp = cell2mat(CONSENSUS_temp) - cell2mat(FORECAST_CONSENSUS(2:end,i));
%                 diff_temp(find(isnan(diff_temp))) = 0;
%                 FORECAST_BOTTOM(2:end,i) = mat2cell(cell2mat(FORECAST_BOTTOM(2:end,i)) + diff_temp,ones(size(FORECAST_BOTTOM(2:end,i),1),1),ones(size(FORECAST_BOTTOM(2:end,i),2),1));
%                 FORECAST_TOP(2:end,i) = mat2cell(cell2mat(FORECAST_TOP(2:end,i)) + diff_temp,ones(size(FORECAST_TOP(2:end,i),1),1),ones(size(FORECAST_TOP(2:end,i),2),1));
%                 FORECAST_CONSENSUS(2:end,i) = CONSENSUS_temp;
%                 clear CONSENSUS_temp CONSENSUS_censored diff_temp
%             end
%             overall_top = cell2mat(FORECAST_TOP(2:end,i))-cell2mat(FORECAST_CONSENSUS(2:end,i));
%             overall_bottom = cell2mat(FORECAST_CONSENSUS(2:end,i))-cell2mat(FORECAST_BOTTOM(2:end,i));
%             top_sorted = sort(overall_top(find(~isnan(overall_top))),'descend');
%             bottom_sorted = sort(overall_bottom(find(~isnan(overall_bottom))),'descend');
%             if ~isempty(find(overall_top > top_sorted(winsor)))
%                 top_ans = cell2mat(FORECAST_CONSENSUS(find(overall_top > top_sorted(winsor))+1,i)) + top_sorted(winsor)*ones(size(find(overall_top > top_sorted(winsor))));
%                 FORECAST_TOP(find(overall_top > top_sorted(winsor))+1,i) = mat2cell(top_ans,ones(size(top_ans,1),1),ones(size(top_ans,2),1));
%                 clear top_ans
%             end
%             if ~isempty(find(overall_bottom > bottom_sorted(winsor)))
%                 bottom_ans = cell2mat(FORECAST_CONSENSUS(find(overall_bottom > bottom_sorted(winsor))+1,i)) - bottom_sorted(winsor)*ones(size(find(overall_bottom > bottom_sorted(winsor))));
%                 FORECAST_BOTTOM(find(overall_bottom > bottom_sorted(winsor))+1,i) = mat2cell(bottom_ans,ones(size(bottom_ans,1),1),ones(size(bottom_ans,2),1));
%                 clear bottom_ans
%             end
%             clear bottom_sorted top_sorted overall_bottom overall_top
% 
%             %             % Display the outlier-adjusted series to compare vs. "original"
%             %             figure
%             %             plot(datenum(FORECAST_CONSENSUS(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_CONSENSUS(2:end,i)),'b');
%             %             hold on
%             %             plot(datenum(FORECAST_BOTTOM(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_BOTTOM(2:end,i)),'r');
%             %             plot(datenum(FORECAST_TOP(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_TOP(2:end,i)),'g');
%             %             legend('CONSENSUS', 'Bottom 3 Avg.','Top 3 Avg.','Location','SouthOutside');
%             %             xlabel('time');
%             %             ylabel('Forecasts');
%             %             title(strcat(forecast_handle,FORECAST_TOP(1,i),{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
%             %             datetick('x','yy','keepticks');
%             %             hold off
%             %             % check for inconsistency between forecasts
%             %             fprintf('CONSENSUS < bottom:\n');
%             %             FORECAST_TOP(find(cell2mat(FORECAST_CONSENSUS(2:end,i)) < cell2mat(FORECAST_BOTTOM(2:end,i)))+1,1)
%             %             fprintf('CONSENSUS > top:\n');
%             %             FORECAST_TOP(find(cell2mat(FORECAST_TOP(2:end,i)) < cell2mat(FORECAST_CONSENSUS(2:end,i)))+1,1)
%             %             fprintf('bottom > top:\n');
%             %             FORECAST_TOP(find(cell2mat(FORECAST_TOP(2:end,i)) < cell2mat(FORECAST_BOTTOM(2:end,i)))+1,1)
%             %             pause;
%             %             saveas(gcf, char(strcat(cd_old,'\Figures\Initial forecasts w-o outliers\', 'Forecast_', forecast_handle, MAD_variables(floor((h+1)/2)),'_',FORECAST_TOP(1,i), '.', ext)), ext); % gcf brings in the current figure handle
%             %             close
% 
%         end
%         clc
%         %         if strcmp(robust_to_outliers,'no')
%         %             saveas(gcf, char(strcat(cd_old,'\Figures\Initial forecasts\', 'Forecast_', forecast_handle, MAD_variables(floor((h+1)/2)),'_',FORECAST_TOP(1,i), '.', ext)), ext); % gcf brings in the current figure handle
%         %         end
%     end
%     close
% 
%     % if some country is removed (e.g. for FX - China) do the same for other
%     % already created variables
%     for j = 1:length(B_fin_missed)
%         for i = 1:h-1
%             if any(strcmp(B_fin_missed(j),FORECAST(1,i).TOP(1,2:end)))
%                 FORECAST(1,i).LM_CONSENSUS(:,find(strcmp(B_fin_missed(j),FORECAST(1,i).TOP(1,:)))) = [];
%                 FORECAST(1,i).CONSENSUS(:,find(strcmp(B_fin_missed(j),FORECAST(1,i).TOP(1,:)))) = [];
%                 FORECAST(1,i).BOTTOM(:,find(strcmp(B_fin_missed(j),FORECAST(1,i).TOP(1,:)))) = [];
%                 FORECAST(1,i).TOP(:,find(strcmp(B_fin_missed(j),FORECAST(1,i).TOP(1,:)))) = [];
%             end
%         end
%     end
% 
%     FORECAST(1,h).LM_CONSENSUS = FORECAST_LM_CONSENSUS;
%     FORECAST(1,h).CONSENSUS = FORECAST_CONSENSUS;
%     FORECAST(1,h).BOTTOM = FORECAST_BOTTOM;
%     FORECAST(1,h).TOP = FORECAST_TOP;
% end
% clear h i j SPOT_MID_txt SPOT_MID GDP_EU_txt GDP_EU GDP_ALL_txt GDP_ALL FORECAST_LM_CONSENSUS FORECAST_BOTTOM FORECAST_CONSENSUS FORECAST_TOP multiplier ans forecast_handle next_CONSENSUS previous_CONSENSUS CONSENSUS_outliers current_CONSENSUS overall_CONSENSUS winsor date1 date2 date_lim year_lim
% 
% % % Check when CONSENSUS in current issue not consistent with last month
% % % CONSENSUS in the next issue (should be the same really but as turns out
% % % it is not often the case)
% % for h = 1:2:9
% %     FORECAST_SR_temp = FORECAST(1,h).CONSENSUS;
% %     FORECAST_LR_temp = FORECAST(1,h+1).CONSENSUS;
% % 
% %     [a b] = size(FORECAST(1,h).TOP);
% %     for i = 2:a
% %         k = month(datenum(FORECAST(1,h).TOP(i,1),'dd/mm/yy'));
% %         if k == 11
% %             FORECAST_SR_temp(i,2:end) = FORECAST(1,h+1).CONSENSUS(i,2:end);
% %             FORECAST_LR_temp(i,2:end) = {NaN};
% %         end
% %     end
% %     figure;
% %     for i = 2:b
% %         fprintf('SHORT RUN case: this issue CONSENSUS ~= next issue last month CONSENSUS:\n');
% %         [h FORECAST(1,h).TOP(1,i)]
% %         FORECAST(1,h).TOP(find(cell2mat(FORECAST_SR_temp(2:end-1,i)) ~= cell2mat(FORECAST(1,h).LM_CONSENSUS(2:end,i)) & (~isnan(cell2mat(FORECAST_SR_temp(2:end-1,i))) | ~isnan(cell2mat(FORECAST(1,h).LM_CONSENSUS(2:end,i)))))+1,1)
% %         plot(cell2mat(FORECAST_SR_temp(2:end-1,i)),'b')
% %         hold on
% %         plot(cell2mat(FORECAST(1,h).LM_CONSENSUS(2:end,i)),'r')
% %         hold off
% %         pause;
% %         clc;
% %         [h FORECAST(1,h).TOP(1,i)]
% %         fprintf('LONG RUN case: this issue CONSENSUS ~= next issue last month CONSENSUS:\n');
% %         FORECAST(1,h).TOP(find((cell2mat(FORECAST_LR_temp(2:end-1,i)) ~= cell2mat(FORECAST(1,h+1).LM_CONSENSUS(2:end,i))) & (~isnan(cell2mat(FORECAST_LR_temp(2:end-1,i))) | ~isnan(cell2mat(FORECAST(1,h+1).LM_CONSENSUS(2:end,i)))))+1,1)
% %         plot(cell2mat(FORECAST_LR_temp(2:end-1,i)),'b')
% %         hold on
% %         plot(cell2mat(FORECAST(1,h+1).LM_CONSENSUS(2:end,i)),'r')
% %         hold off
% %         pause;
% %         clc;
% %     end
% %     close;
% % end
% 
% save 'Data\OUTPUT\BCEI_Data' FORECAST -append;
% % Note: LM_CONSENSUS is not used anymore after this section

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Adjust all series for seasonality, i.e. clean data stage 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FORECAST_seas_adj = FORECAST; % use unadjusted
if strcmp(robust_to_seasonality,'yes')
    % TRAMO-SEATS seasonality adjustment
    % % General option for TRAMO-SEATS as specified in function guide (removing regression part)
    % 'lam=-1,itrad=-7,ieast=-1,idur=9,inic=3,idif=3,iatip=1,aio=2'
    % 'out=0,lam=1,itrad=0,ieast=0,inic=3,idif=3,iatip=0,aio=0,seats=2'
    opts = 'lam=-1,itrad=-7,ieast=-1,idur=9,inic=3,idif=3,iatip=1,aio=2';
    count1 = 0;
    count2 = 0;
    for h = 1:size(FORECAST,2)-4 % because last two variables are not really seasonal
        for i = 2:size(FORECAST(1,h).TOP,2)
            series = cell2mat(FORECAST(1,h).CONSENSUS(2:end,i));
            fin_rows = find(~isnan(series));
            nan_rows = find(isnan(series));
            if isempty(fin_rows)
                start = length(series);
            else
                start = fin_rows(1);
            end
            nan_rows = nan_rows(find(nan_rows > start));
            if isempty(nan_rows)
                finish = length(series);
            else
                finish = nan_rows(1)-1;
            end
            while start < size(FORECAST(1,h).TOP,1)-1
                if length(start:finish)>=36 % minimum amount of observations
                    result = ts(series(start:finish),FORECAST(1,h).TOP(1,i),year(datenum(FORECAST(1,h).TOP(start+1,1),'dd/mm/yy')),month(datenum(FORECAST(1,h).TOP(start+1,1),'dd/mm/yy')),12,[opts]);
                    if any(strcmp('safin',fieldnames(result))) % for some reason not always safin is provided even if time-series is uninterrupted
                        FORECAST_seas_adj(1,h).CONSENSUS(1+start:1+finish,i) = mat2cell(result.safin,ones(size(result.safin,1),1),ones(1,size(result.safin,2)));
                    else
                        count1 = count1 + 1;
                    end
                else
                    count2 = count2 + 1;
                end
                fin_rows = fin_rows(find(fin_rows > finish));
                if isempty(fin_rows)
                    start = length(series);
                else
                    start = fin_rows(1);
                end
                nan_rows = nan_rows(find(nan_rows > start));
                if isempty(nan_rows)
                    finish = length(series);
                else
                    finish = nan_rows(1)-1;
                end
            end
            new_series = cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i));

            %             % plot seasonality-adjusted and original data
            %             figure;
            %             plot(datenum(FORECAST_seas_adj(1,h).TOP(2:end,1),'dd/mm/yy'), series, 'b');
            %             hold on
            %             plot(datenum(FORECAST_seas_adj(1,h).TOP(2:end,1),'dd/mm/yy'), new_series, 'r');
            %             xlabel('time');
            %             ylabel('# of individual MADs available');
            %             legend('original', 'seasonally-adj.','Location','SouthOutside');
            %             if mod(h,2) == 0
            %                 forecast_handle = 'Long run-';
            %             else
            %                 forecast_handle = 'Short run-';
            %             end
            %             title(strcat(FORECAST(1,h).TOP(1,i),{' '},forecast_handle,{' '},MAD_variables(floor((h+1)/2))));
            %             datetick('x','yy');
            %             pause;
            %             saveas(gcf, char(strcat(cd_old,'\Figures\Seasonality adjustment\', FORECAST(1,h).TOP(1,i),{' '},forecast_handle,{' '},MAD_variables(floor((h+1)/2)),'.', ext)), ext); % gcf brings in the current figure handle
            %             close

            clc
        end
        FORECAST_seas_adj(1,h).TOP(2:end,2:end) = mat2cell(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,2:end)) + cell2mat(FORECAST(1,h).TOP(2:end,2:end)) - cell2mat(FORECAST(1,h).CONSENSUS(2:end,2:end)),ones(size(FORECAST(1,h).TOP(2:end,2:end),1),1),ones(1,size(FORECAST(1,h).TOP(2:end,2:end),2)));
        FORECAST_seas_adj(1,h).BOTTOM(2:end,2:end) = mat2cell(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,2:end)) + cell2mat(FORECAST(1,h).BOTTOM(2:end,2:end)) - cell2mat(FORECAST(1,h).CONSENSUS(2:end,2:end)),ones(size(FORECAST(1,h).TOP(2:end,2:end),1),1),ones(1,size(FORECAST(1,h).TOP(2:end,2:end),2)));
%         % check for inconsistency between forecasts - note: there are some
%         % small deviations due to rounding errors as one will see - authors
%         % simply ignored them
%         for i = 2:size(FORECAST(1,h).TOP,2)
%             fprintf('CONSENSUS < bottom:\n');
%             FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,1)
%             if ~isempty(FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,1))
%                 FORECAST_seas_adj(1,h).CONSENSUS(find(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,i)
%                 FORECAST_seas_adj(1,h).BOTTOM(find(cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,i)
%             end
%             fprintf('CONSENSUS > top:\n');
%             FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)))+1,1)
%             if ~isempty(FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)))+1,1))
%                 FORECAST_seas_adj(1,h).CONSENSUS(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)))+1,i)
%                 FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(2:end,i)))+1,i)
%             end
%             fprintf('bottom > top:\n');
%             FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,1)
%             if ~isempty(FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,1))
%                 FORECAST_seas_adj(1,h).BOTTOM(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,i)
%                 FORECAST_seas_adj(1,h).TOP(find(cell2mat(FORECAST_seas_adj(1,h).TOP(2:end,i)) < cell2mat(FORECAST_seas_adj(1,h).BOTTOM(2:end,i)))+1,i)
%             end
%             pause;
%             clc
%         end
    end
end
clear count1 count2 fin_rows finish forecast_handle h i nan_rows new_series opts series start
save 'Data\OUTPUT\BCEI_Data' FORECAST_seas_adj -append;

% % Get all forecasts saved in .xlsx for potential manip
% for i = 1:size(FORECAST,2)
%     if mod(i,2) == 0
%         forecast_handle = 'Long_run_';
%     else
%         forecast_handle = 'Short_run_';
%     end
%     sheet_names_array(1,i) = strcat(forecast_handle,MAD_variables(floor((i+1)/2)));
% end
% % check what field names the structure has in order to choose which to pass
% % to the function below for exporting to excel
% field_names_list = fieldnames(FORECAST);
% AK_EXPORT_TO_XLSX(FORECAST,'DATA\OUTPUT\AK_FORECAST_DATA_',field_names_list,sheet_names_array);
% AK_EXPORT_TO_XLSX(FORECAST_seas_adj,'DATA\OUTPUT\AK_FORECAST_DATA_SEAS_ADJ_',field_names_list,sheet_names_array);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Construction of various specifications of individual (i.e. per
% country) MAD series for each variable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Construct constant maturity individual MADs
MAD_calc_string = {...
    'sqrt((log(TOP_fixh) - log(BOTTOM_fixh)))';... % proxy 1: below is the attempt to construct MAD as in Beber et al. (2010)
    'TOP_fixh - BOTTOM_fixh';... % proxy 2: "simple TOP minus BOTTOM"
    '100*sqrt(1/log(2))*0.5*(TOP_fixh - BOTTOM_fixh)';... % proxy 2: "simple TOP minus BOTTOM"
    % '((log(TOP_fixh) - log(BOTTOM_fixh))/2) / sqrt(0.5*(log(TOP_fixh) - log(CONSENSUS_fixh))^2 + 0.5*(log(BOTTOM_fixh) - log(CONSENSUS_fixh))^2)';...
    % 'sqrt(0.5*(log(TOP_fixh) - log(CONSENSUS_fixh))^2 + 0.5*(log(BOTTOM_fixh) - log(CONSENSUS_fixh))^2)'
    };
choice = 1; % picks the corresponding element from the string right above

MAD_indiv = [];
MAD_indiv_all = {};
CONS_indiv_all = {};
Desc_stats_all_MAD = [];
Desc_stats_all_CONS = [];

for h = 1:2:9
    % Construct individual MADs
    [a b] = size(FORECAST_seas_adj(1,h).TOP);
    for i = 2:a
        k = mod(i+issue_month-3,12); % adjust according to the starting month
        for j = 2:b
            % with fixed forecast horizon as in Buraschi and Whelan (2012)
            TOP_fixh = (1-k/12)*cell2mat(FORECAST_seas_adj(1,h).TOP(i,j)) + (k/12)*cell2mat(FORECAST_seas_adj(1,h+1).TOP(i,j));
            BOTTOM_fixh = (1-k/12)*cell2mat(FORECAST_seas_adj(1,h).BOTTOM(i,j)) + (k/12)*cell2mat(FORECAST_seas_adj(1,h+1).BOTTOM(i,j));
            CONSENSUS_fixh = (1-k/12)*cell2mat(FORECAST_seas_adj(1,h).CONSENSUS(i,j)) + (k/12)*cell2mat(FORECAST_seas_adj(1,h+1).CONSENSUS(i,j));
            
            top_fixh_series(i-1,j-1) = TOP_fixh;
            bottom_fixh_series(i-1,j-1) = BOTTOM_fixh;
            consensus_fixh_series(i-1,j-1) = CONSENSUS_fixh;
            
            TOP_fixh = 1 + TOP_fixh/100;
            BOTTOM_fixh = 1 + BOTTOM_fixh/100;
            CONSENSUS_fixh = 1 + CONSENSUS_fixh/100;
            
            %                 % to check when CA forecasts are of different sign
            %                 if h == 5
            %                     if (sign(TOP_fixh) ~= sign(BOTTOM_fixh)) && (~isnan(TOP_fixh) && ~isnan(BOTTOM_fixh))
            %                         [FORECAST_seas_adj(1,h).TOP(i,1), FORECAST_seas_adj(1,h).TOP(1,j), FORECAST_seas_adj(1,h).TOP(i,j), FORECAST_seas_adj(1,h+1).TOP(i,j), FORECAST_seas_adj(1,h).BOTTOM(i,j), FORECAST_seas_adj(1,h+1).BOTTOM(i,j), TOP_fixh, BOTTOM_fixh]
            %                     end
            %                 end
            
            %                 mads = [abs(log(TOP_fixh) - log(CONSENSUS_fixh)); abs(log(BOTTOM_fixh) - log(CONSENSUS_fixh))];
            %                 % to check that mean(mads) coincides with (log(TOP_fixh) - log(BOTTOM_fixh))/2
            %                 if (mean(mads) ~= (log(TOP_fixh) - log(BOTTOM_fixh))/2) && ~isnan(mean(mads)) && ~isnan(log(TOP_fixh) - log(BOTTOM_fixh))
            %                     [mean(mads) (log(TOP_fixh)-log(BOTTOM_fixh))/2 log(TOP_fixh) log(CONSENSUS_fixh) log(BOTTOM_fixh)]
            %                 end
            
            % choose below how individual MAD measure is constructed
            % from array at the beginning of this section
            MAD_indiv(i-1,j-1) = eval(MAD_calc_string{choice});
        end
    end
    
    fixh.(MAD_variables{floor((h+1)/2)}).top = top_fixh_series;
    fixh.(MAD_variables{floor((h+1)/2)}).bot = bottom_fixh_series;
    fixh.(MAD_variables{floor((h+1)/2)}).cons = consensus_fixh_series;
    
    %     % plot fixed horizon forecasts
    %     figure;
    %     plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), top_fixh_series);
    %     xlabel('time');
    %     ylabel('const horison forecast');
    %     legend(FORECAST_seas_adj(1,1).TOP(1,2:end),'Location','NorthEastOutside');
    %     title(strcat('TOP const horison',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     figure;
    %     plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), consensus_fixh_series);
    %     xlabel('time');
    %     ylabel('const horison forecast');
    %     legend(FORECAST_seas_adj(1,1).TOP(1,2:end),'Location','NorthEastOutside');
    %     title(strcat('CONSENSUS const horison',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     figure;
    %     plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), bottom_fixh_series);
    %     xlabel('time');
    %     ylabel('const horison forecast');
    %     legend(FORECAST_seas_adj(1,1).TOP(1,2:end),'Location','NorthEastOutside');
    %     title(strcat('BOTTOM const horison',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     pause;
    %     % saveas(gcf, char(strcat(cd_old,'\Figures\Individual MADs by variable\', 'Country_number_', MAD_variables(floor((h+1)/2)),'.', ext)), ext); % gcf brings in the current figure handle
    %     close all
    
    MAD_indiv_cell = [...
        Data(1,7).text(1, 2*floor((h+1)/2)), FORECAST_seas_adj(1,1).TOP(1,2:end);...
        FORECAST_seas_adj(1,1).TOP(2:end,1), mat2cell(MAD_indiv,ones(size(MAD_indiv,1),1),ones(1,size(MAD_indiv,2)))...
        ];
    MAD_indiv_all = [MAD_indiv_all, {MAD_indiv_cell}];
    CONS_indiv_cell = [...
        Data(1,7).text(1, 2*floor((h+1)/2)), FORECAST_seas_adj(1,1).TOP(1,2:end);...
        FORECAST_seas_adj(1,1).TOP(2:end,1), mat2cell(consensus_fixh_series/100,ones(size(consensus_fixh_series,1),1),ones(1,size(consensus_fixh_series,2)))...
        ];
    CONS_indiv_all = [CONS_indiv_all, {CONS_indiv_cell}];

    %     % some descriptive stats for indiv MAD series across variables
    %     % plot number of individual MADs available
    %     figure;
    %     plot(fints(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), sum(~isnan(MAD_indiv),2)));
    %     min(sum(~isnan(MAD_indiv),2))
    %     max(sum(~isnan(MAD_indiv),2))
    %     xlabel('time');
    %     ylabel('# of individual MADs available');
    %     legend('off');
    %     title(strcat('Number of individual MADs v1',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     pause;
    %     clc
    %     saveas(gcf, char(strcat(cd_old,'\Figures\Individual MADs by variable\', 'Country_number_', MAD_variables(floor((h+1)/2)),'.', ext)), ext); % gcf brings in the current figure handle
    %     close
    
    % Descriptive stats on MADs
    output = AK_DESC_STATS(MAD_indiv_cell(2:end,2:end),'series_names',MAD_indiv_cell(1,2:end));
    Desc_stats_single = output.summary;
    Desc_stats_single(1,1) = MAD_variables(floor((h+1)/2));
    Desc_stats_all_MAD = [Desc_stats_all_MAD, {Desc_stats_single}];
    
    % Descriptive stats on consensus
    output = AK_DESC_STATS(CONS_indiv_cell(2:end,2:end),'series_names',CONS_indiv_cell(1,2:end));
    Desc_stats_single = output.summary;
    Desc_stats_single(1,1) = MAD_variables(floor((h+1)/2));
    Desc_stats_all_CONS = [Desc_stats_all_CONS, {Desc_stats_single}];

    %     figure;
    %     % Plot individual MAD time series by variable
    %     plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'),MAD_indiv);
    %     xlabel('time');
    %     ylabel('individual MADs');
    %     legend(FORECAST_seas_adj(1,1).TOP(1,2:end),'Location','NorthEastOutside');
    %     title(strcat('Individual MADs v1',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     grid off
    %     FORECAST_seas_adj(1,1).TOP(any(MAD_indiv<0,2),1)
    %     pause;
    %     clc
    %     saveas(gcf, [char(strcat(cd_old,'\Figures\Individual MADs by variable\', 'MAD_', MAD_variables(floor((h+1)/2)),'.', ext))], ext); % gcf brings in the current figure handle
    %     % Plot individual CONS time series by variable
    %     plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'),consensus_fixh_series);
    %     xlabel('time');
    %     ylabel('individual CONSs');
    %     legend(FORECAST_seas_adj(1,1).TOP(1,2:end),'Location','NorthEastOutside');
    %     title(strcat('Individual CONSs',{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
    %     datetick('x','yy');
    %     grid off
    %     pause;
    %     close
    
    MAD_indiv = [];
    consensus_fixh_series = [];
end
clear ans a b h i j k A B A_fin B_fin mads TOP_fixh BOTTOM_fixh CONSENSUS_fixh MAD_indiv MAD_indiv_cell Desc_stats_single output MAD_calc_string choice bottom_fixh_series consensus_fixh_series top_fixh_series

% figure;
% for i = 2:size(MAD_indiv_all{1,1},2)
%     % some descriptive stats for indiv MAD series across countries
%     % Plot individual MAD time series by country
%     fact_number = size(MAD_indiv_all,2);
%     for j = 1:fact_number
%         subplot(fact_number,1,j);
%         plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), cell2mat(MAD_indiv_all{1,j}(2:end,i)));
%         xlabel('time');
%         ylabel('individual MADs');
%         title(strcat(FORECAST_seas_adj(1,1).TOP(1,i),{' '},Desc_stats_all_MAD{1,j}{1,1}));
%         datetick('x','yy');
%         grid off
%     end
%     pause;
%     saveas(gcf, char(strcat(cd_old,'\Figures\Individual MADs by country\', 'MAD_', FORECAST_seas_adj(1,1).TOP(1,i),'.', ext)), ext); % gcf brings in the current figure handle
%     for j = 1:fact_number
%         subplot(fact_number,1,j);
%         plot(datenum(FORECAST_seas_adj(1,1).TOP(2:end,1),'dd/mm/yy'), cell2mat(CONS_indiv_all{1,j}(2:end,i)));
%         xlabel('time');
%         ylabel('individual CONSs');
%         title(strcat(FORECAST_seas_adj(1,1).TOP(1,i),{' '},Desc_stats_all_CONS{1,j}{1,1}));
%         datetick('x','yy');
%         grid off
%     end
%     pause;
%     clear ans temp
% end
% clear i j fact_number
% close;

country_list = {'GERMANY','FRANCE','NETHERLANDS','BELGIUM','ITALY'};
date = busdate(datenum(1999,1,1+gather_day),-1);
for h = 1:length(MAD_indiv_all)
    for i = 2:size(MAD_indiv_all{1,h},1)
        if (h <= 3 && datenum(MAD_indiv_all{1,h}(i,1),'dd/mm/yy') == date)
            if since_euro == 1
                % fill in MADs for the missing 1998 year of Eurozone macro
                temp = [];
                for j = 1:length(country_list)
                    temp = [temp MAD_indiv_all{1,h}(i:i+11,find(strcmp(country_list(j),MAD_indiv_all{1,h}(1,:))))];
                end
                % below two options:
                % 1) MAD_indiv_all{1,h}(i:i+11,find(strcmp('GERMANY',MAD_indiv_all{1,h}(1,:))));
                % 2) mat2cell(nanmean(cell2mat(temp),2),ones(size(temp,1),1),1);
                MAD_indiv_all{1,h}(i:i+11,find(strcmp('EUROZONE',MAD_indiv_all{1,h}(1,:)))) = MAD_indiv_all{1,h}(i:i+11,find(strcmp('GERMANY',MAD_indiv_all{1,h}(1,:))));
                CONS_indiv_all{1,h}(i:i+11,find(strcmp('EUROZONE',CONS_indiv_all{1,h}(1,:)))) = CONS_indiv_all{1,h}(i:i+11,find(strcmp('GERMANY',CONS_indiv_all{1,h}(1,:))));                
                for j = 1:length(country_list)
                    MAD_indiv_all{1,h}(i:end,find(strcmp(country_list(j),MAD_indiv_all{1,h}(1,:)))) = {NaN};
                    CONS_indiv_all{1,h}(i:end,find(strcmp(country_list(j),CONS_indiv_all{1,h}(1,:)))) = {NaN};
                end
                break;
            elseif since_euro == 2
                % fill in MADs for the whole Eurozone macro from individual
                % countries macro
                temp = [];
                for j = 1:length(country_list)
                    temp = [temp MAD_indiv_all{1,h}(i:end,find(strcmp(country_list(j),MAD_indiv_all{1,h}(1,:))))];
                end
                % below two options:
                % 1) MAD_indiv_all{1,h}(i:end,find(strcmp('GERMANY',MAD_indiv_all{1,h}(1,:))));
                % 2) mat2cell(nanmean(cell2mat(temp),2),ones(size(temp,1),1),1);
                MAD_indiv_all{1,h}(i:end,find(strcmp('EUROZONE',MAD_indiv_all{1,h}(1,:)))) = MAD_indiv_all{1,h}(i:end,find(strcmp('GERMANY',MAD_indiv_all{1,h}(1,:))));
                CONS_indiv_all{1,h}(i:end,find(strcmp('EUROZONE',CONS_indiv_all{1,h}(1,:)))) = CONS_indiv_all{1,h}(i:end,find(strcmp('GERMANY',CONS_indiv_all{1,h}(1,:))));
                for j = 1:length(country_list)
                    MAD_indiv_all{1,h}(i:end,find(strcmp(country_list(j),MAD_indiv_all{1,h}(1,:)))) = {NaN};
                    CONS_indiv_all{1,h}(i:end,find(strcmp(country_list(j),CONS_indiv_all{1,h}(1,:)))) = {NaN};
                end
                break;
            end
        end
    end
end
clear temp date h i j country_list

save 'Data\OUTPUT\BCEI_Data' MAD_indiv_all CONS_indiv_all -append;

% % export to excel
% n = length(MAD_variables);
% for i = 1:n
%     MAD_indiv_struct(i).output = MAD_indiv_all{1,i};
% end
% AK_EXPORT_TO_XLSX(MAD_indiv_struct,'DATA\OUTPUT\AK_MAD_indiv_',{'output'},MAD_variables');
% clear MAD_indiv_struct
% for i = 1:n
%     CONS_indiv_struct(i).output = CONS_indiv_all{1,i};
% end
% AK_EXPORT_TO_XLSX(CONS_indiv_struct,'DATA\OUTPUT\AK_CONS_indiv_',{'output'},MAD_variables');
% clear n i CONS_indiv_struct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. get aggregate MAD factors (alternative proxies) time-series constructed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% options:
% 1 - mean
% 2 - std
% 3 - median (to make sure no effect of extreme country-specific disagreement)
% 4 - PC1
choice = 1;

% Get required XS sample
if filter_XS == 0
    country_list = {};
elseif filter_XS == 1
    country_list = setdiff(FORECAST_seas_adj(1,1).TOP(1,2:end),developed);
elseif filter_XS == 2
    country_list = setdiff(developed,setdiff(developed,FORECAST_seas_adj(1,1).TOP(1,2:end)));
elseif filter_XS == 10
    country_list = setdiff(FORECAST_seas_adj(1,1).TOP(1,2:end),G10);
end

DIS_AGGR_ALL = [];
CONS_AGGR_ALL = [];
PC1loadings = [];
corr4meas = {};
PC1explan = [];
for h = 1:length(MAD_indiv_all)
    
    for i = 1:length(country_list)
        MAD_indiv_all{1,h}(:,find(strcmp(country_list(i),MAD_indiv_all{1,h}(1,:)))) = [];
        CONS_indiv_all{1,h}(:,find(strcmp(country_list(i),CONS_indiv_all{1,h}(1,:)))) = [];        
    end
    
    data_temp_MAD = cell2mat(MAD_indiv_all{1,h}(2:end,2:end));
    data_temp_CONS = cell2mat(CONS_indiv_all{1,h}(2:end,2:end));
    country_names = MAD_indiv_all{1,h}(1,2:end)';
    
    %     % TEMP standardise disagreement before aggregating
    %     data_temp_MAD = (data_temp_MAD - ones(length(data_temp_MAD),1)*nanmean(data_temp_MAD,1)) ./ (ones(length(data_temp_MAD),1)*nanstd(data_temp_MAD,0,1));
    %     % AK_DESC_STATS(data_temp_MAD);
    
    DIS_MEAN = nanmean(data_temp_MAD,2);
    DIS_STD = nanstd(data_temp_MAD,0,2);
    DIS_MEDIAN = nanmedian(data_temp_MAD,2);
    
    if strcmp(MAD_variables{h},'CA')
        CONS_MEAN = nanmean(abs(data_temp_CONS),2);
        CONS_MEDIAN = nanmedian(abs(data_temp_CONS),2);
    else
        CONS_MEAN = nanmean(data_temp_CONS,2);
        CONS_MEDIAN = nanmedian(data_temp_CONS,2);
    end
    CONS_STD = nanstd(data_temp_CONS,0,2);
    
    %     % perform PCA with missing values
    %     MAD_variables(h)
    %     [a,b] = size(data_temp_MAD);
    %     country_names(find(sum(isnan(data_temp_MAD),1) > a/2)) % delete all columns which have more than half obs missing
    %     data_temp_MAD(:,find(sum(isnan(data_temp_MAD),1) > a/2)) = [];
    %     [a,b] = size(data_temp_MAD);
    %
    %     NaNvs999 = data_temp_MAD;
    %     for i = 1:b
    %         NaNvs999(find(isnan(data_temp_MAD(:,i))),i) = 999;
    %     end
    %     [check3, M] = BPCAfill(NaNvs999);
    %     estimatedNRMSE = BPCA_reestimation(M);
    %     estimatedNRMSE % quote from the original author's website: "If the estimated NRMSE (normalized root mean squared error) value is near 1.00, the original fill might also not be reliable because of noise in the original expression data and/or other reasons."
    %     % PCA analysis on individual MADs
    %     % isfinite(MAD_indiv)
    %     [loadings, pcs, pc_variances] = pca(check3);
    %     loadings
    %     PC1loadings(:,h) = loadings(:,1);
    %     % pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
    %     (pc_variances./sum(pc_variances) * 100)'
    %     PC1explan(:,h) = ans(1);
    %     cumsum(pc_variances./sum(pc_variances) * 100)'
    %     clear ans
    %     DIS_PC1 = pcs(:,1);
    %
    %     % Desc stats of aggregate MAD measures
    %     figure;
    %     plot(datenum(MAD_indiv_all{1,h}(2:end,1),'dd/mm/yy'),[DIS_MEAN DIS_STD DIS_MEDIAN DIS_PC1]);
    %     xlabel('time');
    %     ylabel('statistics');
    %     legend('XS mean', 'XS std', 'XS median', 'PC1','Location','SouthOutside');
    %     title(strcat('Aggregate MADs v1',{' '},MAD_indiv_all{1,h}(1,1)));
    %     datetick('x','yy');
    %     grid off
    %     corrcoef([DIS_MEAN DIS_STD DIS_MEDIAN DIS_PC1])
    %     corr4meas{h} = ans;
    %     % pause;
    %     if strcmp(robust_to_outliers,'no')
    %         saveas(gcf, char(strcat(cd_old,'\Figures\Aggregate MADs\', 'MAD_', MAD_variables(h),'.', ext)), ext); % gcf brings in the current figure handle
    %     else
    %         saveas(gcf, char(strcat(cd_old,'\Figures\Aggregate MADs\', 'MAD_', MAD_variables(h),'_outl_adj','.', ext)), ext); % gcf brings in the current figure handle
    %     end
    %     close;
    
    % clc
    if choice == 1
        DIS_AGGR_ALL = [DIS_AGGR_ALL, DIS_MEAN];
        CONS_AGGR_ALL = [CONS_AGGR_ALL, CONS_MEAN];
    elseif choice == 2
        DIS_AGGR_ALL = [DIS_AGGR_ALL, DIS_STD];
    elseif choice == 3
        DIS_AGGR_ALL = [DIS_AGGR_ALL, DIS_MEDIAN];
    elseif choice == 4
        DIS_AGGR_ALL = [DIS_AGGR_ALL, DIS_PC1];
    end
end
clear choice data_temp_MAD data_temp_CONS corr4meas PC1loadings PC1explan
MAD_aggr1_ts = fints(datenum(MAD_indiv_all{1,1}(2:end,1),'dd/mm/yy'), DIS_AGGR_ALL, MAD_variables', 'monthly');
CONS_aggr_ts = fints(datenum(CONS_indiv_all{1,1}(2:end,1),'dd/mm/yy'), CONS_AGGR_ALL, MAD_variables', 'monthly');

% incorporate assumed start date
start_date = busdate(datenum(issue_year,issue_month,gather_day+1),-1);
MAD_aggr1_ts = MAD_aggr1_ts(strcat(datestr(start_date,'mm/dd/yy'),'::',datestr(MAD_aggr1_ts.dates(end),'mm/dd/yy')));
CONS_aggr_ts = CONS_aggr_ts(strcat(datestr(start_date,'mm/dd/yy'),'::',datestr(CONS_aggr_ts.dates(end),'mm/dd/yy')));
if gather_rebalance == 12
    date_temp = 1:12:size(MAD_aggr1_ts,1);
    MAD_aggr1_ts = MAD_aggr1_ts(date_temp);
    CONS_aggr_ts = CONS_aggr_ts(date_temp);    
    clear date_temp
    % % the formula below doesn't work if first date has (business) day which is "unusually low" to the one at which data is to be requested
    % MAD_aggr1_ts = toannual(MAD_aggr1_ts,'ED',day(start_date),'EM',month(start_date),'CalcMethod','Exact','EndPtTol',[0,-1]);
end
clear start_date

% % Plot aggregate disagreement measures (for all macro variables) used in
% % subsequent analysis
% figure;
% plot(MAD_aggr1_ts);
% legend('Location','NorthEastOutside');
% datetick('x','yy');
% ylabel('aggregate MAD proxy1');
% xlabel('time');
% pause;
% if strcmp(robust_to_outliers,'no')
%     saveas(gcf, char(strcat(cd_old,'\Figures\Aggregate MADs\', 'MADs','.', ext)), ext); % gcf brings in the current figure handle
% else
%     saveas(gcf, char(strcat(cd_old,'\Figures\Aggregate MADs\', 'MADs_outl_adj','.', ext)), ext); % gcf brings in the current figure handle
% end
% close;
% % Plot aggregate consensus measures (for all macro variables) used in
% % subsequent analysis
% figure;
% plot(CONS_aggr_ts);
% legend('Location','NorthEastOutside');
% datetick('x','yy');
% ylabel('aggregate CONS proxy');
% xlabel('time');
% close;

% % visual analysis of annual (seasonal) pattern
% for j = 1:size(DIS_AGGR_ALL,2)
%     figure;
%     cc = hsv(length(year_vec));
%     % assuming first year is not full
%     m = month(MAD_aggr1_ts.dates(1));
%     plot(m:12,DIS_AGGR_ALL(1:12-m+1,j),'color',cc(1,:));
%     m = 12 - m + 2;
%     hold on
%     % assuming intermediary years are all filled
%     for i = 1:length(year_vec)-2
%         plot(1:12,DIS_AGGR_ALL(m:m+11,j),'color',cc(i+1,:));
%         m = m + 12;
%     end
%     % assuming last year is not full
%     m = month(MAD_aggr1_ts.dates(end));
%     plot(1:m,DIS_AGGR_ALL(end-m+1:end,j),'color',cc(1,:));
%     title(MAD_variables(j));
%     ylabel('aggregate MAD proxy1');
%     xlabel('month');
%     legend(num2str(year_vec'),'Location','NorthEastOutside');
%     hold off
%     pause;
%     close;
% end
% clear j m cc i
% for j = 1:size(CONS_AGGR_ALL,2)
%     figure;
%     cc = hsv(length(year_vec));
%     % assuming first year is not full
%     m = month(CONS_aggr_ts.dates(1));
%     plot(m:12,CONS_AGGR_ALL(1:12-m+1,j),'color',cc(1,:));
%     m = 12 - m + 2;
%     hold on
%     % assuming intermediary years are all filled
%     for i = 1:length(year_vec)-2
%         plot(1:12,CONS_AGGR_ALL(m:m+11,j),'color',cc(i+1,:));
%         m = m + 12;
%     end
%     % assuming last year is not full
%     m = month(CONS_aggr_ts.dates(end));
%     plot(1:m,CONS_AGGR_ALL(end-m+1:end,j),'color',cc(1,:));
%     title(MAD_variables(j));    
%     ylabel('aggregate CONS proxy');
%     xlabel('month');
%     legend(num2str(year_vec'),'Location','NorthEastOutside');
%     hold off
%     pause;
%     close;
% end
% clear j m cc i 

clear DIS_AGGR_ALL CONS_AGGR_ALL
% % Construct aggregate MAD factor v2
% % (using all currencies which have whole time series, note: consider incl
% % Germany;
% % Since data for one month is missing remove it
% D = MAD;
% country_names = FORECAST_TOP(1,2:end);
% D(all(isnan(D),2),:) = [];
% country_names(:,any(isnan(D),1)) = [];
% D(:,any(isnan(D),1)) = [];
% MAD_aggr2_ts = fints(dcommon_star, mean(D,2), 'Aggregate_MAD_v2', 'monthly');
clear i h FORECAST_STD FORECAST_MEAN country_list

% Descriptive stats
output = AK_DESC_STATS(MAD_aggr1_ts,'AC_lags',[1,3,12],'prctiles',[5,95]);
Desc_stats_MAD = output.summary;
Desc_stats_MAD{1,1} = 'MAD_aggr';
output = AK_DESC_STATS(CONS_aggr_ts,'AC_lags',[1,3,12],'prctiles',[5,95]);
Desc_stats_CONS = output.summary;
Desc_stats_CONS{1,1} = 'CONS_aggr';
clear output

% PCA analysis on aggregate MADs
% isfinite(MAD_indiv)
[loadings, pcs, pc_variances] = pca(fts2mat(MAD_aggr1_ts));
loadings
% pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
(pc_variances./sum(pc_variances) * 100)'
cumsum(pc_variances./sum(pc_variances) * 100)'
MAD_dev_PC1 = fints(MAD_aggr1_ts.dates,fts2mat(MAD_aggr1_ts) - pcs(:,1)*loadings(:,1)',MAD_variables,'monthly');
MAD_aggr1_PC1 = fints(MAD_aggr1_ts.dates, pcs(:,1), 'MAD_aggr1_PC1', 'monthly');
MAD_aggr1_ts = [MAD_aggr1_ts MAD_aggr1_PC1];
delete MAD_factors.mat
save 'Data\OUTPUT\MAD_factors' MAD_aggr1_ts
clear ans loadings pc_variances pcs

% PCA analysis on aggregate CONSs
[loadings, pcs, pc_variances] = pca(fts2mat(CONS_aggr_ts));
loadings
% pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
(pc_variances./sum(pc_variances) * 100)'
cumsum(pc_variances./sum(pc_variances) * 100)'
MAD_dev_PC1 = fints(CONS_aggr_ts.dates,fts2mat(CONS_aggr_ts) - pcs(:,1)*loadings(:,1)',MAD_variables,'monthly');
CONS_aggr_PC1 = fints(CONS_aggr_ts.dates, pcs(:,1), 'CONS_aggr_PC1', 'monthly');
CONS_aggr_ts = [CONS_aggr_ts CONS_aggr_PC1];
delete MAD_factors.mat
save 'Data\OUTPUT\MAD_factors' CONS_aggr_ts -append;
clear ans loadings pc_variances pcs
 
% construct innovations to aggregate MAD
MAD_innovations = [];
fld_names = fieldnames(MAD_aggr1_ts);
for i = 4:length(fld_names)
    regressors = ones(size(MAD_aggr1_ts.(fld_names{i}),1)-lag_for_innovations,1);
    for j = 1:lag_for_innovations
        regressors = [regressors fts2mat(MAD_aggr1_ts.(fld_names{i})(j:end-lag_for_innovations+j-1))];
    end
    MAD_innovations_indiv = fts2mat(MAD_aggr1_ts.(fld_names{i})(j+1:end)) - regressors*(regressors \ fts2mat(MAD_aggr1_ts.(fld_names{i})(j+1:end)));
    MAD_innovations = [MAD_innovations, MAD_innovations_indiv];
end
MAD_aggr1_innovations = fints(MAD_aggr1_ts.dates(1+lag_for_innovations:end),MAD_innovations,fld_names(4:end)','monthly');
fld_names = {'MAD_aggr1_PC1'};
for i = 1:length(fld_names)
    MAD_aggr1_innovations = rmfield(MAD_aggr1_innovations,fld_names(i));
end
clear i j regressors fld_names
% construct innovations to aggregate CONS
lag_for_innovations = lag_for_innovations + 1;
CONS_innovations = [];
fld_names = fieldnames(CONS_aggr_ts);
for i = 4:length(fld_names)
    regressors = ones(size(CONS_aggr_ts.(fld_names{i}),1)-lag_for_innovations,1);
    for j = 1:lag_for_innovations
        regressors = [regressors fts2mat(CONS_aggr_ts.(fld_names{i})(j:end-lag_for_innovations+j-1))];
    end
    CONS_innovations_indiv = fts2mat(CONS_aggr_ts.(fld_names{i})(j+1:end)) - regressors*(regressors \ fts2mat(CONS_aggr_ts.(fld_names{i})(j+1:end)));
    CONS_innovations = [CONS_innovations, CONS_innovations_indiv];
end
CONS_aggr_innovations = fints(CONS_aggr_ts.dates(1+lag_for_innovations:end),CONS_innovations,fld_names(4:end)','monthly');
fld_names = {'CONS_aggr_PC1'};
for i = 1:length(fld_names)
    CONS_aggr_innovations = rmfield(CONS_aggr_innovations,fld_names(i));
end
clear i j regressors fld_names

% create orthogonalised component MAD_aggr1_innovations_orth
MAD_aggr1_innovations_orth = AK_ORTHOGONALISE(MAD_aggr1_innovations,FXdVOLts);
% create orthogonalised component FXdVOLts_orth
FXdVOLts_orth = AK_ORTHOGONALISE(FXdVOLts,MAD_aggr1_innovations.('CA'));
% create winsorised MAD_aggr1_innovations with upper bound 95%
MAD_aggr1_innovations_wins = AK_WINSORISE(MAD_aggr1_innovations,0,0.95);
% for i = 1:length(MAD_variables)
%     figure;
%     plot(MAD_aggr1_innovations.(MAD_variables(i)),'b');
%     hold on
%     plot(MAD_aggr1_innovations_wins.(MAD_variables(i)),'r');
%     hold off
%     datetick('x','yy');
%     ylabel('aggregate MAD proxy1');
%     xlabel('time');
%     pause;
%     close;
% end

% figure;
% plot(MAD_aggr1_innovations);
% legend('Location','NorthEastOutside');
% datetick('x','yy');
% ylabel('aggregate MAD proxy1');
% xlabel('time');
% pause;
% saveas(gcf, char(strcat(cd_old,'\Figures\Aggregate MADs\MAD_shocks\', 'MAD_shocks','.', ext)), ext); % gcf brings in the current figure handle
% close;

% Descriptive stats
output = AK_DESC_STATS(MAD_aggr1_innovations);
Desc_stats_dMAD = output.summary;
Desc_stats_dMAD{1,1} = 'MAD_innovations';
Desc_stats_dMAD
clear output

output = AK_DESC_STATS(CONS_aggr_innovations);
Desc_stats_dCONS = output.summary;
Desc_stats_dCONS{1,1} = 'CONS_innovations';
Desc_stats_dCONS
clear output

% PCA analysis on aggregate MADs innovations
[loadings, pcs, pc_variances] = pca(fts2mat(MAD_aggr1_innovations));
loadings
% pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
(pc_variances./sum(pc_variances) * 100)'
cumsum(pc_variances./sum(pc_variances) * 100)'
% dMAD_PC = fints(MAD_aggr1_innovations.dates,pcs,{'PC1','PC2','PC3'},'monthly');
dMAD_dev_PC1 = fints(MAD_aggr1_innovations.dates,fts2mat(MAD_aggr1_innovations) - pcs(:,1)*loadings(:,1)',MAD_variables,'monthly');
dMAD_pc1_ts = fints(MAD_aggr1_innovations.dates,pcs(:,1),'dMAD_pc1_ts','monthly');
% AK_DESC_STATS(dMAD_pc1_ts)
clear loadings pc_variances pcs

% PCA analysis on aggregate CONSs innovations
[loadings, pcs, pc_variances] = pca(fts2mat(CONS_aggr_innovations));
loadings
% pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
(pc_variances./sum(pc_variances) * 100)'
cumsum(pc_variances./sum(pc_variances) * 100)'
% dMAD_PC = fints(MAD_aggr1_innovations.dates,pcs,{'PC1','PC2','PC3'},'monthly');
dCONS_dev_PC1 = fints(CONS_aggr_innovations.dates,fts2mat(CONS_aggr_innovations) - pcs(:,1)*loadings(:,1)',MAD_variables,'monthly');
dCONS_pc1_ts = fints(CONS_aggr_innovations.dates,pcs(:,1),'dCONS_pc1_ts','monthly');
% AK_DESC_STATS(dCONS_pc1_ts)
clear loadings pc_variances pcs

% TEMP
temp = fts2mat(MAD_aggr1_innovations);
temp = temp ./ (ones(length(MAD_aggr1_innovations.dates),1)*std(temp,1,1));
dMAD_avg = fints(MAD_aggr1_innovations.dates,mean(temp,2),'dMAD_avg','monthly');
output = AK_DESC_STATS(dMAD_avg);
output.summary
clear temp output

dMADorth = [];
for i = 1:length(MAD_variables)
    dMADtemp1 = MAD_aggr1_innovations.(MAD_variables(i));
    dMADtemp2 = MAD_aggr1_innovations;
    dMADtemp2 = rmfield(dMADtemp2,MAD_variables(i));
    dMADorth = [dMADorth fts2mat(AK_ORTHOGONALISE(dMADtemp1,dMADtemp2))];
end
dMADorth = fints(MAD_aggr1_innovations.dates,dMADorth,MAD_variables,'monthly');
% output = AK_DESC_STATS([dMADorth MAD_aggr1_innovations]);
clear i dMADtemp1 dMADtemp2

% PCA analysis on aggregate MADs innovations (filtered MAD_variables only)
fld_names = {'FX', 'IR'}; % not to incorporate
MAD_aggr1_innovations_filter = MAD_aggr1_innovations;
for i = 1:length(fld_names)
    MAD_aggr1_innovations_filter = rmfield(MAD_aggr1_innovations_filter,fld_names(i));
end
clear i
variables_filter = fieldnames(MAD_aggr1_innovations_filter);
variables_filter = variables_filter(4:end);
[loadings, pcs, pc_variances] = pca(fts2mat(MAD_aggr1_innovations_filter));
loadings
% pcs(:,1) \ fts2mat(MAD_aggr1_ts) % just to check that loadings on PC1 are exactly the projection coefficients
(pc_variances./sum(pc_variances) * 100)'
cumsum(pc_variances./sum(pc_variances) * 100)'
% dMAD_PC = fints(MAD_aggr1_innovations.dates,pcs,{'PC1','PC2','PC3'},'monthly');
dMAD_dev_PC1_filter = fints(MAD_aggr1_innovations_filter.dates,fts2mat(MAD_aggr1_innovations_filter) - pcs(:,1)*loadings(:,1)',variables_filter,'monthly');
dMAD_pc1_ts_filter = fints(MAD_aggr1_innovations_filter.dates,pcs(:,1),'dMAD_pc1_ts_filter','monthly');
clear loadings pc_variances pcs variables_filter

MAD_aggr1_innovations = [MAD_aggr1_innovations, dMAD_pc1_ts];
MAD_aggr1_innovations_filter = [MAD_aggr1_innovations_filter, dMAD_pc1_ts_filter];
CONS_aggr_innovations = [CONS_aggr_innovations, dCONS_pc1_ts];

clear dMAD_pc1_ts dMAD_pc1_ts_filter ans
save 'Data\OUTPUT\MAD_factors' MAD_aggr1_innovations CONS_aggr_innovations dMAD_dev_PC1 dCONS_dev_PC1 MAD_aggr1_innovations_filter dMAD_dev_PC1_filter -append

% % export to excel
% AK_EXPORT_TO_XLSX(MAD_aggr1_ts,'DATA\OUTPUT\AK_MAD_aggregate_');
% AK_EXPORT_TO_XLSX(MAD_aggr1_innovations,'DATA\OUTPUT\AK_MAD_innovations_');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Descriptive stats (MAD vs. VOL, MAD vs. HML, etc.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % % Initiate structure once
% % Comparison = struct('VOL_MAD',[],'dVOL_MAD',[],'dVOL_dMAD',[],'lMAD_VOL',[],'ldMAD_dVOL',[],'HML_MAD',[],'HML_dMAD',[],'HML_lMAD',[],'HML_ldMAD',[],'HML_dMAD_dev_PC1',[],'RX_MAD',[],'RX_dMAD',[],'RX_lMAD',[],'RX_ldMAD',[],'lambda',[],'SE_lambda',[]);
%
% % Correlations VOL vs. MAD (both levels)
% fprintf('Correlations VOL vs. MAD (both levels)\n')
% dcommon = intersect(MAD_aggr1_ts.dates,FXaggrVOL_monthly_ts.dates);
% output = AK_DESC_STATS([FXaggrVOL_monthly_ts(datestr(dcommon)) MAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.VOL_MAD(1+gather_day,:) = corr;
% clear ans
%
% % Correlations dVOL vs. MAD
% fprintf('Correlations dVOL vs. MAD\n')
% dcommon = intersect(MAD_aggr1_ts.dates,FXdVOLts.dates);
% output = AK_DESC_STATS([FXdVOLts(datestr(dcommon)) MAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.dVOL_MAD(1+gather_day,:) = corr;
% clear ans
%
% % Correlations dVOL vs. dMAD
% fprintf('Correlations dVOL vs. dMAD\n')
% dcommon = intersect(MAD_aggr1_innovations.dates,FXdVOLts.dates);
% output = AK_DESC_STATS([FXdVOLts(datestr(dcommon)) MAD_aggr1_innovations(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.dVOL_dMAD(1+gather_day,:) = corr;
% clear ans
%
% % lMAD vs. VOL
% lMAD_aggr1_ts = lagts(MAD_aggr1_ts,1,NaN);
% lMAD_aggr1_ts = lMAD_aggr1_ts(2:end);
% fprintf('Correlations VOL vs. lMAD (both levels)\n')
% dcommon = intersect(lMAD_aggr1_ts.dates,FXaggrVOL_monthly_ts.dates);
% output = AK_DESC_STATS([FXaggrVOL_monthly_ts(datestr(dcommon)) lMAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.lMAD_VOL(1+gather_day,:) = corr;
% clear ans
%
% % ldMAD vs. dVOL
% ldMAD_ts = lagts(MAD_aggr1_innovations,1,NaN);
% ldMAD_ts = ldMAD_ts(2:end);
% fprintf('Correlations dVOL vs. dlMAD\n')
% dcommon = intersect(ldMAD_ts.dates,FXaggrVOL_monthly_ts.dates);
% output = AK_DESC_STATS([FXaggrVOL_monthly_ts(datestr(dcommon)) ldMAD_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.ldMAD_dVOL(1+gather_day,:) = corr;
% clear ans
%
% % HML vs. MAD
% fprintf('Correlations HML vs. MAD\n')
% dcommon = intersect(MAD_aggr1_ts.dates,hmlFXcarryNETts.dates);
% output = AK_DESC_STATS([hmlFXcarryNETts(datestr(dcommon)) MAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.HML_MAD(1+gather_day,:) = corr;
% % % plotting correlation of MAD vs HML
% % periods = 6; % rolling window in months
% % dcommon = intersect(MAD_aggr1_ts.dates,hmlFXcarryNETts.dates);
% % MAD_temp = MAD_aggr1_ts(datestr(dcommon));
% % HML_temp = hmlFXcarryNETts(datestr(dcommon));
% % flds = fieldnames(MAD_temp);
% % flds = flds(4:end-1);
% % figure;
% % for h = 1:length(flds)
% %     for i = periods:length(HML_temp)
% %         [R, PVAL] = corrcoef(MAD_temp(i-periods+1:i).(flds(h)),HML_temp(i-periods+1:i));
% %         correl(1,i-periods+1) = R(1,2);
% %     end
% %     subplot(length(flds),1,h)
% %     plot(HML_temp.dates(periods:end),correl);
% %     %     % NBER recessions: http://www.nber.org/cycles.html
% %     %     Recessions = [ datenum('15-May-1937'), datenum('15-Jun-1938');
% %     %         datenum('15-Feb-1945'), datenum('15-Oct-1945');
% %     %         datenum('15-Nov-1948'), datenum('15-Oct-1949');
% %     %         datenum('15-Jul-1953'), datenum('15-May-1954');
% %     %         datenum('15-Aug-1957'), datenum('15-Apr-1958');
% %     %         datenum('15-Apr-1960'), datenum('15-Feb-1961');
% %     %         datenum('15-Dec-1969'), datenum('15-Nov-1970');
% %     %         datenum('15-Nov-1973'), datenum('15-Mar-1975');
% %     %         datenum('15-Jan-1980'), datenum('15-Jul-1980');
% %     %         datenum('15-Jul-1981'), datenum('15-Nov-1982');
% %     %         datenum('15-Jul-1990'), datenum('15-Mar-1991');
% %     %         datenum('15-Mar-2001'), datenum('15-Nov-2001');
% %     %         datenum('15-Dec-2007'), datenum('15-Jun-2009') ];
% %     %     Recessions = busdate(Recessions);
% %     %
% %     %     Example_RecessionPlot(HML_temp.dates(periods:end), Recessions);
% %     xlabel('time');
% %     ylabel('Correlation');
% %     % legend('CONSENSUS', 'Bottom 3 Avg.','Top 3 Avg.');
% %     title(flds{h});
% %     datetick('x','yy','keepticks');
% % end
% % clear periods flds correl
%
% % Correlations HML vs. dMAD
% fprintf('Correlations HML vs. dMAD\n')
% dcommon = intersect(hmlFXcarryNETts.dates,MAD_aggr1_innovations.dates);
% output = AK_DESC_STATS([hmlFXcarryNETts(datestr(dcommon)) MAD_aggr1_innovations(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.HML_dMAD(1+gather_day,:) = corr;
% % figure;
% % for h = 4:length(fld_names)
% %     % plotting correlations
% %     periods = 12; % rolling window in months
% %     MAD_temp = MAD_aggr1_innovations(datestr(dcommon)).(fld_names(h));
% %     HML_temp = hmlFXcarryNETts(datestr(dcommon));
% %     VOL_temp = FXdVOLts(datestr(dcommon));
% %     for i = periods:length(HML_temp)
% %         [R, PVAL] = corrcoef(MAD_temp(i-periods+1:i),HML_temp(i-periods+1:i));
% %         correl_HML(1,i-periods+1) = -R(1,2);
% %         [R, PVAL] = corrcoef(VOL_temp(i-periods+1:i),HML_temp(i-periods+1:i));
% %         correl_VOL(1,i-periods+1) = -R(1,2);
% %     end
% %     subplot(length(fld_names(4:end)),1,h-3)
% %     plot(HML_temp.dates(periods:end),correl_HML,'b');
% %     hold on
% %     plot(HML_temp.dates(periods:end),correl_VOL,'r');
% %     legend('dMAD vs. HML', 'VOL vs. HML','Location','NorthEastOutside');
% %     xlabel('time');
% %     ylabel('Rolling correlations');
% %     % title(MAD_variables{h});
% %     datetick('x','yy','keepticks');
% %     [R, PVAL] = corrcoef(MAD_temp,HML_temp);
% %     correl_unc_HML = -R(1,2)
% %     [R, PVAL] = corrcoef(MAD_temp,VOL_temp);
% %     correl_unc_VOL = -R(1,2)
% %     [R, PVAL] = corrcoef(HML_temp,VOL_temp);
% %     -R(1,2)
% % end
% clear ans
%
% % lMAD vs. HML
% fprintf('Correlations HML vs. lMAD\n')
% dcommon = intersect(lMAD_aggr1_ts.dates,hmlFXcarryNETts.dates);
% output = AK_DESC_STATS([hmlFXcarryNETts(datestr(dcommon)) lMAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.HML_lMAD(1+gather_day,:) = corr;
% clear ans
%
% % ldMAD vs. HML
% ldMAD_ts = lagts(MAD_aggr1_innovations,1,NaN);
% ldMAD_ts = ldMAD_ts(2:end);
% fprintf('Correlations HML vs. dlMAD\n')
% dcommon = intersect(ldMAD_ts.dates,hmlFXcarryNETts.dates);
% output = AK_DESC_STATS([hmlFXcarryNETts(datestr(dcommon)) ldMAD_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.HML_ldMAD(1+gather_day,:) = corr;
% clear ans
%
% % Correlations HML vs. dMAD_dev_PC1
% fprintf('Correlations HML vs. dMAD_dev_PC1\n')
% dcommon = intersect(dMAD_dev_PC1.dates,hmlFXcarryNETts.dates);
% output = AK_DESC_STATS([hmlFXcarryNETts(datestr(dcommon)) dMAD_dev_PC1(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.HML_dMAD_dev_PC1(1+gather_day,:) = corr;
%
% % Correlations RX vs. MAD (both levels)
% fprintf('Correlations RX vs. MAD (both levels)\n')
% dcommon = intersect(MAD_aggr1_ts.dates,rxFXcarryNETts.dates);
% output = AK_DESC_STATS([rxFXcarryNETts(datestr(dcommon)) MAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.RX_MAD(1+gather_day,:) = corr;
%
% % Correlations RX vs. dMAD
% fprintf('Correlations rxFXcarryNETts vs. dMAD\n')
% dcommon = intersect(MAD_aggr1_innovations.dates,rxFXcarryNETts.dates);
% output = AK_DESC_STATS([rxFXcarryNETts(datestr(dcommon)) MAD_aggr1_innovations(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.RX_dMAD(1+gather_day,:) = corr;
%
% % lMAD vs. RX
% fprintf('Correlations RX vs. lMAD (both levels)\n')
% dcommon = intersect(lMAD_aggr1_ts.dates,rxFXcarryNETts.dates);
% output = AK_DESC_STATS([rxFXcarryNETts(datestr(dcommon)) lMAD_aggr1_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.RX_lMAD(1+gather_day,:) = corr;
% clear ans
%
% % ldMAD vs. RX
% fprintf('Correlations rxFXcarryNETts vs. dlMAD (both levels)\n')
% dcommon = intersect(ldMAD_ts.dates,rxFXcarryNETts.dates);
% output = AK_DESC_STATS([rxFXcarryNETts(datestr(dcommon)) ldMAD_ts(datestr(dcommon))]);
% corr = output.nancorr(2:end,1)'
% Comparison.RX_ldMAD(1+gather_day,:) = corr;
% clear ans
%
% % delete 'Data\OUTPUT\Comparison.mat'
% % save 'Data\OUTPUT\Comparison' Comparison

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. Tradable factor construction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % construct simple first difference
% dMAD_indiv_all_simple = {};
% for h = 1:length(MAD_indiv_all)
%     dMAD_indiv_simple = (cell2mat(MAD_indiv_all{1,h}(3:end,2:end)) - cell2mat(MAD_indiv_all{1,h}(2:end-1,2:end))) ./ cell2mat(MAD_indiv_all{1,h}(2:end-1,2:end));
%     dMAD_indiv_simple_cell = [...
%         MAD_indiv_all{1,h}(1,:);...
%         MAD_indiv_all{1,h}(3:end,1) mat2cell(dMAD_indiv_simple,ones(size(dMAD_indiv_simple,1),1),ones(1,size(dMAD_indiv_simple,2)))];
%     dMAD_indiv_all_simple = [dMAD_indiv_all_simple, {dMAD_indiv_simple_cell}];
% end
%
% %%%%%%%%%%%%%%%%%%%%
% % a) Long-short idea
% %%%%%%%%%%%%%%%%%%%%
%
% % plotting correlations of MAD_HML vs HML
% for h = 1:length(MAD_variables)
%     % rolling correlations
%     periods = 6; % rolling window in months
%     dcommon = intersect(hmlFXcarryNETts.dates,hmlFXmadNET.(MAD_variables{h}).dates);
%     MAD_temp = hmlFXmadNET.(MAD_variables{h})(datestr(dcommon));
%     HML_temp = hmlFXcarryNETts(datestr(dcommon));
%     VOL_temp = FXdVOLts(datestr(dcommon));
%     for i = periods:length(HML_temp)
%         [R, PVAL] = corrcoef(MAD_temp(i-periods+1:i),HML_temp(i-periods+1:i));
%         correl_HML(1,i-periods+1) = R(1,2);
%         [R, PVAL] = corrcoef(VOL_temp(i-periods+1:i),HML_temp(i-periods+1:i));
%         correl_VOL(1,i-periods+1) = -R(1,2);
%     end
%     subplot(length(MAD_variables),1,h)
%     plot(HML_temp.dates(periods:end),correl_HML,'b');
%     hold on
%     plot(HML_temp.dates(periods:end),correl_VOL,'r');
%     legend('MAD vs. HML', 'VOL vs. HML','Location','NorthEastOutside');
%     xlabel('time');
%     ylabel('Rolling correlations');
%     title(MAD_variables{h});
%     datetick('x','yy','keepticks');
%     % unconditional correlations
%     [R, PVAL] = corrcoef(MAD_temp,HML_temp);
%     correl_unc_HML(h,1) = R(1,2);
%     [R, PVAL] = corrcoef(MAD_temp,VOL_temp);
%     correl_unc_VOL(h,1) = -R(1,2);
%     clear portf_names R PVAL i
% end
% clear correl_HML correl_VOL
% correl_unc_HML'
% correl_unc_VOL'
% [R, PVAL] = corrcoef(HML_temp,VOL_temp);
% -R(1,2)
%
% % AK_EXPORT_TO_XLSX(Desc_MAD_net,'DATA\OUTPUT\Desc_HML_MAD_',{MAD_variables,{'Output'}});
%
% %%%%%%%%%%%%%%%%%%%%
% % b) Factor-mimmick a-la Menkhoff et al. (2011)
% %%%%%%%%%%%%%%%%%%%%
%
% fprintf('MAD_aggr1_innovations mimmick:\n')
% MAD_mimmick_all = [];
% for i = 1:length(MAD_variables)
%     MAD = MAD_aggr1_innovations.(MAD_variables(i));
%     dcommon = intersect(assetsFXcarryNETts.dates,MAD.dates); % MAD_aggr1_ts.dates and
%     MAD_trunc = MAD(datestr(dcommon));
%     portf_ret = 100*fts2mat(assetsFXcarryNETts(datestr(dcommon)));
%     % scale coefficients below a-la Menkhoff (2011)
%     b = 0.1*[ones(size(dcommon,1),1) portf_ret] \ fts2mat(MAD_trunc);
%     MAD_mimmick = portf_ret*b(2:end);
%     % MAD_mimmick = portf_ret(:,[1 end])*b([2 end]);
%     b(2:end)'
%     mean(MAD_mimmick)*12
%     R = corrcoef(MAD_mimmick,fts2mat(hmlFXcarryNETts(datestr(dcommon))));
%     R(1,2)
%     MAD_mimmick_all = [MAD_mimmick_all, MAD_mimmick];
% end
% dMAD_mimmick_ts = fints(dcommon,MAD_mimmick_all,MAD_variables,'monthly');
% clear i b MAD dcommon MAD_mimmick MAD_mimmick_all MAD_trunc R ans
%
% fprintf('dMAD_pc1_ts mimmick:\n')
% MAD = MAD_aggr1_innovations.('dMAD_pc1_ts');
% dcommon = intersect(assetsFXcarryNETts.dates,MAD.dates); % MAD_aggr1_ts.dates and
% MAD_trunc = MAD(datestr(dcommon));
% portf_ret = 100*fts2mat(assetsFXcarryNETts(datestr(dcommon)));
% % scale coefficients below a-la Menkhoff (2011)
% b = 0.1*[ones(size(dcommon,1),1) portf_ret] \ fts2mat(MAD_trunc);
% MAD_mimmick = portf_ret*b(2:end);
% % MAD_mimmick = portf_ret(:,[1 end])*b([2 end]);
% b(2:end)'
% mean(MAD_mimmick)*12
% R = corrcoef(MAD_mimmick,fts2mat(hmlFXcarryNETts(datestr(dcommon))));
% R(1,2)
% dMAD_pc1_mimmick_ts = fints(dcommon,MAD_mimmick,'PC1','monthly');
% dMAD_mimmick_ts = [dMAD_mimmick_ts dMAD_pc1_mimmick_ts];
% clear b MAD dcommon MAD_mimmick MAD_trunc R ans
%
% fprintf('dMAD_dev_PC1 mimmick:\n')
% MAD_mimmick_all = [];
% for i = 1:length(MAD_variables)
%     MAD = dMAD_dev_PC1.(MAD_variables(i));
%     dcommon = intersect(rxFXcarryNETts.dates,MAD.dates); % MAD_aggr1_ts.dates and
%     MAD_trunc = MAD(datestr(dcommon));
%     portf_ret_net_level = 100*fts2mat(assetsFXcarryNETts(datestr(dcommon)));
%     % scale coefficients below a-la Menkhoff (2011)
%     b = 0.1*[ones(size(dcommon,1),1) portf_ret_net_level] \ fts2mat(MAD_trunc);
%     MAD_mimmick = portf_ret_net_level*b(2:end);
%     % MAD_mimmick = portf_ret_net_level(:,[1 end])*b([2 end]);
%     b(2:end)'
%     mean(MAD_mimmick)*12
%     R = corrcoef(MAD_mimmick,fts2mat(hmlFXcarryNETts(datestr(dcommon))));
%     R(1,2)
%     MAD_mimmick_all = [MAD_mimmick_all, MAD_mimmick];
% end
% dMAD_dev_PC1_mimmick_ts = fints(dcommon,MAD_mimmick_all,MAD_variables,'monthly');
% clear i b MAD dcommon MAD_mimmick MAD_mimmick_all MAD_trunc R ans
%
% % create orthogonalised component dMAD_mimmick_orth wp FXdVOL_mimmick_ts
% dMAD_mimmick_orth = AK_ORTHOGONALISE(dMAD_mimmick_ts,FXdVOL_mimmick_ts);
% % create orthogonalised component FXdVOL_mimmick_orth
% FXdVOL_mimmick_orth = AK_ORTHOGONALISE(FXdVOL_mimmick_ts,dMAD_mimmick_ts.('CA'));
% % create orthogonalised component dMAD_mimmick_orth wp hmlFXcarryNETts
% dMAD_mimmick_orthHML = AK_ORTHOGONALISE(dMAD_mimmick_ts,hmlFXcarryNETts);
% % create orthogonalised component hmlFXcarryNETts
% hmlFXcarryNETts_orth = AK_ORTHOGONALISE(hmlFXcarryNETts,dMAD_mimmick_ts.('CA'));
%
% save 'Data\OUTPUT\MAD_portfolios' dMAD_mimmick_ts dMAD_dev_PC1_mimmick_ts dMAD_mimmick_orth FXdVOL_mimmick_orth dMAD_mimmick_orthHML hmlFXcarryNETts_orth

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Construction of macro fundamentals-related factor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rolling_window = 5;
% var_numb_store = [1 2 3 4 5]; % choose how many variables (max 5) to pick to form a "blend" one point at a time
% contemp_vs_lag_store = {'contemp' 'lag'}; % if 'lag' then 1) at t: pick variable 2) at t+1: take realisation of the picked variable; if 'contemp' then everything is done at t
% low_vs_high_store = {'low' 'high'}; % pick variable based on high or low value of the signal
% cdf_vs_sort_store = {'cdf' 'sort'}; % method to construct a signal based on sorting or cdf
% fx_store = {'yes' 'no'}; % if 'cdf' option above is chosen then choose if fx to be incl. (by default it's not included in the 'sort' option)
% % option for signal:
% % 1 - MAD_aggr1_ts
% % 2 - MAD_dispersion_ts
% % 3 - MAD_dev_PC1
% signal_opt_store = [1 2 3];
% % option for variable to track:
% % 1 - hmlFXmadNETts
% % 2 - MAD_aggr1_ts
% % 3 - MAD_dev_PC1
% track_opt_store = [1 2 3];
%
% for a=1:length(var_numb_store)
%     for b=1:length(contemp_vs_lag_store)
%         for c=1:length(low_vs_high_store)
%             for d=1:length(cdf_vs_sort_store)
%                 for e=1:length(fx_store)
%                     for f=1:length(signal_opt_store)
%                         for g=1:length(track_opt_store)
%
%                             var_numb = var_numb_store(a); % choose how many variables (max 5) to pick to form a "blend" one point at a time
%                             contemp_vs_lag = cell2mat(contemp_vs_lag_store(b)); % if 'lag' then 1) at t: pick variable 2) at t+1: take realisation of the picked variable; if 'contemp' then everything is done at t
%                             low_vs_high = cell2mat(low_vs_high_store(c)); % pick variable based on high or low value of the signal
%                             cdf_vs_sort = cell2mat(cdf_vs_sort_store(d)); % method to construct a signal based on sorting or cdf
%                             fx = cell2mat(fx_store(e)); % if 'cdf' option above is chosen then choose if fx to be incl. (by default it's not included in the 'sort' option)
%                             % option for signal:
%                             % 1 - MAD_aggr1_ts
%                             % 2 - MAD_dispersion_ts
%                             % 3 - MAD_dev_PC1
%                             signal_opt = signal_opt_store(f);
%                             % option for variable to track:
%                             % 1 - hmlFXmadNETts
%                             % 2 - MAD_aggr1_ts
%                             % 3 - MAD_dev_PC1
%                             track_opt = track_opt_store(g);
%
%                             if signal_opt == 1
%                                 signal = MAD_aggr1_ts;
%                             elseif signal_opt == 2
%                                 buckets = 3; % divides the individual MADs into buckets and as a dispersion takes the absolute difference between the first and the last bucket
%                                 for h = 1:length(MAD_variables)
%                                     MAD = cell2mat(MAD_indiv_all{1,h}(2:end,2:end));
%                                     for i = 1:(size(MAD,1))
%                                         % sort into buckets
%                                         [values, indexes] = sort(MAD(i,:));
%                                         fin_val = sum(~isnan(MAD(i,:)));
%                                         numb_forc = [];
%                                         mean_MAD = [];
%                                         start_index = 1;
%                                         for j = 1:buckets
%                                             % determine number of currencies in each portfolio
%                                             numb_forc = [numb_forc,round(j * fin_val / buckets) - round((j-1) * fin_val / buckets)];
%                                             % calculate time series of mean MAD for each bucket
%                                             finish_index = start_index + numb_forc(j) - 1;
%                                             held(j) = {indexes(start_index:finish_index)};
%                                             mean_MAD = [mean_MAD, mean(MAD(i,[held{j}]))];
%                                             start_index = finish_index + 1;
%                                         end
%                                         MAD_dispersion(i,h) = mean_MAD(end) - mean_MAD(1);
%                                     end
%                                 end
%                                 MAD_dispersion_ts = fints(datenum(MAD_indiv_all{1,h}(2:end,1),'dd/mm/yy'),MAD_dispersion,MAD_variables','monthly');
%                                 clear MAD MAD_dispersion buckets fin_val finish_index h held i indexes j mean_MAD numb_forc
%                                 signal = MAD_dispersion_ts;
%                             elseif signal_opt == 3
%                                 signal = MAD_dev_PC1;
%                             end
%                             if strcmp(cdf_vs_sort,'cdf')
%                                 signal_mat = fts2mat(signal);
%                                 signal_new_mat = [];
%                                 for h=1:size(signal_mat,2)
%                                     signal_new_mat = [signal_new_mat, ksdensity(signal_mat(:,h),signal_mat(:,h),'function','cdf')];
%                                 end
%                                 fldnames = fieldnames(signal);
%                                 signal = fints(signal.dates,signal_new_mat,fldnames(4:end)','monthly');
%                                 if strcmp(fx,'yes')
%                                     field_list = {'MAD_aggr1_PC1'};
%                                 elseif strcmp(fx,'no')
%                                     field_list = {'FX' 'MAD_aggr1_PC1'};
%                                 end
%                             else
%                                 field_list = {'FX' 'MAD_aggr1_PC1'};
%                             end
%                             if var_numb >= length(MAD_variables) && length(field_list) > 1
%                                 var_numb = length(MAD_variables) - length(field_list) + 1;
%                             end
%                             for i=1:length(field_list)
%                                 if any(strcmp(field_list(i),fieldnames(signal)))
%                                     signal = rmfield(signal,field_list(i));
%                                 end
%                             end
%                             if strcmp(contemp_vs_lag,'lag')
%                                 signal = lagts(signal,1,NaN);
%                             end
%
%                             if track_opt == 1
%                                 dcommon = intersect(hmlFXcarryNETts.dates,hmlFXmadNETts.dates);
%                                 X = hmlFXmadNETts(datestr(dcommon));
%                             elseif track_opt == 2
%                                 dcommon = intersect(hmlFXcarryNETts.dates,MAD_aggr1_innovations.dates);
%                                 X = -MAD_aggr1_innovations(datestr(dcommon));
%                             elseif track_opt == 3
%                                 dcommon = intersect(hmlFXcarryNETts.dates,MAD_dev_PC1.dates);
%                                 X = -MAD_dev_PC1(datestr(dcommon));
%                             end
%                             for i=1:length(field_list)
%                                 if any(strcmp(field_list(i),fieldnames(X)))
%                                     X = rmfield(X,field_list(i));
%                                 end
%                             end
%
% %                             % 1. "Simple" methods
% %                             X_mat = fts2mat(X);
% %                             signal = signal(datestr(dcommon));
% %                             signal_mat = fts2mat(signal);
% %                             count(1,1:size(signal,2)) = 0;
% %                             combination = [];
% %                             for i = 1:size(signal,1)
% %                                 [values, indexes] = sort(signal_mat(i,:));
% %                                 if strcmp('low',low_vs_high)
% % %                                     weights = ones(1,var_numb) / var_numb;
% %                                     weights = signal_mat(i,indexes(1:var_numb)) / sum(signal_mat(i,indexes(1:var_numb)));
% %                                     combination(i,1) = X_mat(i,indexes(1:var_numb))*weights'; % try low and high value after sorting
% %                                     count(1,indexes(1:var_numb)) = count(1,indexes(1:var_numb)) + 1;
% %                                 elseif strcmp('high',low_vs_high)
% % %                                     weights = ones(1,var_numb) / var_numb;
% %                                     weights = signal_mat(i,indexes(end-var_numb+1:end)) / sum(signal_mat(i,indexes(end-var_numb+1:end)));
% %                                     combination(i,1) = X_mat(i,indexes(end-var_numb+1:end))*weights'; % try low and high value after sorting
% %                                     count(1,indexes(end-var_numb+1:end)) = count(1,indexes(end-var_numb+1:end)) + 1;
% %                                 end
% %                             end
% %                             combination_ts = fints(X.dates,combination,'combination','monthly');
% %
% %                             % 2. a-la Granger and Bates (1969) weighting of individual forecasts
% %                             dcommon = intersect(X.dates,hmlFXmadNETts.dates);
% %                             X = X(datestr(dcommon));
% %                             X_mat = fts2mat(X);
% %                             signal = signal(datestr(dcommon));
% %                             signal_mat = fts2mat(signal);
% %                             count(1,1:size(signal,2)) = 0;
% %                             combination = [];
% %                             HML_temp = fts2mat(hmlFXcarryNETts(datestr(dcommon)));
% %                             HML_MAD_temp = hmlFXmadNETts(datestr(dcommon));
% %                             for i = 1:length(field_list)
% %                                 if any(strcmp(field_list(i),fieldnames(HML_MAD_temp)))
% %                                     HML_MAD_temp = rmfield(HML_MAD_temp,field_list(i));
% %                                 end
% %                             end
% %                             if strcmp(contemp_vs_lag,'lag')
% %                                 HML_MAD_temp = lagts(HML_MAD_temp,1,NaN);
% %                             end
% %                             HML_MAD_temp = fts2mat(HML_MAD_temp);
% %                             for i = rolling_window:size(signal,1)
% %                                 [values, indexes] = sort(signal_mat(i,:));
% %                                 % run rolling regression
% %                                 for j = 1:size(HML_MAD_temp,2)
% %                                     x_temp = HML_MAD_temp(i-rolling_window+1:i,j);
% %                                     y_temp = HML_temp(i-rolling_window+1:i);
% %                                     if any(isnan(x_temp))
% %                                         y_temp(find(isnan(x_temp))) = [];
% %                                         x_temp(find(isnan(x_temp))) = [];
% %                                         resid = HML_temp(i-rolling_window+2:i) - HML_MAD_temp(i-rolling_window+2:i,j)*(x_temp \ y_temp);
% %                                         sigma_inv(j) = 1/(resid'*resid/(rolling_window-1));
% %                                     else
% %                                         resid = HML_temp(i-rolling_window+1:i) - HML_MAD_temp(i-rolling_window+1:i,j)*(x_temp \ y_temp);
% %                                         sigma_inv(j) = 1/(resid'*resid/(rolling_window-1));
% %                                     end
% %                                 end
% %                                 clear x_temp y_temp resid
% %                                 if strcmp('low',low_vs_high)
% %                                     weights = sigma_inv(indexes(1:var_numb)) / sum(sigma_inv(indexes(1:var_numb)));
% %                                     combination(i-rolling_window+1,1) = X_mat(i,indexes(1:var_numb))*weights'; % try low and high value after sorting
% %                                     count(1,indexes(1:var_numb)) = count(1,indexes(1:var_numb)) + 1;
% %                                 elseif strcmp('high',low_vs_high)
% %                                     weights = sigma_inv(indexes(end-var_numb+1:end)) / sum(sigma_inv(indexes(end-var_numb+1:end)));
% %                                     combination(i-rolling_window+1,1) = X_mat(i,indexes(end-var_numb+1:end))*weights'; % try low and high value after sorting
% %                                     count(1,indexes(end-var_numb+1:end)) = count(1,indexes(end-var_numb+1:end)) + 1;
% %                                 end
% %                             end
% %                             combination_ts = fints(X.dates(rolling_window:end),combination,'combination','monthly');
%
%                             % plotting correlations
%                             periods = 12; % rolling window in months
%                             MAD_temp = combination_ts;
%                             dcommon = intersect(hmlFXcarryNETts.dates,MAD_temp.dates);
%                             HML_temp = hmlFXcarryNETts(datestr(dcommon));
%                             VOL_temp = FXdVOLts(datestr(dcommon));
%                             [R, PVAL] = corrcoef(MAD_temp,HML_temp);
%                             if R(1,2) > 0.4
%                                 fprintf('---------------------------------------------\n')
%                                 correl_unc_HML = R(1,2)
%                                 [R, PVAL] = corrcoef(MAD_temp,VOL_temp);
%                                 correl_unc_VOL = -R(1,2)
%                                 [R, PVAL] = corrcoef(HML_temp,VOL_temp);
%                                 -R(1,2)
%
%                                 for i = periods:length(HML_temp)
%                                     [R, PVAL] = corrcoef(MAD_temp(i-periods+1:i),HML_temp(i-periods+1:i));
%                                     correl_HML(1,i-periods+1) = R(1,2);
%                                     [R, PVAL] = corrcoef(VOL_temp(i-periods+1:i),HML_temp(i-periods+1:i));
%                                     correl_VOL(1,i-periods+1) = -R(1,2);
%                                 end
%                                 % subplot(length(MAD_variables),1,h)
%                                 figure;
%                                 plot(HML_temp.dates(periods:end),correl_HML,'b');
%                                 hold on
%                                 plot(HML_temp.dates(periods:end),correl_VOL,'r');
%                                 legend('MAD vs. HML', 'VOL vs. HML','Location','NorthEastOutside');
%                                 xlabel('time');
%                                 ylabel('Rolling correlations');
%                                 % title(MAD_variables{h});
%                                 datetick('x','yy','keepticks');
%
%                                 {
%                                     var_numb
%                                     contemp_vs_lag
%                                     low_vs_high
%                                     cdf_vs_sort
%                                     fx
%                                     signal_opt
%                                     track_opt
%                                     }
%
%                             end
%                             count = [];
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
%
% % 3. Estimation of HML through HML_MADs with time-varying coefficients put
% % on the latter via Kalman filter
% % a. get series
% const = 'yes';
% W = MAD_aggr1_innovations; W = rmfield(W,'dMAD_pc1_ts');
% % Options:
% % 1. hmlFXmadNETts;
% % 2. MAD_aggr1_innovations; W = rmfield(W,'dMAD_pc1_ts');
% var_set = [1 2 3 4 5];
% dcommon = intersect(hmlFXcarryNETts.dates,W.(MAD_variables{var_set(1)}).dates);
% y = fts2mat(hmlFXcarryNETts(datestr(dcommon))); % check: rt(2:end);
% nobs = size(y,1);
% s = hmlFXcarryNETts.dates(datestr(dcommon));
% if strcmp(const,'yes')
%     X = ones(nobs,1);
% elseif strcmp(const,'no')
%     X = [];
% end
% for i = 1:length(var_set)
%     X = [X fts2mat(W.(MAD_variables{var_set(i)})(datestr(dcommon)))]; % X = [ones(nobs,1) rt(1:end-1)];
% end
% % X = fts2mat(W(datestr(dcommon)).(MAD_variables(1)));
% nvar = size(X,2);
% beta_uncond = X \ y;
% var_hat = [];
% for i = 1:size(X,2)
%     e = y - X(:,i)*(X(:,i) \ y);
%     var_hat = [var_hat; e'*e/(nobs-1)]; % X = [ones(nobs,1) rt(1:end-1)];
% end
% clear e i
% 
% % b. specify problem in terms of general Kalman filter framework
% % Specify state equation
% c = zeros(nobs,size(X,2)); % explained what happens here in section 2.2 of Rockinger (2004) notes; number of betas is equal to the number of elements in X
% T_est = 'yes'; % if 'yes' by construction T will be estimated as diagonal matrix with eigenvalues inside the unit circle
% if strcmp(T_est,'yes')
%     T = 0;
%     beta_T = zeros(1,nvar);
%     eps = 0.0001;
%     lb_T = -zeros(1,nvar)*(1 - eps);
%     ub_T = ones(1,nvar)*(1 - eps);
%     clear eps
% elseif strcmp(T_est,'no')
%     T = eye(nvar);
%     T = kron(reshape(T,1,nvar^2),ones(nobs,1)); % explained what happens here in section 2.2 of Rockinger (2004) notes
%     beta_T = [];
%     lb_T = [];
%     ub_T = [];
% end
% R = eye(nvar);
% R = kron(reshape(R,1,nvar^2),ones(nobs,1)); % explained what happens here in section 2.2 of Rockinger (2004) notes
% % Specify observation equation
% Z = X; % explained what happens here in section 2.2 of Rockinger (2004) notes
% d = zeros(nobs,size(y,2));
% clear X
% 
% % c. parameter estimation
% a0_est = 'no'; % choose whether to estimate a0 as part of MLE procedure or come up with exogeneous prior estimate
% P0_est = 'yes'; % choose whether to estimate P0 as part of MLE procedure or come up with exogeneous prior estimate
% if strcmp(a0_est,'yes')
%     a0 = 0; % AK: simply initialise those, these initial values will be changed after parameter estimation phase
%     beta_a0 = beta_uncond';
%     lb_a0 = [-10*ones(1,nvar)];
%     ub_a0 = [10*ones(1,nvar)];
% elseif strcmp(a0_est,'no')
%     a0 = zeros(nvar,1);
%     % Options:
%     % 1. beta_uncond;
%     % 2. zeros(nvar,1);
%     % 3. ones(nvar,1); % e.g.
%     % 4. -ones(nvar,1); % e.g. idea is not to have any significant changes
%     % in values  independent of the starting value after burning out phase below
%     beta_a0 = [];
%     lb_a0 = [];
%     ub_a0 = [];
% end
% if strcmp(P0_est,'yes')
%     P0 = 0;
% elseif strcmp(P0_est,'no')
%     P0 = eye(nvar).*(var_hat*ones(1,nvar)); % set to residuals from individual OLS regressions
% end
% H = 0; % ---//---
% Q = 0; % ---//---
% factor = 10;
% beta_Q0 = factor*ones(1,nvar);
% lb_Q0 = [0.0001*ones(1,nvar)];
% ub_Q0 = [100*ones(1,nvar)];
% 
% beta0 = [beta_a0 beta_T beta_Q0 factor*1]; % initial vector to feed into the ml function (bottom of the script)
% lb = [lb_a0 lb_T lb_Q0 0.0001]; % first: betas bounds, middle: sigma_epsilon bound, lastly: sigma_eta bounds
% ub = [ub_a0 ub_T ub_Q0 100]; % ---//---
% beta0 = beta0';
% lb = lb';
% ub = ub';
% options = optimset('Diagnostics','on','Display','iter','MaxFunEvals',10000);
% [beta,stderr1,vc,logl] = max_lik(@ml,beta0,'Hessian',[],[],[],[],lb,ub,[],options,...
%     y,Z,d,T,c,R,a0,P0,H,Q,1,nobs+1,T_est,a0_est,P0_est,nvar);
% % Notes:
% % 1. maximises likelihood by changing vector of parameters 'beta', other
% % parameters passed to evaluate the likelihood function are specified after
% % 'options' (second row)
% % 2. code works in such a way that if one before last argument is 0, then
% % parameters in Kalman are taken to be time-invariant and hence the
% % parameters specified at the beginning of this section of the code should
% % be past as pure row vectors (without any expanded time (column) dimension).
% % 3. as part of the routine of parameter estimation one also estimates the
% % initial values for Kalman filter iterations: 'a0' and (if specified) 'P0'
% % 4. asymptotic properties of the parameters from MLE are not easily derived as random walk is assumed - need to restrict the model to be stationary first to be able to use Hamilton (1994) (p.388-389)
% 
% % d. AK: Kalman filter iterations
% % AK: initialise Kalman filter iterations - transformations are pretty much
% % the ml.m code
% ref = 1;
% if strcmp(a0_est,'yes')
%     a0 = beta(ref:ref+nvar-1); % these are initial values of betas used to launch a Kalman filter
%     ref = ref + nvar;
% end
% if strcmp(T_est,'yes')
%     T = eye(nvar).*(beta(ref:ref+nvar-1)*ones(1,nvar));
%     ref = ref + nvar;
% end
% beta(ref:ref+nvar-1) = beta(ref:ref+nvar-1).^2; % to make sure estimated parameters are positive
% Q = eye(nvar).*(beta(ref:ref+nvar-1)*ones(1,nvar));
% ref = ref + nvar;
% if strcmp(P0_est,'yes')
%     if strcmp(T_est,'yes')
%         P0 = reshape(inv(eye(nvar^2) - kron(T,T))*reshape(Q,nvar^2,1),nvar,nvar);
%     elseif strcmp(T_est,'no')
%         P0 = Q;
%         % Danger!: seems like author restricts P0 = Q in his case when T = I. Not
%         % sure it is correct. It is not really correct if eigenvalues of T lie
%         % inside (!) the unit circle (i.e. beta process is stationary) - see
%         % Hamilton p. 378 for initial values a0 and P0 in this case... Below IF
%         % statement is performend to provide a quick fix
%     end
% end
% if strcmp(T_est,'yes')
%     T = kron(reshape(T,1,nvar^2),ones(nobs,1)); % explained what happens here in section 2.2 of Rockinger (2004) notes
% end
% % AK: Assign values for the unknown parameters, estimated in previous section
% % through the MLE
% Q = kron(reshape(Q,1,nvar^2), ones(nobs,1)); % explained what happens here in section 2.2 of Rockinger (2004) notes
% beta(ref) = beta(ref)^2;
% H = kron(beta(ref), ones(nobs,1)); % basically, because ; explained what happens here in section 2.2 of Rockinger (2004) notes
% ref = ref + 1;
% 
% [y_cond,y_prev,MSE,v,a,a_cond,a_smooth,a_prev,P,P_cond,P_smooth,P_prev,F,logl] = kalman_filter(y,Z,d,T,c,R,a0,P0,H,Q,1,nobs+1);
% % Note: implement p.398-399 to uncorporate parameter uncertainty into the MSE of xi (smoothed or forecasted)
% 
% % burning of first observations
% burn = 20;
% s = s(burn+1:end,:);
% nobs = nobs - burn;
% y_cond = y_cond(burn+1:end,:);
% y_prev = y_prev(burn+1:end,:);
% MSE = MSE(burn+1:end,:);
% v = v(burn+1:end,:);
% a = a(burn+1:end,:);
% a_cond = a_cond(burn+1:end,:);
% a_smooth = a_smooth(burn+1:end,:);
% a_prev = a_prev(burn+1:end,:);
% P = P(burn+1:end,:);
% P_cond = P_cond(burn+1:end,:);
% P_smooth = P_smooth(burn+1:end,:);
% P_prev = P_prev(burn+1:end,:);
% 
% if strcmp(const,'yes')
%     legend_names = ['const'; MAD_variables];
%     var_set = var_set + ones(1,length(var_set));
%     var_set = [1, var_set];
% elseif strcmp(const,'no')
%     legend_names = MAD_variables;
% end
% for i = 1:nvar
%     figure;
%     subplot(2,1,1);
%     plot(s,beta_uncond(i)*ones(nobs,1),'b'); % OLS data
%     hold on
%     plot(s,a_cond(:,i),'g'); % one period ahead forecast
%     plot(s,a(:,i),'k'); % contemporaneous
%     plot(s,a_smooth(:,i),'r'); % smoothed series
%     hold off
%     legend('OLS fitted','1-period forecast','contemporaneous','smoothed','Location','NorthEastOutside');
%     xlabel('time');
%     ylabel('values of betas');
%     datetick('x','yy','keepticks');
%     title(strcat('Beta analysis_',legend_names(var_set(i))));
%     subplot(2,1,2);
%     plot(s,P_cond(:,(i-1)*(nvar+1)+1),'g'); % one period ahead forecast
%     hold on
%     plot(s,P(:,(i-1)*(nvar+1)+1),'k'); % contemporaneous
%     plot(s,P_smooth(:,(i-1)*(nvar+1)+1),'r'); % smoothed series
%     hold off
%     legend('MSE beta 1-period forecast','MSE beta contemporaneous','MSE beta smoothed','Location','NorthEastOutside');
%     xlabel('time');
%     ylabel('values of MSE');
%     datetick('x','yy','keepticks');
%     title(strcat('MSE analysis_',legend_names(var_set(i))));
%     saveas(gcf, char(strcat(cd_old,'\Figures\Time-varying betas\', num2str(nvar),'\Beta_', num2str(i),'.', ext)), ext); % gcf brings in the current figure handle
% end
% figure;
% plot(s,a_smooth);
% legend(legend_names,'Location','NorthEastOutside');
% xlabel('time');
% ylabel('values of betas');
% datetick('x','yy','keepticks');
% title(strcat('beta analysis'));
% saveas(gcf, char(strcat(cd_old,'\Figures\Time-varying betas\', 'Betas', '.', ext)), ext); % gcf brings in the current figure handle
% % % forecast over half of sample
% % [y_prev,a_prev,P_prev,MSE] = kalman_forecasting(y,Z,d,T,c,R,a0,P0,H,Q,1,floor(size(y,1)/2));
% % for i = 1:nvar
% %     figure;
% %     subplot(2,1,1);
% %     plot(s,y,s,y_prev)
% %     subplot(2,1,2);
% %     plot(s,a(:,i),s,a_prev(:,i))
% % end
% 
% % save 'Data\OUTPUT\MAD_factors' combination_ts -append

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 10. Asset pricing exercise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % To check combinations generated through estimated time-varying betas
% dcommon = intersect(hmlFXcarryNETts.dates,hmlFXmadNETts.dates);
% [A B] = xlsread('Data\temp\Smoothed_Betas.xlsx',1);
% combination_ts = fints(dcommon, sum(fts2mat(hmlFXmadNETts(datestr(dcommon)) .* A(:,2:end)),2), 'combination', 'monthly');

% run Fama_French_factors;
% MAD_variables = [MAD_variables; 'dMAD_pc1_ts'];
MAD_variables_paper = {'CA'; 'PI'; 'IR'; 'RG'; 'FX'; 'dMAD_pc1_ts'};

figure;
for i = 1%1:length(MAD_variables_paper)
    
% Examples:
% 1) MAD_aggr1_innovations.(MAD_variables(i)); % or MAD_aggr1_innovations.('dMAD_pc1_ts');
% 1.a) dMAD_dev_PC1.(MAD_variables(i));
% 1.b) MAD_aggr1_innovations_filter.('dMAD_pc1_ts_filter');
% 1.c) dMAD_dev_PC1_filter.(MAD_variables(i));
% 2) dMAD_mimmick_ts.(MAD_variables(i));
% 2.a) dMAD_dev_PC1_mimmick_ts.(MAD_variables(i));
% 3) combination_ts
MAD = MAD_aggr1_innovations.(MAD_variables_paper(i));
dcommon = intersect(assetsFXcarryNETts.dates,MAD.dates);
MAD = MAD(datestr(dcommon));

% specify inputs to the asset pricing
factors = fts2mat(100*[rxFXcarryNETts(datestr(dcommon)) MAD(datestr(dcommon))]);

% TEMP standardize shocks
factors(:,2:end) = factors(:,2:end) ./ (ones(length(dcommon),1)*std(factors(:,2:end),0,1));
AK_DESC_STATS(factors);

% Examples:
% 1) 100*fts2mat(assetsFXcarryNETts(datestr(dcommon)));
% 2) assetsFXnfaGROSSts
% 3) 100*fts2mat(FFcountry_monthly_ts(datestr(dcommon)));
portf_ret_net_level = 100*fts2mat([assetsFXcarryNETts(datestr(dcommon))]);
% perform asset pricing test(s)
[Desc_ts_test Desc_xs_test Desc_fmb_test] = AK_ASSET_PRICING_LINEAR(portf_ret_net_level, factors, true);

% % graph with a set of AP results
% if mod(length(MAD_variables_paper),2) == 0
%     subplot(2,length(MAD_variables_paper)/2,i);
% elseif mod(length(MAD_variables_paper),2) == 1
%     subplot(2,(length(MAD_variables_paper)+1)/2,i);
% end
% AK_ASSET_PRICING_PLOT(portf_ret_net_level,Desc_xs_test.d.g(1:size(portf_ret_net_level,2)),'error_bars',true,'VCV_g',Desc_xs_test.d.VCV_g(1:size(portf_ret_net_level,2),1:size(portf_ret_net_level,2)),'alpha',0.1,'plot_type','dep','colmrk_set', [6 6]);
% if strcmp(MAD_variables_paper(i),'PI')
%     title(strcat('$\Delta u_{','IF','}$'),'Interpreter','Latex');
% elseif strcmp(MAD_variables_paper(i),'dMAD_pc1_ts')
%     title(strcat('$\Delta u_{','PC','}$'),'Interpreter','Latex');
% else
%     title(strcat('$\Delta u_{',MAD_variables_paper(i),'}$'),'Interpreter','Latex');
% end
% axis([-0.5 1 -0.5 1])
% axis square
% xlabel('Model-predicted');
% ylabel('Actual');

% APstruct(1).(MAD_variables_paper{i}) = Desc_ts_test.regressions;
% APstruct(2).(MAD_variables_paper{i}) = Desc_xs_test.summary;
end
clear i MAD
% AK_EXPORT_TO_XLSX(APstruct,'DATA\OUTPUT\AP_',MAD_variables_paper,{'TS','XS'});

% % saving the chart
% if strcmp(ext,'eps')
%     % saveas(gcf, char(strcat(cd_old,'\Figures\Supplementary graphs\', 'AP_BC_MAD_shocks','.', ext)), 'epsc'); % gcf brings in the current figure handle
%     print(gcf, char(strcat(cd_old,'\Figures\Supplementary graphs\', 'AP_BC_MAD_shocks','.', ext)), '-depsc'); % 'saveas' can only save .eps format of level 1. 
% else
%     saveas(gcf, char(strcat(cd_old,'\Figures\Supplementary graphs\', 'AP_BC_MAD_shocks','.', ext)), ext); % gcf brings in the current figure handle    
% end

% % TEMP:
% output = AK_DESC_STATS(portf_ret_net_level,'series_names',{'1','2','3','4','5','6'},'xtra_stats',true);
% temp = output.summary;
% temp(2,2:end) = num2cell(output.mean*12);
% temp(4,2:end) = num2cell(output.median*12);
% temp(3,2:end) = num2cell(output.std*sqrt(12));
% temp(8,2:end) = num2cell(output.mean_st_err*sqrt(12));
% temp(9,2:end) = num2cell(output.sharpe_ratio*sqrt(12));
% temp
% clear output temp

% individual currency strategies pricing
portf_ret_net_level = 100*fts2mat([assetsFXcarryTSindivGROSSts(datestr(dcommon))]);
FMB1 = AK_FMB(portf_ret_net_level, factors, 'roll', false, 'pass2const', false,'ap_factors_traded', true); % with non-rollying betas in the first pass
FMB2 = AK_FMB(portf_ret_net_level, factors, 'pass2const', false,'ap_factors_traded', true); % with rollying betas in the first pass

% % finding "dodgy" countries
% beta = zeros(size(portf_ret_net_level,2),2);
% for i = 1:size(portf_ret_net_level,2)
%     output = regstats(portf_ret_net_level(:,i),factors);
%     beta(i,:) = output.beta(2:end)';
% end
% country_names = fieldnames(assetsFXcarryXSindivGROSSts);
% country_names = country_names(4:end);
% country_names(find(beta(:,2)>0.05))

% Comparison.lambda(1+gather_day,:) = Desc_xs_test.d.lambda(1,2);
% Comparison.SE_lambda(1+gather_day,:) = Desc_xs_test.d.lambda(2,2);
% delete 'Data\OUTPUT\Comparison.mat'
% save 'Data\OUTPUT\Comparison' Comparison
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 11. Supplementary analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Plot disagreement shock vs. carry trade cumulative return (defined via HML)
% dcommon = intersect(MAD_aggr1_innovations.dates, hmlFXcarryNETts.dates);
% strat_ret = [0; fts2mat(hmlFXcarryNETts(datestr(dcommon)))];
% dcommon = [busdate(datenum(year(dcommon(1)),month(dcommon(1)),1+gather_day),-1); dcommon];
% cum_ret = cumprod(strat_ret + ones(size(strat_ret)))-1;
% clear strat_ret
% cum_ret_ts = fints(dcommon,cum_ret,'cumulative_return','monthly');
% ret_ts = fints(dcommon,[NaN; fts2mat(hmlFXcarryNETts(datestr(dcommon(2:end))))],'return','monthly');
% shock_series = fints(dcommon,[NaN; fts2mat(MAD_aggr1_innovations.('CA'))],'Disagreement_shocks','monthly');
% figure;
% % note that HML is an effectively levered strategy (cause both long and
% % short parts are carries themselves); hence, to compare e.g. vs. stock
% % return index one needs to construct smth like 2*(rm-rf)
% subplot(3,1,1);
% plot_ref = plot(cum_ret_ts*100);
% title('Cumulative return on HML_{FX} strategy');
% set(legend(plot_ref),'Location','SouthEast','Interpreter','none'); % set(0,'DefaultTextInterpreter','none') - didn't work
% xlabel('time');
% ylabel('Cumulative return (%)');
% datetick('x','yy','keepticks');
% axis tight
% recessionplot;
% 
% subplot(3,1,2);
% plot_ref = plot(ret_ts*100);
% title('Monthly returns on HML_{FX} strategy');
% set(legend(plot_ref),'Location','NorthEast','Interpreter','none'); % set(0,'DefaultTextInterpreter','none') - didn't work
% xlabel('time');
% ylabel('Return (%)');
% datetick('x','yy','keepticks');
% axis tight
% recessionplot;
% 
% % title(strcat('MSE analysis_',legend_names(var_set(i))));
% subplot(3,1,3);
% plot_ref = plot(shock_series);
% title('Monthly shocks to aggregate current account disagreement');
% set(legend(plot_ref),'Location','SouthEast','Interpreter','none'); % set(0,'DefaultTextInterpreter','none') - didn't work
% xlabel('time');
% ylabel('Innovations');
% datetick('x','yy','keepticks');
% axis tight
% recessionplot;
% pause;
% close
% clear plot_ref
% 
% % do 3-period mov avg
% ret_ts = tsmovavg(ret_ts,'s',12);
% shock_series = tsmovavg(shock_series,'s',12);
% m = fts2mat(ret_ts*100);
% ret_stand = (m - nanmean(m)) / nanstd(m);
% m = fts2mat(shock_series*100);
% shock_stand = (m - nanmean(m)) / nanstd(m);
% figure;
% plot(ret_ts.dates,ret_stand, 'r')
% xlabel('time');
% ylabel('Innovations');
% datetick('x','yy','keepticks');
% % title(strcat('MSE analysis_',legend_names(var_set(i))));
% axis tight
% xlim = get(gca,'xlim');  %Get x range
% hold on
% plot(ret_ts.dates,shock_stand, 'b--')
% legend({'HML_{FX} standardised', 'MAD_{CA} shock standardised'}, 'Location','NorthWest');
% plot([xlim(1) xlim(2)],[0 0],'--k')
% recessionplot;
% hold off
% pause;
% close
% 
% % a-la Menkhoff et al. (2012a) Figure 2
% bars_number = 4;
% X = MAD_aggr1_innovations.('CA'); % hmlFXcarryNETts, FXdVOLts
% Y = hmlFXcarryNETts; % MAD_aggr1_innovations.('CA')
% dcommon = intersect(X.dates, Y.dates);
% n = length(dcommon);
% X = fts2mat(X(datestr(dcommon)));
% Y = fts2mat(Y(datestr(dcommon)));
% [values, indexes] = sort(X);
% start_index = 1;
% % determine entries in each bar
% numb_entries = [];
% for j = 1:bars_number
%     numb_entries = [numb_entries,round(j * n / bars_number) - round((j-1) * n / bars_number)];
% end
% y_plot = zeros(bars_number,1);
% for j = 1:bars_number
%     finish_index = start_index + numb_entries(j) - 1;
%     held(j) = {indexes(start_index:finish_index)};
%     y_plot(j) = mean(Y(held{j}));
%     start_index = finish_index + 1;
% end
% % construct plot
% y_plot = y_plot*100*12;
% x_plot = 1:1:bars_number;
% figure;
% bar(x_plot,y_plot)
% xlabel('Portfolios formed by sorting on MAD_{CA}');
% ylabel('Mean HML_{FX} strategy return (in % per annum)');
% title('All countries')
% pause;
% close
% 
% % TEMP pretty much replica of the analysis done right above with different
% % series to figure out if TS momentum and aggr disagreement are related
% bars_number = 3;
% X = MAD_aggr1_ts.('MAD_aggr1_PC1'); % MAD_aggr1_ts.('MAD_aggr1_PC1'), MAD_aggr1_innovations.('dMAD_pc1_ts'), rxFXtsmomentumNETts
% X = tsmovavg(X,'s',1);
% X = lagts(X,1,NaN);
% X = X(2:end);
% Y = rxFXtsmomentumNETts; % MAD_aggr1_innovations.('CA')
% % Y = lagts(Y,1,NaN);
% % Y = Y(2:end);
% dcommon = intersect(X.dates, Y.dates);
% n = length(dcommon);
% X = fts2mat(X(datestr(dcommon)));
% Y = fts2mat(Y(datestr(dcommon)));
% [values, indexes] = sort(X);
% start_index = 1;
% % determine entries in each bar
% numb_entries = [];
% for j = 1:bars_number
%     numb_entries = [numb_entries,round(j * n / bars_number) - round((j-1) * n / bars_number)];
% end
% y_plot = zeros(bars_number,1);
% for j = 1:bars_number
%     finish_index = start_index + numb_entries(j) - 1;
%     held(j) = {indexes(start_index:finish_index)};
%     y_plot(j) = mean(Y(held{j}));
%     start_index = finish_index + 1;
% end
% % construct plot
% y_plot = y_plot*100*12;
% x_plot = 1:1:bars_number;
% figure;
% bar(x_plot,y_plot)
% xlabel('Portfolios formed by sorting on MAD_{CA}');
% ylabel('Mean HML_{FX} strategy return (in % per annum)');
% title('All countries');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 12. Disagreement vs VOL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MAD_var_paper = MAD_variables_paper;
MAD_var_paper{6} = 'MAD_aggr1_PC1';
CONS_var_paper = MAD_var_paper;
CONS_var_paper{6} = 'CONS_aggr_PC1';
regsor1 = MAD_aggr1_ts; % MAD_aggr1_ts, MAD_aggr1_innovations
regsor2 = CONS_aggr_ts; % CONS_aggr_ts, CONS_aggr_innovations
regsand = FXaggrVOL_monthly_ts; % FXaggrVOL_monthly_ts, FXdVOLts

lag_regsor = 0;
regsor1 = lagts(regsor1, lag_regsor, NaN);
regsor1_choose = [1:length(MAD_var_paper)-1]; % [], 1:length(MAD_var_paper)-1
regsor2 = lagts(regsor2, lag_regsor, NaN);
regsor2_choose = []; % [], 1:length(MAD_var_paper)-1
regsor3 = lagts(regsand, lag_regsor, NaN);
regsor3_choose = []; % [], 1:length(MAD_var_paper)-1

dcommon = intersect(regsor1.dates,regsand.dates);
dcommon = datestr(dcommon);
regsor = [];
for i = 1:length(regsor1_choose)
    regsor = [regsor fts2mat(regsor1.(MAD_var_paper{regsor1_choose(i)})(dcommon))];
end
for i = 1:length(regsor2_choose)
    regsor = [regsor fts2mat(regsor2.(CONS_var_paper{regsor2_choose(i)})(dcommon))];
end
for i = 1:length(regsor3_choose)
    regsor = [regsor fts2mat(regsor3(dcommon))];
end
regsand = fts2mat(regsand(dcommon));
row_del = any(isnan([regsand,regsor]),2);
regsor(row_del,:) = [];
regsand(row_del) = [];
clear row_del

% regressions, single coefficient tests
result = regstats(regsand,regsor);
[EstCoeffCov,se,coeff] = hac(regsor,regsand,'smallT',false);
[coeff coeff ./ se]'
% AK_ASSET_PRICING_LINEAR(regsand(all(~isnan([regsand,regsor]),2),:),regsor(all(~isnan([regsand,regsor]),2),:),false);

% Granger-causality
lags = 2;
[Granger_stat, Granger_pval, Granger_statAll, Granger_pvalAll] = grangercause([regsor regsand],1,[1:lags],1,1,1);
Granger_pval
clear lags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% *. Unused bits below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

delete *.asv

% % Get required spot rates
% [A B] = xlsread('Data\DATASTREAM\FX\FXdata_Daily.xlsx',4);
% B(1,2:end) = strrep(B(1,2:end),' ','_');
% B(1,2:end) = strrep(B(1,2:end),'EURO_AREA','EUROZONE');
% % Switch necessary FX rates to USD/FCU view from FCU/USD (FCU - foreign currency unit)
% country_list = {'IRELAND','UNITED_KINGDOM'};
% for i = 1:length(B(1,2:end))
%     if ~any(strcmp(B(1,i+1),country_list))
%         A(:,i) = 1 ./ A(:,i);
%     end
% end
% A_fin = [];
% B_fin = [];
% B_fin_missed = [];
% i = 2;
% while i <= (size(FORECAST_TOP,2))
%     if any(strcmp(FORECAST_TOP(1,i),B(1,2:end)))
%         A_fin = [A_fin, A(:,find(strcmp(FORECAST_TOP(1,i),B(1,2:end))))];
%         B_fin = [B_fin, FORECAST_TOP(1,i)];
%         i = i + 1;
%     else
%         B_fin_missed = [B_fin_missed, FORECAST_TOP(1,i)];
%         FORECAST_TOP(:,i) = [];
%         FORECAST_BOTTOM(:,i) = [];
%     end
% end
% clear i country_list

% % CASE 1 - didn't work that well
% % identify abnormal deviations
% multiplier = 5;
% current_top = cell2mat(FORECAST_TOP(3:end-1,i)) - cell2mat(FORECAST_CONSENSUS(3:end-1,i));
% previous_top = cell2mat(FORECAST_TOP(2:end-2,i)) - cell2mat(FORECAST_CONSENSUS(2:end-2,i));
% next_top = cell2mat(FORECAST_TOP(4:end,i)) - cell2mat(FORECAST_CONSENSUS(4:end,i));
% overall_top = cell2mat(FORECAST_TOP(find(~isnan(cell2mat(FORECAST_TOP(2:end,i))-cell2mat(FORECAST_CONSENSUS(2:end,i))))+1,i))-cell2mat(FORECAST_CONSENSUS(find(~isnan(cell2mat(FORECAST_TOP(2:end,i))-cell2mat(FORECAST_CONSENSUS(2:end,i))))+1,i));
% current_bottom = cell2mat(FORECAST_CONSENSUS(3:end-1,i))-cell2mat(FORECAST_BOTTOM(3:end-1,i));
% previous_bottom = cell2mat(FORECAST_CONSENSUS(2:end-2,i))-cell2mat(FORECAST_BOTTOM(2:end-2,i));
% next_bottom = cell2mat(FORECAST_CONSENSUS(4:end,i)) - cell2mat(FORECAST_BOTTOM(4:end,i));
% overall_bottom = cell2mat(FORECAST_CONSENSUS(find(~isnan(cell2mat(FORECAST_CONSENSUS(2:end,i))-cell2mat(FORECAST_BOTTOM(2:end,i))))+1,i))-cell2mat(FORECAST_BOTTOM(find(~isnan(cell2mat(FORECAST_CONSENSUS(2:end,i))-cell2mat(FORECAST_BOTTOM(2:end,i))))+1,i));
% top_outliers = FORECAST_TOP(find(...
%     ((abs(current_top-previous_top) > multiplier*std(overall_top)) & (abs(current_top-next_top) > multiplier*std(overall_top))) &...
%     ((abs(current_bottom-previous_bottom) < multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) < multiplier*std(overall_bottom))) ...
%     )+2,1)
% bottom_outliers = FORECAST_BOTTOM(find(...
%     ((abs(current_top-previous_top) < multiplier*std(overall_top)) & (abs(current_top-next_top) < multiplier*std(overall_top))) &...
%     ((abs(current_bottom-previous_bottom) > multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) > multiplier*std(overall_bottom))) ...
%     )+2,1)
% pause;
% % if outliers are to be deleted uncomment the IF clause below
% if strcmp(robust_to_outliers,'yes - adhoc') && (~isempty(top_outliers) || ~isempty(bottom_outliers))
%     top_censored = cell2mat(FORECAST_CONSENSUS(3:end-1,i)) + previous_top + sign(current_top-previous_top)*multiplier*std(overall_top);
%     top_censored = mat2cell(top_censored,ones(size(top_censored,1),1),ones(1,size(top_censored,2)));
%     bottom_censored = cell2mat(FORECAST_CONSENSUS(3:end-1,i)) - previous_bottom - sign(current_bottom-previous_bottom)*multiplier*std(overall_bottom);
%     bottom_censored = mat2cell(bottom_censored,ones(size(bottom_censored,1),1),ones(1,size(bottom_censored,2)));
%     FORECAST_TOP(find(...
%         ((abs(current_top-previous_top) > multiplier*std(overall_top)) & (abs(current_top-next_top) > multiplier*std(overall_top))) &...
%         ((abs(current_bottom-previous_bottom) < multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) < multiplier*std(overall_bottom))) ...
%         )+2,i) = top_censored(find(...
%         ((abs(current_top-previous_top) > multiplier*std(overall_top)) & (abs(current_top-next_top) > multiplier*std(overall_top))) &...
%         ((abs(current_bottom-previous_bottom) < multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) < multiplier*std(overall_bottom))) ...
%         ),1);
%     FORECAST_BOTTOM(find(...
%         ((abs(current_top-previous_top) < multiplier*std(overall_top)) & (abs(current_top-next_top) < multiplier*std(overall_top))) &...
%         ((abs(current_bottom-previous_bottom) > multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) > multiplier*std(overall_bottom))) ...
%         )+2,i) = bottom_censored(find(...
%         ((abs(current_top-previous_top) < multiplier*std(overall_top)) & (abs(current_top-next_top) < multiplier*std(overall_top))) &...
%         ((abs(current_bottom-previous_bottom) > multiplier*std(overall_bottom)) & (abs(current_bottom-next_bottom) > multiplier*std(overall_bottom))) ...
%         ),1);
%     % Display the outlier-adjusted series to compare vs. "raw"
%     figure
%     plot(datenum(FORECAST_CONSENSUS_outl(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_CONSENSUS_outl(2:end,i)),'b');
%     hold on
%     plot(datenum(FORECAST_BOTTOM(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_BOTTOM(2:end,i)),'r');
%     plot(datenum(FORECAST_TOP(2:end,1),'dd/mm/yy'),cell2mat(FORECAST_TOP(2:end,i)),'g');
%     legend('CONSENSUS', 'Bottom 3 Avg.','Top 3 Avg.');
%     xlabel('time');
%     ylabel('Forecasts');
%     title(strcat(forecast_handle,FORECAST_TOP(1,i),{' '},Data(1,7).text(1, 2*floor((h+1)/2))));
%     datetick('x','yy','keepticks');
%     hold off
%     pause;
%     saveas(gcf, char(strcat(cd_old,'\Figures\Initial forecasts w-o outliers\', 'Forecast_', forecast_handle, MAD_variables(floor((h+1)/2)),'_',FORECAST_TOP(1,i), '.', ext)), ext); % gcf brings in the current figure handle
%     close
% end

toc