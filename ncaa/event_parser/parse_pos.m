function num = parse_pos(pos_str,line_no)

if(nargin == 1)
    line_no = -1;
end

if(~isempty(strfind(pos_str,'1b')))
    num = 3;
elseif(~isempty(strfind(pos_str,'2b')))
    num = 4;
elseif(~isempty(strfind(pos_str,'3b')))
    num = 5;
elseif(~isempty(strfind(pos_str,'ss')))
    num = 6;
elseif(~isempty(strfind(pos_str,'lf')))
    num = 7;
elseif(~isempty(strfind(pos_str,'cf')))
    num = 8;
elseif(~isempty(strfind(pos_str,'rf')))
    num = 9;
elseif(~isempty(strfind(pos_str,'c')))
    num = 2;
elseif(~isempty(strfind(pos_str,'dh')))
    num = 10;
elseif(~isempty(strfind(pos_str,'p')))
    num = 1;
else
    fprintf('~*~Warning: Unusual position in parser on line # %i: %s\n',line_no,pos_str);
    num = -1;
end