%% INITIALIZATION
clc
close all
h = waitbar(0,'Initializing...');

[~,~,events] = xlsread('C:\Users\Bryan\Documents\GitHub\baseball\ncaa\csv\ncaa_games_pbp_2014_D1.xlsx');

charsleft = -ones(length(events),4);
textleft = cell(length(events),4);

batName = cell(length(events),1);
runName = cell(length(events),3);
newRun = cell(1,3);

sub_cell = cell(length(events),3);  % in / pos / out

bases = zeros(length(events),1);
outs = zeros(length(events),1);

balls = zeros(length(events),1);
strikes = zeros(length(events),1);
pitches = cell(length(events),1);

base_end = zeros(length(events),1);
outs_end = zeros(length(events),1);

tas_str = cell(length(events),1);

rbi = zeros(length(events),1);
uer = zeros(length(events),1);
tm_uer = zeros(length(events),1);

is_ab = zeros(length(events),1);
is_pa = zeros(length(events),1);
is_bat = zeros(length(events),1);
is_bip = zeros(length(events),1);

event_cd =  zeros(length(events),1);
hit_cd = zeros(length(events),1);
hit_type = cell(length(events),1);
hit_loc = cell(length(events),1);
is_bunt = zeros(length(events),1);
is_sf = zeros(length(events),1);
is_sh = zeros(length(events),1);
sb_fl = zeros(length(events),1);
cs_fl = zeros(length(events),1);
pk_fl = zeros(length(events),1);

assists = zeros(length(events),6);
putouts = zeros(length(events),3);
errors = zeros(length(events),3);
errtype = cell(length(events),3);

home_bats = zeros(length(events),1);
inn_st_fl = zeros(length(events),1);
inn_end_fl = zeros(length(events),1);
inn_fate = zeros(length(events),1);
runs_before = zeros(length(events),1);
play_fate = zeros(length(events),1);
last_end_inn = 1;

% find semicolons
sc = zeros(length(events),1);

for n=2:length(events),
    tas_str{n} = '';
    runtmp = cell(1,3);
	sub_cell{n,2} = 0;
    
    if(sum(isnan(events{n,4})) > 0 && sum(isnan(events{n,7}))>0) % what if BOTH are empty? ahhhh
        fprintf('No text on line %i\n',n);
        continue;
    elseif(isempty(events{n,7}) || sum(isnan(events{n,7}))>0)
        tmptext = events{n,4};
    else
        tmptext = events{n,7};
    end
    if(mod(n,1000) == 0)
        waitbar(n/length(events),h,sprintf('%i events parsed. (%2.2f%%)',n,100*n/length(events)))
    end
%%
    sc_tmp = [strfind(tmptext,';'),strfind(tmptext,':')];
    sc(n) = length(sc_tmp);
    if(sc(n) > 1)
        battext = tmptext(1:sc_tmp(1)-1);
        charsleft(n,1) = length(battext);
        for m=1:sc(n)-1
            runtmp{m} = tmptext(sc_tmp(m)+1:sc_tmp(m+1)-1);
            charsleft(n,m+1) = length(runtmp{m});
        end
        runtmp{m+1} = tmptext(sc_tmp(m+1)+1:end);
        charsleft(n,m+2) = length(runtmp{m+1});
    elseif(sc(n) == 1)
        battext = tmptext(1:sc_tmp);
        charsleft(n,1) = length(battext);
        runtmp{1} = tmptext(sc_tmp+1:end);
        charsleft(n,2) = length(runtmp{1});
        
    else
        battext = tmptext;
        charsleft(n,1) = length(battext);        
    end

% base/out state
    if(events{n,3} == 0)    % new game
        bases(n) = 0;
        outs(n) = 0;
        newRun = cell(1,3);
        
        home_bats(n) = 0;
        last_end_inn = n;
    elseif(events{n,2} ~= events{n-1,2})    % new inning
        bases(n) = 0;
        outs(n) = 0;
        newRun = cell(1,3);
        
        home_bats(n) = xor(home_bats(n-1),1);
        
        runsThisInn = events{n-1,6}-events{last_end_inn,6};
        tmp_fate = runsThisInn*ones(n-last_end_inn,1);

        runs_before(n) = 0;
        inn_fate(last_end_inn:n-1) = tmp_fate;
        last_end_inn = n;
    elseif(sum(isnan(events{n-1,4})) && sum(isnan(events{n,7})))  % new half-inning, visiting team now bats
        bases(n) = 0;
        outs(n) = 0;
        newRun = cell(1,3);
        
        home_bats(n) = xor(home_bats(n-1),1);

        runsThisInn = events{n-1,6}-events{last_end_inn,6};
        tmp_fate = runsThisInn*ones(n-last_end_inn,1);
        
        inn_fate(last_end_inn:n-1) = tmp_fate;
        last_end_inn = n;
        runs_before(n) = 0;
    elseif(sum(isnan(events{n-1,7})) && sum(isnan(events{n,4})))  % new half-inning, home team now bats
        bases(n) = 0;
        outs(n) = 0;
        newRun = cell(1,3);
        
        home_bats(n) = xor(home_bats(n-1),1);

        runsThisInn = events{n-1,5}-events{last_end_inn,5};
        tmp_fate = runsThisInn*ones(n-last_end_inn,1);
        
        inn_fate(last_end_inn:n-1) = tmp_fate;
        last_end_inn = n;
        runs_before(n) = 0;
    else
        bases(n) = base_end(n-1);
        outs(n) = outs_end(n-1);
        
        home_bats(n) = home_bats(n-1);
    end
    % store runner names from end of last play, then clear to prep for next
    % iteration
    runName(n,:) = newRun;
    
%     switch bases(n)
%         case 0
%             isR1 = false;
%             isR2 = false;
%             isR3 = false;
%         case 1
%             isR1 = true;
%             isR2 = false;
%             isR3 = false;
%         case 2
%             isR1 = false;
%             isR2 = true;
%             isR3 = false;
%         case 3
%             isR1 = true;
%             isR2 = true;
%             isR3 = false;
%         case 4
%             isR1 = false;
%             isR2 = false;
%             isR3 = true;
%         case 5
%             isR1 = true;
%             isR2 = false;
%             isR3 = true;
%         case 6
%             isR1 = false;
%             isR2 = true;
%             isR3 = true;
%         case 7
%             isR1 = true;
%             isR2 = true;
%             isR3 = true;
%         otherwise
%             isR1 = false;
%             isR2 = false;
%             isR3 = false;
%             fprintf('Unusual base state: %i',n);
%     end

    runsOnPlay = 0;
    outsOnPlay = 0;
    errct = 0;
    asstct = 0;
    poct = 0;
% score start
    if(isnan(events{n,5}))
        if(events{n,3} == 0)    % new game
            events{n,5} = 0;
            events{n,6} = 0;
        else
            events{n,5} = events{n-1,5};
            events{n,6} = events{n-1,6};
        end
    end
    
    
%% SKIP END-OF-INNING AND OTHER COMMENTS
    if(strfind(tmptext,'R:'))
        inn_end_fl(n-1) = 1;
        if(n < length(events))
            inn_st_fl(n+1) = 1;
        end
        charsleft(n,:) = 0;
        tas_str{n} = 'eoi';
        outs_end(n) = 0;
        base_end(n) = 0;
        continue;
    elseif(strcmp(tmptext(1),'('))
        tas_str{n} = ['COMMENT: ',tmptext];
        outs_end(n) = outs_end(n-1);
        base_end(n) = base_end(n-1);
        continue;
    elseif(strfind(tmptext,'No play'))
        % ???
        tas_str{n} = 'No play.';
        outs_end(n) = outs_end(n-1);
        base_end(n) = base_end(n-1);
        continue;
    end
% delay
    if(strfind(battext,'delay'))
        tas_str{n} = 'delay';
        tmptext = '';
        continue;
    end
    
% balls/strikes/pitch string
    if(regexp(battext,'(.-.'))
        pitchtext = battext(strfind(battext,'(')+1:strfind(battext,')')-1);
        balls(n) = str2num(pitchtext(1));
        strikes(n) = str2num(pitchtext(3));
        if(length(pitchtext) > 3)
            pitches{n} = pitchtext(5:end);
        end
        
        battext = battext(1:strfind(battext,'(')-1);
    end
    
%% BATTING CODES
    runsOnPlay = length(strfind(tmptext,' scored'))+length(strfind(tmptext,' homered'))+length(strfind(tmptext,' stole home'))+length(strfind(tmptext,' advanced to home'));
% BB/IBB
    if(strfind(battext,'walked'))
        if(strfind(battext,'intentionally'))
            event_cd(n) = 15;
            tas_str{n} = [tas_str{n},'IBB'];
        
            pos = strfind(battext,'intentionally walked');
        
            batName{n} = strtrim(battext(1:pos-1));
            battext = battext(pos+21:end);
        else
            event_cd(n) = 14;
            tas_str{n} = [tas_str{n},'BB'];
        
            pos = strfind(battext,'walked');
        
            batName{n} = strtrim(battext(1:pos-1));
            battext = battext(pos+7:end);
        end
        
        if(~isempty(newRun{1}))
            if(~isempty(newRun{2}))
                if(~isempty(newRun{3}))
                    newRun{3} = newRun{2};
                    newRun{2} = newRun{1};
                else                    
                    newRun{3} = newRun{2};
                    newRun{2} = newRun{1};
                end
            else
                newRun{2} = newRun{1};
            end
        end
        newRun{1} = batName{n};
        
        is_pa(n) = true;
        is_ab(n) = false;
        is_bat(n) = true;
% HP
    elseif(strfind(battext,'hit by pitch'))
        event_cd(n) = 16;
        tas_str{n} = [tas_str{n},'HP'];
        
        is_pa(n) = true;
        is_ab(n) = false;
        is_bat(n) = true;
        
        pos = strfind(battext,'hit by pitch');

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+13:end);
        newRun{1} = batName{n};
% CI
    elseif(strfind(battext,'reached on catcher''s interference'))
        event_cd(n) = 17;
        tas_str{n} = [tas_str{n},'CI '];
        
        is_pa(n) = true;
        is_ab(n) = false;
        is_bat(n) = true;
        
        pos = strfind(battext,'reached on catcher''s interference');

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+34:end);
        newRun{1} = batName{n};
