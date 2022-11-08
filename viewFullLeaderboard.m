function [] = viewFullLeaderboard(expName)
%
%
% Created by SML July 2016

% Load leaderboard:
fname = ['leaderboard_', expName];
try 
    load(fname)
catch
    disp('Leaderboard could not be found')
    return
end

% Sort leaderboard:
[points,idx] = sort(leaderboard_score,2,'descend');
names = leaderboard_init(idx);

% Display leaderboard:
N = length(points);
for ii = 1:N-2
   ptext = [names{ii} ':   ' num2str(points(ii))];
   disp(ptext)
end

end
