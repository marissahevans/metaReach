function [names,points] = addToLeaderboard(expName,init,score)
%
%
% Created by SML July 2016

fname = ['leaderboard_', expName];

try 
    load(fname)
    N = length(leaderboard_init);
    leaderboard_init(N+1) = {init};
    leaderboard_score = [leaderboard_score, score];
catch
    leaderboard_init = {init, 'BLANK', 'BLANK', 'BLANK', 'BLANK'};
    leaderboard_score = [score, 0, 0, 0, 0];
end

[points,idx] = sort(leaderboard_score,2,'descend');
names = leaderboard_init(idx);
save(fname,'leaderboard_init','leaderboard_score')

end