% BI
    elseif(strfind(battext,'out on batter''s interference'))
        event_cd(n) = 2;
        tas_str{n} = [tas_str{n},'BI '];
        pitches{n} = [pitches{n}, 'X'];
        is_bip(n) = true;
        
        is_pa(n) = true;
        is_ab(n) = true;    % is this an official at bat?  I say yes.
        is_bat(n) = true;
        
        outsOnPlay = outsOnPlay + 1;
        
        pos = strfind(battext,'out on batter''s interference');

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+29:end);
% K/KS/KL (TODO: move before reached on error codes)
    elseif(strfind(battext,'struck out'))
        event_cd(n) = 3;
        pos = strfind(battext,'struck out');
        batName{n} = strtrim(battext(1:pos-1));
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        posend = posend(min(2,length(posend)));
        
        if(strfind(battext,'looking'))
            tas_str{n} = [tas_str{n},'KL '];
        elseif(strfind(battext, 'swinging'))
            tas_str{n} = [tas_str{n},'KS '];
        else
            tas_str{n} = [tas_str{n},'K '];
        end
        % if he reached anyway
        if(strfind(battext,'reached '))
            newRun{1} = batName{n};
            % ...via wild pitch
            if(strfind(battext, 'wild pitch'))
                tas_str{n} = [tas_str{n}, 'WP '];
            % ...via passed ball
            elseif(strfind(battext, 'passed ball'))
                tas_str{n} = [tas_str{n}, 'PB '];
            % ...via error
            elseif(strfind(battext, 'error'))
                pos2 = strfind(battext,'error');
                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+9:min(pos2+10,length(battext))),n);
                errtype{n,errct} = 'K';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'O '];
            % ...via muffed throw (sigh)
            elseif(strfind(battext, 'muffed throw'))
                pos2 = strfind(battext,'muffed throw');
                bypos1 = strfind(battext(pos2:end),'by');
                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos1+2:min(pos2+bypos1+4,length(battext))),n);
                errtype{n,errct} = 'K MT';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'MT '];
                battext = battext(1:pos2);
            % ...via fielder's choice (Jesus, guys.)
            elseif(strfind(battext, 'fielder''s choice'))
                tas_str{n} = [tas_str{n}, 'FC '];                
            end
        % if not (with throw)
        elseif(strfind(battext,'out at first '))
            fieldtext = battext(strfind(battext,'out at first'):pos+posend-1);
            poct = poct+1;
            tos = strfind(fieldtext,' to ');

            if(strfind(fieldtext,'unassisted'))
                poct = poct+1;
                putouts(n,poct) = parse_pos(fieldtext(13:15),n);   
                tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
            else
                for k=1:length(tos)
                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                    tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                end
                putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);   
                tas_str{n} = [tas_str{n},'',num2str(putouts(n,poct)),' '];
            end
            outsOnPlay = outsOnPlay + 1;
        % if not (with strike 'em out/throw 'em out)
        elseif(strfind(battext,'double play'))
            fieldtext = battext(strfind(battext,'double play'):pos+posend-1);
            poct = poct+2;
            tos = strfind(fieldtext,' to ');
            tas_str{n} = [tas_str{n},'DP '];

            for k=1:length(tos)
                asstct = asstct+1;
                assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
            end
            putouts(n,poct-1) = 2;
            putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);   
            tas_str{n} = [tas_str{n},'',num2str(putouts(n,poct)),' '];
            outsOnPlay = outsOnPlay + 2;
            
        % if not (normal)
        else
            poct = poct + 1;
            putouts(n,poct) = 2;
            outsOnPlay = outsOnPlay + 1;
        end
                
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        battext = battext(pos+posend:end);
% F
    elseif(strfind(battext,'flied out to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'flied out to ');
        
        poct = poct+1;
        putouts(n,poct) = parse_pos(battext(pos+12:min(length(battext),pos+14)),n);   
        tas_str{n} = [tas_str{n},'F',num2str(putouts(n,poct)),' '];
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;     
        is_bat(n) = true;   
        hit_type{n} = 'F';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+16:end);
% P
    elseif(strfind(battext,'popped up to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'popped up to ');
        
        poct = poct+1;
        putouts(n,poct) = parse_pos(battext(pos+12:min(length(battext),pos+14)),n);   
        tas_str{n} = [tas_str{n},'P',num2str(putouts(n,poct)),' '];
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;        
        is_bat(n) = true;
        hit_type{n} = 'P';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+15:end);
% L
    elseif(strfind(battext,'lined out to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'lined out to ');
        
        poct = poct+1;
        putouts(n,poct) = parse_pos(battext(pos+12:min(length(battext),pos+14)),n);   
        tas_str{n} = [tas_str{n},'L',num2str(putouts(n,poct)),' '];
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;   
        is_bat(n) = true;     
        hit_type{n} = 'L';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+16:end);
% FF
    elseif(strfind(battext,'fouled out to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'fouled out to ');
        
        poct = poct+1;
        putouts(n,poct) = parse_pos(battext(pos+13:min(pos+15,length(battext))),n);   
        tas_str{n} = [tas_str{n},'FF',num2str(putouts(n,poct)),' '];
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;      
        is_bat(n) = true;  
        hit_type{n} = 'FF';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+16:end);
% G
    elseif(strfind(battext,'grounded out to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'grounded out to ');
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+13:pos+posend-1);
        
        if(strfind(fieldtext,'unassisted'))
            poct = poct+1;
            putouts(n,poct) = parse_pos(battext(pos+16:min(pos+17,length(battext))),n);   
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            asstct = asstct+1;
            assists(n,asstct) = parse_pos(battext(pos+16:min(pos+17,length(battext))),n);   
            poct = poct+1;
            putouts(n,poct) = 3;

            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-3 '];
        end
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;        
        is_bat(n) = true;
        hit_type{n} = 'G';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+posend:end);    
    elseif(~isempty(strfind(battext,'out at first ')) && isempty(strfind(battext,'picked off')) && isempty(strfind(battext,'reached on a fielder''s choice')))
        event_cd(n) = 2;
        pos = strfind(battext,'out at first ');
        pitches{n} = [pitches{n}, 'X'];
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+13:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        for k=1:length(tos)
            asstct = asstct+1;
            assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
        end
        poct = poct+1;
        if(strfind(fieldtext,'unassisted'))
            %ua = strfind(fieldtext,'unassisted');
            putouts(n,poct) = parse_pos(fieldtext(1:min(3,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        elseif(isempty(tos))    % unassisted but weird
            putouts(n,poct) = parse_pos(fieldtext(1:min(3,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;        
        is_bat(n) = true;
        hit_type{n} = 'G';

        batName{n} = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strfind(batName{n},newRun{ii}))
                batName{n} = newRun{ii};
                newRun{ii} = '';
                is_bat(n) = false;
                is_ab(n) = false;
                is_pa(n) = false;
            end
        end
        
        battext = battext(pos+posend:end);    
    elseif(~isempty(strfind(battext,'out at first ')) && ~isempty(strfind(battext,'picked off')))
        event_cd(n) = 8;
        %pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'out at first ');
        pos2 = max(strfind(battext,'out at first '),strfind(battext,'picked off'));
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+13:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        batName{n} = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strfind(batName{n},newRun{ii}))
                batName{n} = newRun{ii};
                newRun{ii} = '';
            end
        end
        
        if(battext(1) == '/' || battext(1) == ',')
            newRun{1} = '';
        end
        
        tas_str{n} = [tas_str{n},'PK '];
        for k=1:length(tos)
            asstct = asstct+1;
            assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
        end
        poct = poct+1;
        if(strfind(fieldtext,'unassisted'))
            %ua = strfind(fieldtext,'unassisted');
            putouts(n,poct) = parse_pos(fieldtext(1:min(3,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        elseif(isempty(tos))    % unassisted but weird
            putouts(n,poct) = parse_pos(fieldtext(1:min(3,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 1;
        
        if(~isempty(strfind(battext,'reached on an error')) || ~isempty(strfind(tmptext,'singled')))
            event_cd(n) = 7;
            pitches{n} = [pitches{n}, 'X'];
            is_bip(n) = true;
            is_pa(n) = true;
            is_ab(n) = true;        
            is_bat(n) = true;
            hit_type{n} = 'G';
            battext = '';
        else
            is_pa(n) = false;
            is_ab(n) = false;        
            is_bat(n) = false;
            %hit_type{n} = 'G';
            battext = battext(pos+posend:end);    
        end

% 1B
    elseif(strfind(battext,'singled'))
        event_cd(n) = 20;
        pitches{n} = [pitches{n}, 'X'];
        tas_str{n} = [tas_str{n},'1B '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;
        hit_cd(n) = 1;
        
        pos = strfind(battext,'singled');
        
        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+8:end);
        newRun{1} = batName{n};
% 2B
    elseif(strfind(battext,'doubled'))
        event_cd(n) = 21;
        pitches{n} = [pitches{n}, 'X'];
        tas_str{n} = [tas_str{n},'2B '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;
        hit_cd(n) = 2;
        
        pos = strfind(battext,'doubled');
        
        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+8:end);
        newRun{2} = batName{n};
% 3B
    elseif(strfind(battext,'tripled'))
        event_cd(n) = 22;
        pitches{n} = [pitches{n}, 'X'];
        tas_str{n} = [tas_str{n},'3B '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;
        hit_cd(n) = 3;
        
        pos = strfind(battext,'tripled');
        
        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+8:end);
        newRun{3} = batName{n};
% HR
    elseif(strfind(battext,'homered'))
        event_cd(n) = 23;
        pitches{n} = [pitches{n}, 'X'];
        tas_str{n} = [tas_str{n},'HR '];
        hit_cd(n) = 4;
        
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;
        
        pos = strfind(battext,'homered');
        
        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+8:end);

% E
    elseif(~isempty(strfind(battext,'reached on an error by ')) ||~isempty(strfind(battext,'reached first on an error by ')))
        event_cd(n) = 18;
        
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'reached ');
        bypos = strfind(battext(pos:end),'by ');
        
        errct = errct+1;
        errors(n,errct) = parse_pos(battext(pos+bypos+2:min(pos+bypos+3,length(battext))),n);
        errtype{n,errct} = 'X';
        tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),' '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+bypos+4:end);
        newRun{1} = batName{n};
    elseif(~isempty(strfind(battext,'reached on a fielding error by ')) || ~isempty(strfind(battext,'reached first on a fielding error by ')))
        event_cd(n) = 18;
        
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'reached ');
        bypos = strfind(battext(pos:end),'by ');
        
        errct = errct+1;
        errors(n,errct) = parse_pos(battext(pos+bypos+2:min(length(battext),pos+bypos+3)),n);
        errtype{n,errct} = 'F';
        tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'F '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+bypos+4:end);
        newRun{1} = batName{n};
    elseif(~isempty(strfind(battext,'reached on a throwing error by ')) || ~isempty(strfind(battext,'reached first on a throwing error by ')))
        event_cd(n) = 18;
        
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'reached ');
        bypos = strfind(battext(pos:end),'by ');
        
        errct = errct+1;
        errors(n,errct) = parse_pos(battext(pos+bypos+2:min(pos+bypos+3,length(battext))),n);
        errtype{n,errct} = 'T';
        tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'T '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+bypos+4:end);
        newRun{1} = batName{n};
    elseif(~isempty(strfind(battext,'reached on a dropped fly by ')) || ~isempty(strfind(battext,'reached first on a dropped fly by ')))
        event_cd(n) = 18;
        
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'reached ');
        bypos = strfind(battext(pos:end),'by ');
        
        errct = errct+1;
        errors(n,errct) = parse_pos(battext(pos+bypos+2:min(length(battext),pos+bypos+3)),n);
        errtype{n,errct} = 'DF';
        tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'DF '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+bypos+4:end);
        newRun{1} = batName{n};
    elseif(~isempty(strfind(battext,'reached on a muffed throw by ')) || ~isempty(strfind(battext,'reached first on a muffed throw by ')))
        event_cd(n) = 18;
        
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'reached ');
        bypos = strfind(battext(pos:end),'by ');
        
        errct = errct+1;
        errors(n,errct) = parse_pos(battext(pos+bypos+2:min(length(battext),pos+bypos+3)),n);
        errtype{n,errct} = 'MT';
        tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'MT '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+bypos+4:end);
        newRun{1} = batName{n};
% FC
    elseif(strfind(battext,'reached on a fielder''s choice'))
        event_cd(n) = 19;
        pitches{n} = [pitches{n}, 'X'];
        tas_str{n} = [tas_str{n},'FC '];
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;
        is_bat(n) = true;
        
        pos = strfind(battext,'reached on a fielder''s choice');

        % sometimes the info about how the runner got putout is mistakenly 
        % embedded here
        pos0 = pos;
        if(strfind(battext(pos:end),'grounded out'))
            fprintf('FC/GO info together at line %i...',n);
        elseif(strfind(battext(pos:end),'double play'))
            fprintf('FC/DP info together at line %i...',n);
        elseif(~isempty(strfind(battext,'out at first')) && ~isempty(strfind(tmptext,'out on the play')))
            pos0 = strfind(battext,'out at first');
            fprintf('FC/GO info together at line %i...',n);
            outsOnPlay = outsOnPlay+1;
        end
        
        if(~isempty(newRun{1}))
            if(~isempty(newRun{2}))
                if(~isempty(newRun{3}))
                    newRun{3} = newRun{2};
                    newRun{2} = newRun{1};
                else                    
                    newRun{3} = newRun{2};
                    newRun{2} = newRun{1};
                end
            else
                newRun{2} = newRun{1};
            end
        end
        
        batName{n} = strtrim(battext(1:pos0-1));
        battext = battext(pos+30:end);
        newRun{1} = batName{n};
% DP
    elseif(strfind(battext,' double play'))
        event_cd(n) = 2;
        % grounded
        pitches{n} = [pitches{n}, 'X'];
        if(strfind(battext,'grounded'))
            pos = strfind(battext,'grounded');
            tas_str{n} = [tas_str{n}, 'GDP '];
            hit_type{n} = 'G';
        % lined
        elseif(strfind(battext,'lined'))
            pos = strfind(battext,'lined');
            tas_str{n} = [tas_str{n}, 'LDP '];
            hit_type{n} = 'L';
        % flied
        elseif(strfind(battext,'flied'))
            pos = strfind(battext,'flied');
            tas_str{n} = [tas_str{n}, 'FDP '];
            hit_type{n} = 'F';
        % popped
        elseif(strfind(battext,'popped'))
            pos = strfind(battext,'popped');
            tas_str{n} = [tas_str{n}, 'PDP '];
            hit_type{n} = 'P';
        % bunted?!
        elseif(strfind(battext,'bunt'))
            pos = strfind(battext,'hit into double play');
            tas_str{n} = [tas_str{n}, 'BDP '];
            hit_type{n} = 'B';
            is_bunt(n) = true;
        % fouled (c'mon, man)
        elseif(strfind(battext,'fouled'))
            pos = strfind(battext,'fouled');
            tas_str{n} = [tas_str{n}, 'FFDP '];
            hit_type{n} = 'FF';
        % just generally out
        elseif(strfind(battext,'out on double play'))
            pos = strfind(battext,'out on double play');
            tas_str{n} = [tas_str{n}, 'DP '];
            hit_type{n} = 'X';
        elseif(strfind(battext,'hit into double play'))
            pos = strfind(battext,'hit into double play');
            tas_str{n} = [tas_str{n}, 'DP '];
            hit_type{n} = 'X';
        end
        
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+13:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        
        if(strfind(fieldtext,'unassisted'))
            ua = strfind(fieldtext,' unassisted');
            poct = poct+2;
            putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
            putouts(n,poct-1) = putouts(n,poct);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        elseif(isempty(tos))    % unassisted, but not telling me
            play_loc = strfind(fieldtext,' play');
            poct = poct+2;
            putouts(n,poct) = parse_pos(fieldtext(play_loc+5:play_loc+7),n);
            putouts(n,poct-1) = putouts(n,poct);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            k = 0;
            if(length(tos) > 1)
                for k=1:length(tos)-1
                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                    tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                end
            end

            % penultimate fielder gets both an assist and a putout (sort of
            % arbitrarily, but what do you want from me?)
            asstct = asstct+1;
            poct = poct+1;
            assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);   
            putouts(n,poct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);
            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
            
            % last fielder just gets a putout
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(tos(k+1)+2:end),n);            
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 2;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;        
        is_bat(n) = true;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+posend:end);
            
% TP
    elseif(strfind(battext,' triple play'))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        % grounded
        if(strfind(battext,'grounded'))
            pos = strfind(battext,'grounded');
            tas_str{n} = [tas_str{n}, 'GTP '];
            hit_type{n} = 'G';
            asst_to_first = 1;
        % lined
        elseif(strfind(battext,'lined'))
            pos = strfind(battext,'lined');
            tas_str{n} = [tas_str{n}, 'LTP '];
            hit_type{n} = 'L';
            asst_to_first = 1;
        % flied
        elseif(strfind(battext,'flied'))
            pos = strfind(battext,'flied');
            tas_str{n} = [tas_str{n}, 'FTP '];
            hit_type{n} = 'F';
            asst_to_first = 0;
        % popped
        elseif(strfind(battext,'popped'))
            pos = strfind(battext,'popped');
            tas_str{n} = [tas_str{n}, 'PTP '];
            hit_type{n} = 'P';
            asst_to_first = 0;
        % bunted?!
        elseif(strfind(battext,'bunt'))
            pos = strfind(battext,'bunt');
            tas_str{n} = [tas_str{n}, 'BTP '];
            hit_type{n} = 'B';
            is_bunt(n) = true;
            asst_to_first = 1;
        % just generally out
        elseif(strfind(battext,'hit into triple play'))
            pos = strfind(battext,'hit into triple play');
            tas_str{n} = [tas_str{n}, 'TP '];
            hit_type{n} = 'X';
            asst_to_first = 1;
        end
        
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+13:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        
        if(strfind(fieldtext,'unassisted'))
            ua = strfind(fieldtext,' unassisted');
            poct = poct+2;
            putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
            putouts(n,poct-1) = putouts(n,poct);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            k = 0;
            if(length(tos) > 2)
                for k=1:length(tos)-2
                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                    tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                end
                poct = poct+1;
                if(asst_to_first == 0)
                    putouts(n,poct) = parse_pos(fieldtext(max(1,tos(1)-2):tos(1)),n);
                else
                    putouts(n,poct) = parse_pos(fieldtext(max(k,tos(k)-2):tos(k)),n);
                end
            end

            % penultimate fielder gets both an assist and a putout (sort of
            % arbitrarily, but what do you want from me?)
            asstct = asstct+1;
            poct = poct+1;
            assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);   
            putouts(n,poct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);
            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
            
            % last fielder just gets a putout
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(tos(k+1)+2:end),n);            
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = 3;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;       
        is_bat(n) = true; 

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+posend:end);
% IF
    elseif(strfind(battext,'infield fly to '))
        event_cd(n) = 2;
        pitches{n} = [pitches{n}, 'X'];
        pos = strfind(battext,'infield fly to ');
        
        poct = poct+1;
        putouts(n,poct) = parse_pos(battext(pos+15:min(pos+17,length(battext))),n);   
        tas_str{n} = [tas_str{n},'P',num2str(putouts(n,poct)),' IF '];
        outsOnPlay = outsOnPlay + 1;
        
        is_bip(n) = true;
        is_pa(n) = true;
        is_ab(n) = true;        
        is_bat(n) = true;
        hit_type{n} = 'P';

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+18:end);
% runner out on basepaths
    elseif(~isempty(strfind(battext,'out at second')) || ~isempty(strfind(battext,'out at third')) || ~isempty(strfind(battext,'out at home')))
        event_cd(n) = 2;
        if(strfind(battext,'out at second'))
            pos = strfind(battext,'out at second');
        elseif(strfind(battext,'out at third'))
            pos = strfind(battext,'out at third');
        elseif(strfind(battext,'out at home'))
            pos = strfind(battext,'out at home');
        end
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+12:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        batName{n} = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strfind(batName{n},newRun{ii}))
                batName{n} = newRun{ii};
                newRun{ii} = '';
            end
        end
                 
        if(battext(1) == '/' || battext(1) == ',')
            if(outat < 4)
                newRun{outat} = '';
            end
        end
        
        for k=1:length(tos)
            asstct = asstct+1;
            assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
            tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
        end
        poct = poct+1;
        if(strfind(fieldtext,'unassisted'))
            %ua = strfind(fieldtext,'unassisted');
            putouts(n,poct) = parse_pos(fieldtext(1:min(4,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        elseif(isempty(tos))    % unassisted but weird
            putouts(n,poct) = parse_pos(fieldtext(1:min(4,length(fieldtext))),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
        else
            putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 1;
        
        is_pa(n) = false;
        is_ab(n) = false;        
        is_bat(n) = false;

        batName{n} = strtrim(battext(1:pos-1));
        battext = battext(pos+posend:end);
% SB
    elseif(strfind(battext,'stole'))
        event_cd(n) = 4;
        pos = strfind(battext,'stole');
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        
        batName{n} = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strcmp(newRun{ii},batName{n}))
                newRun{ii} = '';
            end
        end
        
        sb_fl(n) = sb_fl(n)+1;
        
        if(strfind(battext,' second, stole third, stole home'))  % so badass my eyes are bleeding
            tas_str{n} = [tas_str{n},'+2 SB +3 SB '];
            runsOnPlay = runsOnPlay+1;
            newBase = 4;
            sb_fl(n) = sb_fl(n)+2;
        elseif(strfind(battext,' second, stole third')) % badass
            tas_str{n} = [tas_str{n},'+2 SB '];
            newRun{3} = batName{n};
            newBase = 3;
            sb_fl(n) = sb_fl(n)+1;
        elseif(strfind(battext,' third, stole home')) % even badasser
            tas_str{n} = [tas_str{n},'+3 SB '];
            runsOnPlay = runsOnPlay+1;
            newBase = 4;
            sb_fl(n) = sb_fl(n)+1;
        elseif(strfind(battext,' second'))
            newRun{2} = batName{n};
            newBase = 2;
        elseif(strfind(battext,' third'))
            newRun{3} = batName{n};
            newBase = 3;
        elseif(strfind(battext,' home'))
            runsOnPlay = runsOnPlay+1;
            newBase = 4;
        end
        
        tas_str{n} = [tas_str{n},'+',num2str(newBase),' SB '];
        
        is_pa(n) = false;
        is_ab(n) = false;        
        battext = battext(pos+posend(1):end);
        
% CS
    elseif(~isempty(strfind(battext,'caught stealing')) && isempty(strfind(battext,'advanced')))
        event_cd(n) = 6;
        pos = strfind(battext,'out at');
        
        runNameTmp = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strcmp(newRun{ii},runNameTmp))
                newRun{ii} = '';
            end
        end
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+10:pos+posend-1);
        tos = strfind(fieldtext,' to ');
        
        cs_fl(n) = cs_fl(n) +1;
        
        if(strfind(fieldtext,'unassisted'))
            ua = strfind(fieldtext,' unassisted');
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
            tas_str{n} = [tas_str{n},'CS ',num2str(putouts(n,poct)),'U '];
        else
            k = 0;
            tas_str{n} = [tas_str{n},'CS '];
            %if(length(tos) > 1)
                for k=1:length(tos)
                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                    tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                end
            %end
            
            % last fielder gets a putout
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);            
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 1;
        
        is_pa(n) = false;
        is_ab(n) = false;        

        battext = battext(pos+posend(2):end);
        
% PK
    elseif(~isempty(strfind(battext,'picked off')) && isempty(strfind(battext,'advanced')))
        event_cd(n) = 8;
        pos = strfind(battext,'out at');
        pos0 = strfind(battext,'picked off');
        
        runNameTmp = strtrim(battext(1:pos-1));
        pk_fl(n) = pk_fl(n) + 1;
        % remove runner from bases
        for ii=3:-1:1,
            if(strcmp(newRun{ii},runNameTmp))
                newRun{ii} = '';
            end
        end
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        fieldtext = battext(pos+10:pos+posend-1);
        tos = strfind(fieldtext,' to ');

        if(isempty(fieldtext))
            %fprintf('*~*Warning: Weird entry at line %i: %s\n',n,tmptext);
            tas_str{n} = [tas_str{n},'COMMENT: ',battext];
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        end
        
        if(strfind(fieldtext,'unassisted'))
            ua = strfind(fieldtext,' unassisted');
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
            tas_str{n} = [tas_str{n},'PK ',num2str(putouts(n,poct)),'U '];
        else
            k = 0;
            tas_str{n} = [tas_str{n},'PK '];
            if(length(tos) > 1)
                for k=1:length(tos)
                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                    tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                end
            end
            
            % last fielder gets a putout
            poct = poct+1;
            putouts(n,poct) = parse_pos(fieldtext(tos(end)+2:end),n);            
            tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
        end
        
        outsOnPlay = outsOnPlay + 1;
        
        is_pa(n) = false;
        is_ab(n) = false;        

        battext = [battext(pos+posend(2):pos0),battext(pos0+10:end)];
% PB/WP/BK (not a PA)
    elseif((~isempty(strfind(battext,'advanced')) || ~isempty(strfind(battext,'scored'))) && isempty(tas_str{n}))
        if(strfind(battext,'advanced'))
            pos = strfind(battext,'advanced');
        else
            pos = strfind(battext,'scored');
        end
        
        posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
        posend = sort(posend);
        
        batName{n} = strtrim(battext(1:pos-1));
        % remove runner from bases
        for ii=3:-1:1,
            if(strfind(batName{n},newRun{ii}))
                batName{n} = newRun{ii};
                newRun{ii} = '';
            end
        end
                
        if(strfind(battext,'to second'))
            newRun{2} = batName{n};
            newBase = 2;
        elseif(strfind(battext,'to third'))
            newRun{3} = batName{n};
            newBase = 3;
        elseif(strfind(battext,'scored'))
            newBase = 4;
        end
        if(strfind(tmptext,'wild pitch'))
            event_cd(n) = 9;
            tas_str{n} = [tas_str{n},'+',num2str(newBase),' WP '];
        elseif(strfind(tmptext,'passed ball'))
            event_cd(n) = 10;
            tas_str{n} = [tas_str{n},'+',num2str(newBase),' PB '];
        elseif(strfind(tmptext,'balk'))
            event_cd(n) = 11;
            tas_str{n} = [tas_str{n},'+',num2str(newBase),' BK ']; 
        elseif(strfind(tmptext,'throwing error'))
            event_cd(n) = 12;
            pos3 = strfind(tmptext,'throwing error');
            bypos = strfind(tmptext(pos3:end),'by ');

            errtmp = parse_pos(tmptext(pos3+bypos+2:pos3+bypos+3),n);
            tas_str{n} = [tas_str{n},'+',num2str(newBase),' E',num2str(errtmp),'T '];   
        elseif(strfind(tmptext,'fielding error'))
            event_cd(n) = 12;
            pos3 = strfind(tmptext,'fielding error');
            bypos = strfind(tmptext(pos3:end),'by ');

            errtmp = parse_pos(tmptext(pos3+bypos+2:pos3+bypos+3),n);
            tas_str{n} = [tas_str{n},'+',num2str(newBase),' E',num2str(errtmp),'F '];   
        elseif(strfind(tmptext,'error'))
            event_cd(n) = 12;
            pos3 = strfind(tmptext,'error');
            bypos = strfind(tmptext(pos3:end),'by ');
            
            if(isempty(bypos))
                tas_str{n} = [tas_str{n},'+',num2str(newBase),' E?'];             
            else
                errtmp = parse_pos(tmptext(pos3(1)+bypos(1)+2:pos3(1)+bypos(1)+3),n);
                tas_str{n} = [tas_str{n},'+',num2str(newBase),' E',num2str(errtmp),'O '];             
            end
        elseif(strfind(tmptext,'caught stealing'))
            event_cd(n) = 6;
            tas_str{n} = [tas_str{n},'+',num2str(newBase), ' CS '];
        elseif(strfind(tmptext,'muffed throw')) % I promise you this shows up at least once.
            event_cd(n) = 12;
            pos3 = strfind(tmptext,'muffed throw');
            bypos = strfind(tmptext(pos3:end),'by ');

            errct = errct+1;
            errors(n,errct) = parse_pos(tmptext(pos3+bypos+2:pos3+bypos+3),n);
            errtype{n,errct} = 'MT';

            tas_str{n} = [tas_str{n},'+',num2str(newBase),' E',num2str(errtmp),' MT ']; 
            
%             if(strfind(tmptext,'assist by'))
%                 pos4 = strfind(tmptext,'assist by');
%                 bypos = strfind(tmptext(pos4:end),'by');
%                 
%                 asstct = asstct+1;
%                 assists(n,asstct) = parse_pos(tmptext(pos4+bypos+2:min(length(tmptext),pos4+bypos+5)),n);   
%                 tas_str{n} = [tas_str{n},'A',num2str(assists(n,asstct)),' '];
%             end  
        elseif(strfind(tmptext,'stolen base'))
            event_cd(n) = 4;
            tas_str{n} = [tas_str{n},'+',num2str(newBase), 'T SB '];            
        elseif(strfind(tmptext,'fielder''s choice'))
            event_cd(n) = 12;
            tas_str{n} = [tas_str{n},'+',num2str(newBase), 'T FC '];            
        elseif(strfind(tmptext,'failed pickoff'))
            event_cd(n) = 7;
            tas_str{n} = [tas_str{n},'+',num2str(newBase), 'T FPO '];
        else
            event_cd(n) = 12;
            tas_str{n} = [tas_str{n},'+',num2str(newBase),'? '];
            %fprintf('~*~Warning: unusual text on line %i: %s\n',n,battext);
        end
        
        is_pa(n) = false;
        is_ab(n) = false;        
        battext = battext(pos+posend(1):end);
    elseif(strfind(battext,'Dropped foul ball'))
        
        event_cd(n) = 13;
        err_loc = strfind(battext,', E');
        
        errct = errct + 1;
        errors(n,errct) = str2double(battext(err_loc+3));
        errtype{n,errct} = 'DF';
            
        tas_str{n} = [tas_str{n}, 'DF E',num2str(errors(n,errct))];
        battext = '';
%% SUBSTITUTIONS
    else
        event_cd(n) = 1;
        to_loc = strfind(battext,' to ');
        for_loc = strfind(battext,' for ');
        ph = strfind(battext,' pinch hit ');
        pr = strfind(battext,' pinch ran ');
        slash = strfind(battext,'/');
        
        numwords = length(strfind(battext,' '))+1;
        
        if((isempty(to_loc) && isempty(for_loc)) || numwords >= 9)   % arbitrary limit: anything over 9 words is probably a comment, not a substitution.
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        end
        
        if(strfind(battext,'Pitching coach'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'Pitching Coach'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'Manager'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'Head coach'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'Head Coach'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'ejected'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;
        elseif(strfind(battext,'Visit to the mound'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;    
        elseif(strfind(battext,'rain'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;    
        elseif(strfind(battext,'weather'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;    
        elseif(strfind(battext,'lightning'))
            tas_str{n} = ['COMMENT: ',battext];
            battext = '';
            outs_end(n) = outs_end(n-1);
            base_end(n) = base_end(n-1);
            continue;    
        end
        
        if(~isempty(to_loc) && ~isempty(for_loc))
            sub_cell{n,1} = strtrim(battext(1:to_loc-1));   % sub in
            sub_cell{n,2} = parse_pos(battext(to_loc+1:for_loc-1),n); % sub pos
            sub_cell{n,3} = strtrim(battext(for_loc+4:end-1));   % sub out
            
            % swap old runner for new runner on bases...just in case
            for ii=3:-1:1,
                if(strcmp(newRun{ii},sub_cell{n,3}))
                    newRun{ii} = sub_cell{n,1};
                end
            end
        elseif(~isempty(ph))
            sub_cell{n,1} = strtrim(battext(1:ph-1));   % sub in
            sub_cell{n,2} = 11; % sub pos 11 = PH
            sub_cell{n,3} = strtrim(battext(ph+14:end-1));   % sub out
            
            % swap old runner for new runner on bases  -- I SWEAR THIS HAPPENS
            for ii=3:-1:1,
                if(strcmp(newRun{ii},sub_cell{n,3}))
                    newRun{ii} = sub_cell{n,1};
                end
            end
        elseif(~isempty(pr))
            sub_cell{n,1} = strtrim(battext(1:pr-1));   % sub in
            sub_cell{n,2} = 12; % sub pos 12 = PR
            sub_cell{n,3} = strtrim(battext(pr+14:end-1));   % sub out
            
            % swap old runner for new runner on bases
            for ii=3:-1:1,
                if(strcmp(newRun{ii},sub_cell{n,3}))
                    newRun{ii} = sub_cell{n,1};
                end
            end
        elseif(~isempty(slash))
%             sub_cell{n,1} = strtrim(battext(1:to_loc-1));   % sub in
            sub_cell{n,2} = -1; % sub pos
            sub_cell{n,3} = strtrim(battext(for_loc+4:end-1));   % sub out            
        elseif(~isempty(to_loc) && isempty(for_loc))
            sub_cell{n,1} = strtrim(battext(1:to_loc-1));   % sub in
            sub_cell{n,2} = parse_pos(battext(to_loc+1:end),n); % sub pos
            %sub_cell{n,3} = strtrim(battext(for_loc+4:end-1));   % sub out            
        end
        
        tas_str{n} = 'sub';
        battext = '';
    end
    
    for t=1:3,      % go through everything 3 times, in case there's multiple stuff on the end.
    % SAC
        if(strfind(battext,'SAC'))
            pos = strfind(battext,'SAC');
            posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
            posend = sort(posend);

            is_sh(n) = true;

            is_pa(n) = false;
            is_ab(n) = false;

            tas_str{n} = [tas_str{n},'SAC '];

            sac_loc = find(pos < posend,1);
            if(sac_loc == 1)
                battext = battext(pos+posend(sac_loc):end);
            else
                battext = [battext(1:pos+posend(sac_loc-1)),battext(pos+posend(sac_loc):end)];
            end
        % SF
        elseif(strfind(battext,'SF'))
            pos = strfind(battext,'SF');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            is_sf(n) = true;

            is_pa(n) = false;
            is_ab(n) = false;

            tas_str{n} = [tas_str{n},'SF '];

            sac_loc = find(pos < posend,1);
            if(sac_loc == 1)
                battext = battext(posend(sac_loc)+1:end);
            else
                battext = [battext(1:posend(sac_loc-1)),battext(posend(sac_loc)+1:end)];
            end
        elseif(strfind(battext,'sacrifice fly'))
            pos = strfind(battext,'sacrifice fly');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            is_sf(n) = true;

            is_pa(n) = false;
            is_ab(n) = false;

            tas_str{n} = [tas_str{n},'SF '];

            sac_loc = find(pos < posend,1);
            if(sac_loc == 1)
                battext = battext(posend(sac_loc)+1:end);
            else
                battext = [battext(1:posend(sac_loc-1)),battext(posend(sac_loc)+1:end)];
            end
        end

        % out advancing
        if(strfind(battext,'out at '))
            pos = strfind(battext,'out at');
            posend = [strfind(battext(pos:end),';'),strfind(battext(pos:end),':'),strfind(battext(pos:end),'.'),strfind(battext(pos:end),','),length(battext(pos:end))];
            posend = sort(posend);

            if(strfind(battext,'at first'))
                where_out = 1;
            elseif(strfind(battext,'at second'))
                where_out = 2;
            elseif(strfind(battext,'at third'))
                where_out = 3;
            elseif(strfind(battext,'at home'))
                where_out = 4;
            end

            % remove runner from bases
            for ii=3:-1:1,
                if(strcmp(newRun{ii},batName{n}))
                    newRun{ii} = '';
                end
            end

            % credit for assists/putouts
            fieldtext = battext(pos+11:pos+posend(1)-1);
            tos = strfind(fieldtext,' to ');

            if(strfind(fieldtext,'unassisted'))
                ua = strfind(fieldtext,' unassisted');
                poct = poct+1;
                putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
                tas_str{n} = [tas_str{n},'OA',num2str(where_out),' ',num2str(putouts(n,poct)),'U '];
            elseif(isempty(tos))
                poct = poct+1;
                putouts(n,poct) = parse_pos(fieldtext(end-2:end),n);
                tas_str{n} = [tas_str{n},'OA',num2str(where_out),' ',num2str(putouts(n,poct)),'U '];
            else
                k = 0;
                tas_str{n} = [tas_str{n},'OA',num2str(where_out),' '];
                %if(length(tos) > 1)
                    for k=1:length(tos)
                        asstct = asstct+1;
                        assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                        tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                    end
                %end

                % last fielder gets a putout
                poct = poct+1;
                putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);            
                tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
            end

            outsOnPlay = outsOnPlay + 1;

            out_loc = find(pos < posend,1);
            if(out_loc == 1)
                battext = battext(pos+posend(out_loc):end);
            else
                battext = [battext(1:pos+posend(out_loc-1)),battext(pos+posend(out_loc):end)];
            end

        elseif(strfind(battext,'out on the play'))
            % usually means the actual out text is somewhere else, so just make
            % sure the runner is gone and add to the string
            pos = strfind(battext,'out on the play');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            % remove runner from bases
            for ii=3:-1:1,
                if(strcmp(newRun{ii},batName{n}))
                    newRun{ii} = '';
                end
            end
            
            tas_str{n} = [tas_str{n},'X'];
            out_loc = find(pos < posend,1);
            if(out_loc == 1)
                battext = battext(pos+posend(out_loc):end);
            else
                battext = [battext(1:pos+posend(out_loc-1)),battext(pos+posend(out_loc):end)];
            end
        % advancing
        elseif(strfind(battext,'advanced to '))
            pos = strfind(battext,'advanced to ');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            runNameTmp = batName{n};

            if(strfind(battext,'advanced to second'))
                newRun{2} = runNameTmp;
                newBase = 2;
            elseif(strfind(battext,'advanced to third'))
                newRun{3} = runNameTmp;
                newBase = 3;
            elseif(strfind(battext,'scored'))
                newBase = 4;
            end

            bct = 0;
            for ii=3:-1:1,
                if(strcmp(newRun{ii},batName{n}))
                    bct = bct+1;
                    if(bct >= 2)
                        newRun{ii} = '';
                    end
                end
            end

            tas_str{n} = [tas_str{n},'+',num2str(newBase),' '];

            % on error
            if(strfind(battext,'throwing error'))
                pos2 = strfind(battext,'throwing error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'T';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'T '];        
            elseif(strfind(battext,'fielding error'))
                pos2 = strfind(battext,'fielding error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'F';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'F '];
            elseif(strfind(battext,'on the error'))
                pos3 = strfind(tmptext,'on the error');
                bypos = strfind(tmptext(pos3(1):end),'by ');

                if(isempty(bypos))
                    tas_str{n} = [tas_str{n},'E '];
                else
                    errtmp = parse_pos(tmptext(pos3(1)+bypos+2:pos3(1)+bypos+3),n);
                    tas_str{n} = [tas_str{n},'E',num2str(errtmp),' '];
                end
            elseif(strfind(battext,'error'))
                bypos = strfind(battext(pos:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos+bypos+2:min(pos+bypos+3,length(battext))),n);
                errtype{n,errct} = 'X';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),' '];
            end

            adv_loc = find(pos(1) < posend,1);
            if(adv_loc == 1)
                battext = battext(posend(adv_loc)+1:end);
            else
                battext = [battext(1:posend(adv_loc-1)),battext(posend(adv_loc)+1:end)];
            end
        % advancing
        elseif(strfind(battext,'reached to '))
            pos = strfind(battext,'reached to ');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            runNameTmp = batName{n};

            if(strfind(battext,'reached to second'))
                newRun{2} = runNameTmp;
                newBase = 2;
            elseif(strfind(battext,'reached to third'))
                newRun{3} = runNameTmp;
                newBase = 3;
            elseif(strfind(battext,'scored'))
                newBase = 4;
            end

            bct = 0;
            for ii=3:-1:1,
                if(strcmp(newRun{ii},batName{n}))
                    bct = bct+1;
                    if(bct >= 2)
                        newRun{ii} = '';
                    end
                end
            end

            tas_str{n} = [tas_str{n},'+',num2str(newBase),' '];

            % on error
            if(strfind(battext,'throwing error'))
                pos2 = strfind(battext,'throwing error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'T';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'T '];        
            elseif(strfind(battext,'fielding error'))
                pos2 = strfind(battext,'fielding error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'F';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'F '];
            elseif(strfind(battext,'on the error'))
                pos3 = strfind(tmptext,'on the error');
                bypos = strfind(tmptext(pos3(1):end),'by ');

                if(isempty(bypos))
                    tas_str{n} = [tas_str{n},'E '];
                else
                    errtmp = parse_pos(tmptext(pos3(1)+bypos+2:pos3(1)+bypos+3),n);
                    tas_str{n} = [tas_str{n},'E',num2str(errtmp),' '];
                end
            elseif(strfind(battext,'error'))
                bypos = strfind(battext(pos:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos+bypos+2:min(pos+bypos+3,length(battext))),n);
                errtype{n,errct} = 'X';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),' '];
            end

            adv_loc = find(pos(1) < posend,1);
            if(adv_loc == 1)
                battext = battext(posend(adv_loc)+1:end);
            else
                battext = [battext(1:posend(adv_loc-1)),battext(posend(adv_loc)+1:end)];
            end
        % advancing
        elseif(strfind(battext,'scored'))
            pos = strfind(battext,'scored');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            runNameTmp = batName{n};
            newBase = 4;

            for ii=3:-1:1,
                if(strcmp(newRun{ii},batName{n}))
                    newRun{ii} = '';
                end
            end

            tas_str{n} = [tas_str{n},'+',num2str(newBase),' '];

            % on error
            if(strfind(battext,'throwing error'))
                pos2 = strfind(battext,'throwing error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'T';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'T '];        
            elseif(strfind(battext,'fielding error'))
                pos2 = strfind(battext,'fielding error');
                bypos = strfind(battext(pos2:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos2+bypos+2:min(pos2+bypos+3,length(battext))),n);
                errtype{n,errct} = 'F';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'F '];
            elseif(strfind(battext,'on the error'))
                pos3 = strfind(tmptext,'on the error');
                bypos = strfind(tmptext(pos3(1):end),'by ');

                if(isempty(bypos))
                    tas_str{n} = [tas_str{n},'E '];
                else
                    errtmp = parse_pos(tmptext(pos3(1)+bypos+2:pos3(1)+bypos+3),n);
                    tas_str{n} = [tas_str{n},'E',num2str(errtmp),' '];
                end
            elseif(strfind(battext,'error'))
                bypos = strfind(battext(pos:end),'by ');

                errct = errct+1;
                errors(n,errct) = parse_pos(battext(pos+bypos+2:min(pos+bypos+3,length(battext))),n);
                errtype{n,errct} = 'X';
                tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),' '];
            end

            adv_loc = find(pos(1) < posend,1);
            if(adv_loc == 1)
                battext = battext(posend(adv_loc)+1:end);
            else
                battext = [battext(1:posend(adv_loc-1)),battext(posend(adv_loc)+1:end)];
            end
        end

        % RBI
        if(strfind(battext,'RBI'))
            pos = strfind(battext,'RBI');
            posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
            posend = sort(posend);

            if(~isempty(strfind(battext,'2 RBI')) || ~isempty(strfind(battext,'3 RBI')) || ~isempty(strfind(battext,'4 RBI')))
                rbi(n) = str2double(battext(pos-2));
            else
                rbi(n) = 1;
            end

            if(length(pos) == 2)    % 2 RBI the dumb way
                rbi(n) = 2;
            elseif(length(pos) == 3)% 3 RBI
                rbi(n) = 3;
            elseif(length(pos) == 4) %4 RBI
                rbi(n) = 4;
            elseif(length(pos) > 4)
                fprintf('~*~Warning: 5+ RBI credited on line #%i!\n',n);
            end

            tas_str{n} = [tas_str{n},num2str(rbi(n)),'RBI '];

            battext = [battext(1:pos(1)-3),battext(pos(end)+3:end)];
        end
        if(strfind(battext,'team unearned'))
            pos = strfind(battext,'team unearned');

            tm_uer(n) = tm_uer(n) + 1;
            tas_str{n} = [tas_str{n},'TUE '];

            battext = [battext(1:pos-1),battext(pos+14:end)];       
        elseif(strfind(battext,'unearned'))
            pos = strfind(battext,'unearned');

            uer(n) = uer(n) + 1;
            tas_str{n} = [tas_str{n},'UE '];

            battext = [battext(1:pos-1),battext(pos+9:end)];
        end
        if(strfind(battext,'caught stealing'))
            pos = strfind(battext,'caught stealing');

            tas_str{n} = [tas_str{n},'CS '];
            cs_fl(n) = cs_fl(n)+1;
            
            is_bat(n) = false;
            
            % remove runner from bases
            if(outsOnPlay > 0)
                for ii=3:-1:1,
                    if(strcmp(newRun{ii},batName{n}))
                        newRun{ii} = '';
                    end
                end
            end

            battext = [battext(1:pos-1),battext(pos+16:end)];
        end
        if(strfind(battext,'interference'))
            pos = strfind(battext,'interference');

            tas_str{n} = [tas_str{n},'INT '];

            battext = [battext(1:pos-1),battext(pos+12:end)];
        end
        if(strfind(battext,'picked off'))
            pos = strfind(battext,'picked off');

            tas_str{n} = [tas_str{n},'PK '];
            pk_fl(n) = pk_fl(n)+1;

            % remove runner from bases
            if(outsOnPlay > 0)
                for ii=3:-1:1,
                    if(strcmp(newRun{ii},batName{n}))
                        newRun{ii} = '';
                    end
                end
            end

            is_pa(n) = false;
            is_ab(n) = false;
            is_bat(n) = false;
            battext = [battext(1:pos-1),battext(pos+10:end)];
        end
        if(strfind(tmptext,'failed pickoff attempt'))
            pos = strfind(battext,'failed pickoff attempt');

            tas_str{n} = [tas_str{n},'FPO '];

            if(isempty(pos))
                batName_tmp = batName{n};
                batName{n} = strtrim(batName_tmp(1:strfind(batName{n},'failed pickoff attempt')-1));
            end
            battext = [battext(1:pos-1),battext(pos+22:end)];
        end
        if(strfind(battext,'runner left early'))
            pos = strfind(battext,'runner left early');

            tas_str{n} = [tas_str{n},'RLE '];

            battext = [battext(1:pos-1),battext(pos+18:end)];
        end
        if(strfind(battext,'obstruction'))
            pos = strfind(battext,'obstruction');

            tas_str{n} = [tas_str{n},'OBS '];

            battext = [battext(1:pos-1),battext(pos+11:end)];
        end
        if(strfind(battext,'assist by'))
            pos = strfind(battext,'by');

            asstct = asstct+1;
            assists(n,asstct) = parse_pos(battext(pos+3:min(pos+5,length(battext))),n);   

            tas_str{n} = [tas_str{n},'A',num2str(assists(n,asstct)),' '];

            battext = [battext(1:pos-8),battext(pos+22:end)];
        end
    end
%% LOCATION CODES
    if(~isempty(battext))
        if(strfind(battext,'bunt'))
            pos = strfind(battext,'bunt');
            is_bunt(n) = true;
            hit_type{n} = 'B';
            
            tas_str{n} = [tas_str{n}, 'BU '];
            
            battext = [battext(1:pos-1),battext(pos+5:end)];
        end
        if(strfind(battext,' ground-rule'))
            pos = strfind(battext,' ground-rule');
            
            tas_str{n} = [tas_str{n}, 'GR '];
            
            battext = [battext(1:pos-1),battext(pos+12:end)];
        end
        if(strfind(battext,'inside the park'))
            pos = strfind(battext,'inside the park');
            
            tas_str{n} = [tas_str{n}, 'IP '];
            
            battext = [battext(1:pos-1),battext(pos+15:end)];
        end
    
        hitloc_tmp = '';
        hitloc_str = '';
        posend = [strfind(battext,';'),strfind(battext,':'),strfind(battext,'.'),strfind(battext,','),length(battext)];
        posend = sort(posend);
        if(strfind(battext,'to pitcher'))
            hitloc_str = 'to pitcher';
            hitloc_tmp = 'P';
        elseif(strfind(battext,'to catcher'))
            hitloc_str = 'to catcher';
            hitloc_tmp = 'C';
        elseif(strfind(battext,'to first base'))
            hitloc_str = 'to first base';
            hitloc_tmp = '1B';
        elseif(strfind(battext,'to second base'))
            hitloc_str = 'to second base';
            hitloc_tmp = '2B';
        elseif(strfind(battext,'to third base'))
            hitloc_str = 'to third base';
            hitloc_tmp = '3B';
        elseif(strfind(battext,'to shortstop'))
            hitloc_str = 'to shortstop';
            hitloc_tmp = 'SS';
        elseif(strfind(battext,'to left field'))
            hitloc_str = 'to left field';
            hitloc_tmp = 'LF';
        elseif(strfind(battext,'to center field'))
            hitloc_str = 'to center field';
            hitloc_tmp = 'CF';
        elseif(strfind(battext,'to right field'))
            hitloc_str = 'to right field';
            hitloc_tmp = 'RF';
        elseif(strfind(battext,'to left center'))
            hitloc_str = 'to left center';
            hitloc_tmp = 'LC';
        elseif(strfind(battext,'to right center'))
            hitloc_str = 'to right center';
            hitloc_tmp = 'RC';
        elseif(strfind(battext,'down the lf line'))
            hitloc_str = 'down the lf line';
            hitloc_tmp = 'LL';
        elseif(strfind(battext,'down the rf line'))
            hitloc_str = 'down the rf line';
            hitloc_tmp = 'RL';
        elseif(strfind(battext,'down the 1b line'))
            hitloc_str = 'down the 1b line';
            hitloc_tmp = '1BL';
        elseif(strfind(battext,'down the 3b line'))
            hitloc_str = 'down the 3b line';
            hitloc_tmp = '3BL';
        elseif(strfind(battext,'through the left side'))
            hitloc_str = 'through the left side';
            hitloc_tmp = 'LS';
        elseif(strfind(battext,'through the right side'))
            hitloc_str = 'through the right side';
            hitloc_tmp = 'RS';
        elseif(strfind(battext,'up the middle'))
            hitloc_str = 'up the middle';
            hitloc_tmp = 'MI';
        end
        
        if(~isempty(hitloc_str))
            hit_loc{n} = hitloc_tmp;
            tas_str{n} = [tas_str{n}, hitloc_tmp, ' '];
            
            pos = strfind(battext,hitloc_str);
            battext = [battext(1:pos-1),battext(pos+length(hitloc_str):end)];
        end
    end


%% RUNNER CODES
    for m=1:3,
        no_text = 1;
        if(~isempty(runtmp{m}))
            tas_str{n} = [tas_str{n},'; '];
            runNameTmp = '';
            runtxt = runtmp{m};
            for t=1:3,
                if(strfind(runtxt,'stole '))
                    no_text = 0;
                    pos = strfind(runtxt,'stole ');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    if(strfind(runtxt(pos:pos+punct(1)-1),'second'))
                        runPosTmp = 2;
                        baselen = strfind(runtxt(pos:pos+punct(1)-1),'second')+5;
                    elseif(strfind(runtxt(pos:pos+punct(1)-1),'third'))
                        if(strfind(runtxt,'advanced to second, stole third'))   % it comes up multiple times!
                            pos = strfind(runtxt,'advanced ');
                        end
                        runPosTmp = 3;
                        baselen = strfind(runtxt(pos:pos+punct(1)-1),'third')+4;
                    elseif(strfind(runtxt(pos:pos+punct(1)-1),'home'))
                        runPosTmp = 4;
                        runsOnPlay = runsOnPlay + 1;
                        baselen = strfind(runtxt(pos:pos+punct(1)-1),'home')+3;
                    end
                    
                    tas_str{n} = [tas_str{n},'+',num2str(runPosTmp), ' SB '];
                    
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runtxt = runtxt(pos+baselen:end);     
                elseif(strfind(runtxt,'advanced to second'))
                    no_text = 0;
                    pos = strfind(runtxt,'advanced to second');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'+2 '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 2;
                    runtxt = runtxt(pos+19:end);            
                elseif(strfind(runtxt,'advanced to third'))
                    no_text = 0;
                    pos = strfind(runtxt,'advanced to third');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'+3 '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 3;
                    runtxt = runtxt(pos+18:end);            
                elseif(strfind(runtxt,'scored'))
                    no_text = 0;
                    pos = strfind(runtxt,'scored');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'+4 '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 4;
                    runtxt = runtxt(pos+7:end);       
                elseif(strfind(runtxt,'out at'))
                    no_text = 0;
                    pos = strfind(runtxt,'out at');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    atpos = strfind(runtxt,' at ');
                    
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end

                    if(strfind(runtxt(atpos:pos+punct(1)-1),'second'))
                        outat = 2;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'second')+5;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'third'))
                        outat = 3;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'third')+4;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'home'))
                        outat = 4;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'home')+3;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'first'))
                        outat = 4;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'first')+4;
                    end
                    outsOnPlay = outsOnPlay + 1;

                    % remove runner from bases
                    runnerFound = 0;
                    for ii=3:-1:1,
                        if(strfind(runNameTmp,newRun{ii}))
                            newRun{ii} = '';
                            runnerFound = 1;
                        end
                    end
                    
                    if(~runnerFound && length(runNameTmp) < 2)
                        if(outat < 4)
                            newRun{outat} = '';
                        end
                    end

                    % credit for assists/putouts
                    fieldtext = runtxt(pos+11:pos+punct(1)-1);
                    tos = strfind(fieldtext,' to ');

                    if(strfind(fieldtext,'unassisted'))
                        ua = strfind(fieldtext,' unassisted');
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' ',num2str(putouts(n,poct)),'U '];
                    elseif(isempty(tos))
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(end-2:end),n);
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' ',num2str(putouts(n,poct)),'U '];
                    else
                        k = 0;
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' '];
                        %if(length(tos) > 1)
                            for k=1:length(tos)
                                asstct = asstct+1;
                                assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                                tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                            end
                        %end

                        % last fielder gets a putout
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);            
                        tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
                    end

                    out_loc = find(pos < punct(1),1);
                    
                    runtxt = runtxt(pos+punct(out_loc)+1:end);
                    
                    runPosTmp = 0;
                    %runtxt = runtxt(atpos+baselen:end);
                elseif(~isempty(strfind(runtxt,'out on the play')) && ~isempty(strfind(tmptext,'out at first')))
                    no_text = 0;
                    pos = strfind(runtxt,'out on the play');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    if(~isempty(strfind(tmptext,'batter''s interference')) || ~isempty(strfind(tmptext,'SF')) || ~isempty(strfind(tmptext,'SAC')))
                        if(isempty(strfind(tmptext,'double play')))
                            outsOnPlay = length(strfind(tmptext,' out '));
                        end
                    end

                    tas_str{n} = [tas_str{n},'X '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 0;
                    runtxt = runtxt(pos+16:end);     
                elseif(~isempty(strfind(runtxt,'out on the play')) && isempty(strfind(tmptext,'out at first')))
                    no_text = 0;
                    pos = strfind(runtxt,'out on the play');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    if(~isempty(strfind(tmptext,'batter''s interference')) || ~isempty(strfind(tmptext,'SF')) || ~isempty(strfind(tmptext,'SAC')))
                        if(isempty(strfind(tmptext,'double play')))
                            outsOnPlay = length(strfind(tmptext,' out '));
                        end
                    end

                    tas_str{n} = [tas_str{n},'X '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 0;
                    runtxt = runtxt(pos+16:end);     
                elseif(strfind(runtxt,'out at'))
                    no_text = 0;
                    pos = strfind(runtxt,'out at');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    atpos = strfind(runtxt,' at ');
                    
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end

                    if(strfind(runtxt(atpos:pos+punct(1)-1),'second'))
                        outat = 2;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'second')+5;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'third'))
                        outat = 3;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'third')+4;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'home'))
                        outat = 4;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'home')+3;
                    elseif(strfind(runtxt(atpos:pos+punct(1)-1),'first'))
                        outat = 4;
                        baselen = strfind(runtxt(atpos:pos+punct(1)-1),'first')+4;
                    end
                    outsOnPlay = outsOnPlay + 1;

                    % remove runner from bases
                    runnerFound = 0;
                    for ii=3:-1:1,
                        if(strfind(runNameTmp,newRun{ii}))
                            newRun{ii} = '';
                            runnerFound = 1;
                        end
                    end
                    
                    if(~runnerFound && length(runNameTmp) < 2)
                        if(outat < 4)
                            newRun{outat} = '';
                        end
                    end

                    % credit for assists/putouts
                    fieldtext = runtxt(pos+11:pos+punct(1)-1);
                    tos = strfind(fieldtext,' to ');

                    if(strfind(fieldtext,'unassisted'))
                        ua = strfind(fieldtext,' unassisted');
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' ',num2str(putouts(n,poct)),'U '];
                    elseif(isempty(tos))
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(end-2:end),n);
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' ',num2str(putouts(n,poct)),'U '];
                    else
                        k = 0;
                        tas_str{n} = [tas_str{n},'OA',num2str(outat),' '];
                        %if(length(tos) > 1)
                            for k=1:length(tos)
                                asstct = asstct+1;
                                assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                                tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                            end
                        %end

                        % last fielder gets a putout
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(tos(k)+2:end),n);            
                        tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
                    end

                    out_loc = find(pos < punct(1),1);
                    
                    runtxt = runtxt(pos+punct(out_loc)+1:end);
                    
                    runPosTmp = 0;
                    %runtxt = runtxt(atpos+baselen:end);
                elseif(strfind(runtxt,'out on double play'))
                    no_text = 0;
                    pos = strfind(runtxt,'out on double play');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    fieldtext = runtxt(pos+13:pos+punct-1);
                    tos = strfind(fieldtext,' to ');

                    tas_str{n} = [tas_str{n},'X DP '];
                    
                    if(strfind(fieldtext,'unassisted'))
                        ua = strfind(fieldtext,' unassisted');
                        poct = poct+2;
                        putouts(n,poct) = parse_pos(fieldtext(ua-2:ua),n);
                        putouts(n,poct-1) = putouts(n,poct);
                        tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
                    elseif(isempty(tos))    % unassisted, but not telling me
                        play_loc = strfind(fieldtext,' play');
                        poct = poct+2;
                        putouts(n,poct) = parse_pos(fieldtext(play_loc+5:play_loc+7),n);
                        putouts(n,poct-1) = putouts(n,poct);
                        tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),'U '];
                    else
                        k = 0;
                        if(length(tos) > 1)
                            for k=1:length(tos)-1
                                asstct = asstct+1;
                                assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k)-2):tos(k)),n);   
                                tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];
                            end
                        end

                        % penultimate fielder gets both an assist and a putout (sort of
                        % arbitrarily, but what do you want from me?)
                        asstct = asstct+1;
                        poct = poct+1;
                        assists(n,asstct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);   
                        putouts(n,poct) = parse_pos(fieldtext(max(1,tos(k+1)-2):tos(k+1)),n);
                        tas_str{n} = [tas_str{n},num2str(assists(n,asstct)),'-'];

                        % last fielder just gets a putout
                        poct = poct+1;
                        putouts(n,poct) = parse_pos(fieldtext(tos(k+1)+2:end),n);            
                        tas_str{n} = [tas_str{n},num2str(putouts(n,poct)),' '];
                    end

                    outsOnPlay = outsOnPlay + 2;
                    
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runPosTmp = 0;
                    runtxt = runtxt(pos+punct(1):end);
                elseif(strfind(runtxt,'no advance'))
                    no_text = 0;
                    pos = strfind(runtxt,'no advance');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'NA '];
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    
                    for ii=3:-1:1,
                        if(strcmp(runName{n,ii},runNameTmp))
                            %newRun{ii} = runNameTmp;
                            runPosTmp = ii;
                        end
                    end
                    runtxt = runtxt(pos+10:end);
                end
                
                % SB
                if(strfind(runtxt,'stolen base'))
                    no_text = 0;
                    pos = strfind(runtxt,'stolen base');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'SB '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+11:end)];
                end
                % PB
                if(strfind(runtxt,'on a passed ball'))
                    no_text = 0;
                    pos = strfind(runtxt,'on a passed ball');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'PB '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+16:end)];
                end
                % WP
                if(strfind(runtxt,'on a wild pitch'))
                    no_text = 0;
                    pos = strfind(runtxt,'on a wild pitch');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'WP '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+16:end)];
                end
                % BK
                if(strfind(runtxt,'balk'))
                    no_text = 0;
                    pos = strfind(runtxt,'balk');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'BK '];

                    runtxt = [runtxt(1:pos-6),runtxt(pos+4:end)];
                end
                % CS
                if(strfind(runtxt,'caught stealing'))
                    no_text = 0;
                    pos = strfind(runtxt,'caught stealing');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'CS '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+16:end)];
                end
                % DP/TP
                if(~isempty(strfind(runtxt,'out on the play')) && ~isempty(strfind(tmptext,'double play')))
                    no_text = 0;
                    tas_str{n} = [tas_str{n},'X DP '];
                    pos = strfind(runtxt,'out on the play');
                    
                    runPosTmp = 0;
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runtxt = runtxt(pos+16:end);     
                elseif(~isempty(strfind(runtxt,'out on the play')) && ~isempty(strfind(tmptext,'triple play')))
                    no_text = 0;
                    tas_str{n} = [tas_str{n},'X TP '];
                    pos = strfind(runtxt,'out on the play');
                    
                    runPosTmp = 0;
                    if(t == 1)
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    runtxt = runtxt(pos+16:end);     
                end
                % UE
                if(strfind(runtxt,'team unearned'))
                    no_text = 0;
                    pos = strfind(runtxt,'team unearned');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tm_uer(n) = tm_uer(n) + 1;
                    tas_str{n} = [tas_str{n},'TUE '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+14:end)];       
                elseif(strfind(runtxt,' unearned'))
                    no_text = 0;
                    if(strfind(runtxt,', unearned'))
                        pos = strfind(runtxt,', unearned');
                    else
                        pos = strfind(runtxt,' unearned');
                    end
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    uer(n) = uer(n) + 1;
                    tas_str{n} = [tas_str{n},'UE '];

                    runPosTmp = 4;
                    if(t == 1 && isempty(runNameTmp))
                        runNameTmp = strtrim(runtxt(1:pos-1));
                    end
                    
                    if(pos+11 > length(runtxt))
                        runtxt = runtxt(1:pos-1);
                    else
                        runtxt = [runtxt(1:pos-1),runtxt(pos+11:end)];
                    end
                end
                % INT
                if(strfind(runtxt,'interference'))
                    no_text = 0;
                    pos = strfind(runtxt,'interference');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'INT '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+12:end)];
                end
                % PK
                if(strfind(runtxt,'picked off'))
                    no_text = 0;
                    pos = strfind(runtxt,'picked off');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'PK '];
                    pk_fl(n) = pk_fl(n)+1;

                    runtxt = [runtxt(1:pos-1),runtxt(pos+10:end)];
                end
                % FPO
                if(strfind(runtxt,'failed pickoff attempt'))
                    no_text = 0;
                    pos = strfind(runtxt,'failed pickoff attempt');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'FPO '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+22:end)];
                end
                % RLE
                if(strfind(runtxt,'runner left early'))
                    no_text = 0;
                    pos = strfind(runtxt,'runner left early');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'RLE '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+18:end)];
                end
                % AOE
                if(strfind(runtxt,'on the error'))
                    no_text = 0;
                    pos = strfind(runtxt,'on the error');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'E '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+12:end)];
                end
                if(strfind(runtxt,'on a throwing error'))
                    no_text = 0;
                    pos = strfind(runtxt,'on a throwing error');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    bypos = strfind(runtxt(pos:end),'by ');
                    
                    errct = errct+1;
                    errors(n,errct) = parse_pos(runtxt(pos+bypos+2:min(pos+bypos+4,length(runtxt))),n);  
                    errtype{n,errct} = 'T';

                    tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'T '];

                    if(pos+bypos+4 > length(runtxt))
                        runtxt = runtxt(1:pos-1);
                    else
                        runtxt = [runtxt(1:pos-1),runtxt(min(pos+bypos+4,length(runtxt)):end)];
                    end
                end
                if(strfind(runtxt,'on a fielding error'))
                    no_text = 0;
                    pos = strfind(runtxt,'on a fielding error');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    bypos = strfind(runtxt(pos:end),'by ');
                    
                    errct = errct+1;
                    errors(n,errct) = parse_pos(runtxt(pos+bypos+2:min(pos+bypos+4,length(runtxt))),n);  
                    errtype{n,errct} = 'F';

                    tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'F '];

                    if(pos+bypos+4 > length(runtxt))
                        runtxt = runtxt(1:pos-1);
                    else
                        runtxt = [runtxt(1:pos-1),runtxt(min(pos+bypos+4,length(runtxt)):end)];
                    end
                end
                if(strfind(runtxt,'on an error'))
                    no_text = 0;
                    pos = strfind(runtxt,'on an error');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    bypos = strfind(runtxt(pos:end),'by ');
                    
                    errct = errct+1;
                    errors(n,errct) = parse_pos(runtxt(pos+bypos+2:min(pos+bypos+4,length(runtxt))),n);  
                    errtype{n,errct} = 'O';

                    tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'O '];

                    if(pos+bypos+4 > length(runtxt))
                        runtxt = runtxt(1:pos-1);
                    else
                        runtxt = [runtxt(1:pos-1),runtxt(min(pos+bypos+4,length(runtxt)):end)];
                    end
                end
                if(strfind(runtxt,'on a muffed throw'))
                    no_text = 0;
                    pos = strfind(runtxt,'on a muffed throw');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);
                    bypos = strfind(runtxt(pos:end),'by ');
                    
                    errct = errct+1;
                    errors(n,errct) = parse_pos(runtxt(pos+bypos+2:min(pos+bypos+4,length(runtxt))),n);  
                    errtype{n,errct} = 'MT';

                    tas_str{n} = [tas_str{n},'E',num2str(errors(n,errct)),'MT '];

                    if(pos+bypos+4 > length(runtxt))
                        runtxt = runtxt(1:pos-1);
                    else
                        runtxt = [runtxt(1:pos-1),runtxt(min(pos+bypos+4,length(runtxt)):end)];
                    end
                end
                % AOT
                if(strfind(runtxt,'on the throw'))
                    no_text = 0;
                    pos = strfind(runtxt,'on the throw');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'T '];

                    runtxt = [runtxt(1:pos-1),runtxt(pos+12:end)];
                end
                % FC
                if(strfind(runtxt,'fielder''s choice'))
                    no_text = 0;
                    pos = strfind(runtxt,'fielder''s choice');
                    punct = [strfind(runtxt(pos:end),';'),strfind(runtxt(pos:end),':'),strfind(runtxt(pos:end),'.'),strfind(runtxt(pos:end),','),length(runtxt(pos:end))];
                    punct = sort(punct);

                    tas_str{n} = [tas_str{n},'FC '];

                    runtxt = [runtxt(1:pos-6),runtxt(pos+16:end)];
                end
                % extra assists, I guess
                if(strfind(runtxt,'assist by'))
                    no_text = 0;
                    pos = strfind(runtxt,'by');

                    asstct = asstct+1;
                    assists(n,asstct) = parse_pos(runtxt(pos+3:min(pos+5,length(runtxt))),n);   

                    tas_str{n} = [tas_str{n},'A',num2str(assists(n,asstct)),' '];

                    runtxt = [runtxt(1:pos-8),runtxt(pos+22:end)];
                end
            end

            if(no_text)
                runName2 = runtmp{m};
                runFound = 0;
                for ii=3:-1:1,
                    if(strfind(runName2,runName{n,ii}))
                        runFound = 1;
                        % remove runner from bases
                        if(m > 1)
                            if(strfind(runtmp{m-1},'scored'))
                                newRun{ii} = '';
                                break;
                            end
                        elseif(m == 1)
                            if(rbi(n) > runsOnPlay) %&& ~isempty(strfind(tmptext,'RBI')))
                                newRun{ii} = '';
                                break;
                            end
                        end
                        if(isempty(newRun{ii}))
                            newRun{ii} = runName{n,ii};
                        elseif(~strcmp(newRun{ii},runName{n,ii}))
                            nextBase = min(ii+1,length(newRun));
                            if(isempty(newRun{nextBase}))
                                newRun{nextBase} = runName{n,ii};
                            elseif(~strcmp(newRun{nextBase},runName{n,ii}))
                                nextBase = min(ii+2,length(newRun));
                                if(isempty(newRun{nextBase}))
                                    newRun{nextBase} = runName{n,ii};
                                elseif(~strcmp(newRun{nextBase},runName{n,ii}))
                                nextBase = min(ii+3,length(newRun));
                                    if(isempty(newRun{nextBase}))
                                        newRun{nextBase} = runName{n,ii};
                                    end
                                end
                            end
                        end
                    end
                end
                
                if(runFound == 0)
                    if(isempty(newRun{ii}))
                        newRun{ii} = strtrim(runName2(1:end-1));
                    else
                        nextBase = min(ii+1,length(newRun));
                        if(isempty(newRun{nextBase}))
                            newRun{nextBase} = strtrim(runName2(1:end-1));
                        else
                            nextBase = min(ii+2,length(newRun));
                            if(isempty(newRun{nextBase}))
                                newRun{nextBase} = strtrim(runName2(1:end-1));
                            else
                            nextBase = min(ii+3,length(newRun));
                                if(isempty(newRun{nextBase}))
                                    newRun{nextBase} = strtrim(runName2(1:end-1));
                                end
                            end
                        end
                    end
                end
                runtxt = '';
            else
                for s = 1:3
                    if(strcmp(newRun{s},runNameTmp))
                        newRun{s} = '';
                    end
                end
                if(runPosTmp >= 1 && runPosTmp <= 3)
                    newRun{runPosTmp} = runNameTmp;
                else
                    % runner scored/is out, remove name
                end
            end

            if(regexp(runtxt,'[0-9A-Za-z]'))
                fprintf('runner on line %i: %s\n',n,runtxt);
            end
        end
    end

%% MOVING ON

    outs_end(n) = outs(n) + outsOnPlay;
    base_end(n) = 4*(~isempty(newRun{3})) + 2*(~isempty(newRun{2})) + 1*(~isempty(newRun{1}));
    
    if(sc(n) > 1)
        charsleft(n,1) = length(battext);
        textleft{n,1} = battext;
        for m=1:sc(n)-1
            charsleft(n,m+1) = length(runtmp{m});
            textleft{n,m+1} = runtmp{m};
        end
        charsleft(n,m+2) = length(runtmp{m+1});
        textleft{n,m+2} = runtmp{m+1};
    elseif(sc(n) == 1)
        charsleft(n,1) = length(battext);     
        textleft{n,1} = battext;
        charsleft(n,2) = length(runtmp{1});
        textleft{n,2} = runtmp{1};
    else
        charsleft(n,1) = length(battext);        
        textleft{n,1} = battext;
    end
    
    if(regexp(textleft{n,1},'[0-9A-Za-z]'))
        fprintf('batter on line %i: %s\n',n,textleft{n,1});
    end
    
    % base/out/runs state sanity check
    if(events{n,3} == 0)    % new game
        score_chg = events{n,5} + events{n,6};
    else
        score_chg = events{n,5} - events{n-1,5} + events{n,6} - events{n-1,6};
    end

    runners_in = ~isempty(runName{n,1}) + ~isempty(runName{n,2}) + ~isempty(runName{n,3}) + outs(n);
    if(score_chg > 0)
        runners_out = ~isempty(newRun{1}) + ~isempty(newRun{2}) + ~isempty(newRun{3}) + outs_end(n) + score_chg;
        play_fate(n) = score_chg;
    else
        runners_out = ~isempty(newRun{1}) + ~isempty(newRun{2}) + ~isempty(newRun{3}) + outs_end(n) + runsOnPlay;
        play_fate(n) = runsOnPlay;
    end

    if(outs_end(n) < 3 && isempty(strfind(events{n+1,4},'R:')) && isempty(strfind(events{n+1,7},'R:')))
        if(runners_in + is_bat(n) ~= runners_out)
    %         runName{n,:}
    %         newRun
    %         runners_in + is_bat(n) 
    %         runners_out
            fprintf('!!!Disagreement on line %i: %s\n',n,tmptext);
        end
    end
    
end

waitbar(1,h,sprintf('Parsing complete! Writing to output file...'))
%% PUTTING EVERYTHING TOGETHER

yearNo = 2015;
divNo = 1;

unique_ids = 1:length(events);
year_ids = yearNo*ones(size(unique_ids));
div_ids = divNo*ones(size(unique_ids));

% new_labels = {'unique_id','year_id','div_id','game_id','inning','event_seq','road_text','road_score','home_score','home_team','bat_name','run_name',...
%             'sub_in','sub_pos','sub_out','base_cd_before','outs_before','event_str','balls','strikes','pitch_str','base_cd_after','outs_after',...
%             'rbi','uer','tm_uer','ab_fl','pa_fl','bat_event_fl','hit_cd','hit_type','hit_loc','bunt_fl','sf_fl','sh_fl','sb_fl','cs_fl','pk_fl',...
%             'asst1','asst2','asst3','asst4','asst5','asst6','asst7','putout1','putout2','putout3','error1','error2','error3','error4','err1_type','err2_type',...
%             'err3_type','err4_type','inn_st_fl','inn_end_fl','runs_this_inn'};
% new_events = {unique_ids', year_ids', div_ids', events, batName, runName, sub_cell, bases, outs, tas_str, balls, strikes, pitches, base_end, outs_end,...
%             rbi, uer, tm_uer, is_ab, is_pa, is_bat, hit_cd, hit_type, hit_loc, is_bunt, is_sf, is_sh, sb_fl, cs_fl, pk_fl, assists, putouts,...
%             errors, errtype, inn_st_fl, inn_end_fl, inn_fate};
% 
% out_cell = [new_labels; new_events];

filename = ['C:\Retrosheet\ncaa\events_',num2str(yearNo),'_D',num2str(divNo),'.dat'];
eventFile = fopen(filename,'w');
        
fprintf(eventFile,'unique_id\tyear_id\tdiv_id\tgame_id\tinning\thome_bats\tevent_seq\troad_text\troad_score\thome_score\t');
fprintf(eventFile,'home_team\tbat_name\trun1_name\trun2_name\trun3_name\tsub_in\tsub_pos\tsub_out\tbase_cd_before\touts_before\tevent_str\t');
fprintf(eventFile,'balls\tstrikes\tpitch_str\tbase_cd_after\touts_after\trbi\tuer\ttm_uer\tab_fl\tpa_fl\tbat_event_fl\tbip_fl\t');
fprintf(eventFile,'event_cd\thit_cd\thit_type\thit_loc\tbunt_fl\tsf_fl\tsh_fl\tsb_fl\tcs_fl\tpk_fl\tasst1\tasst2\tasst3\tasst4\t');
fprintf(eventFile,'asst5\tasst6\tputout1\tputout2\tputout3\terror1\terror2\terror3\terr1_type\t');
fprintf(eventFile,'err2_type\terr3_type\tinn_st_fl\tinn_end_fl\tinn_runs_before\truns_on_play\truns_this_inn\n');

for n=2:length(events)
%     if(mod(n,1000) == 0)
%         waitbar(n/length(events),h,sprintf('%i lines written. (%2.2f%%)',n,100*n/length(events)))
%     end
    
    fprintf(eventFile,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%d\t',unique_ids(n),year_ids(n),div_ids(n),events{n,1},events{n,2},home_bats(n),events{n,3},events{n,4},events{n,5},events{n,6});
    fprintf(eventFile,'%s\t%s\t%s\t%s\t%s\t%s\t%d\t%s\t%d\t%d\t%s\t',events{n,7},batName{n},runName{n,1},runName{n,2},runName{n,3},sub_cell{n,1},sub_cell{n,2},sub_cell{n,3},bases(n),outs(n),tas_str{n});
    fprintf(eventFile,'%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t',balls(n),strikes(n),pitches{n},base_end(n),outs_end(n),rbi(n),uer(n),tm_uer(n),is_ab(n),is_pa(n),is_bat(n),is_bip(n));
    fprintf(eventFile,'%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t',event_cd(n),hit_cd(n),hit_type{n},hit_loc{n},is_bunt(n),is_sf(n),is_sh(n),sb_fl(n),cs_fl(n),pk_fl(n),assists(n,1),assists(n,2),assists(n,3),assists(n,4));
    fprintf(eventFile,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t',assists(n,5),assists(n,6),putouts(n,1),putouts(n,2),putouts(n,3),errors(n,1),errors(n,2),errors(n,3),errtype{n,1});
    fprintf(eventFile,'%s\t%s\t%d\t%d\t%d\t%d\n',errtype{n,2},errtype{n,3},inn_st_fl(n),inn_end_fl(n),play_fate(n),inn_fate(n));

end

fclose(eventFile);

close(h) 

