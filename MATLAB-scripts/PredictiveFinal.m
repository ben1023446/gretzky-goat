metrics = { 'MixedModel', 'EraAdjusted', 'ZScore', 'Composite', 'WeightedComposite' };
nM = numel(metrics);

S = readtable('all_seasons_combined.csv');      % all seasons and player stats
S = S(S.GP >= 20, :);       % drop players with <20 games played
[~, ~, pid] = unique(S.Player);     % create and ID for each player
careerLengths = accumarray(pid, 1);           

% allocating outputs
D_goat = zeros(nM,1);
P_surpass = zeros(nM,1);
CI_low = zeros(nM,1);
CI_high = zeros(nM,1);
shapeGEV    = zeros(nM,1);
scaleGEV    = zeros(nM,1);
locGEV      = zeros(nM,1);

if isempty(gcp('nocreate')), parpool; end

% metrics loop 
for i = 1:nM
    metric = metrics{i};

    switch metric
      case 'MixedModel'
        T = readtable('GOAT_rankings.xlsx','Sheet','MixedModel');
        peaks = T.Effect;
        players = T.Player;
      case 'EraAdjusted'
        T = readtable('GOAT_rankings.xlsx','Sheet','EraAdjusted');
        peaks = T.PeakAdj;
        players = T.Player;
      case 'ZScore'
        T = readtable('GOAT_rankings.xlsx','Sheet','ZScore');
        peaks = T.PeakZ;
        players = T.Player;
      case 'Composite'
        C = readtable('final_rankings.csv');
        peaks = C.Composite;
        players = C.Player;
      case 'WeightedComposite'
        W = readtable('final_rankings_weighted.csv');
        peaks = W.Composite_w;
        players = W.Player;
      otherwise
        error('Unknown metric %s', metric);
    end

    %calculate the GOAT
    [ps, idx] = sort(peaks,'descend');
    goat = ps(1);
    runner_up = ps(2);
    sigma_p = std(peaks,1);     % population standard deviation
    Dg = (goat - runner_up) / sigma_p;
    D_goat(i) = Dg;

    % generalised extreme value
    parmhat = gevfit(peaks);           
    kappa = parmhat(1);
    sigmaGEV = parmhat(2);
    muGEV = parmhat(3);
    shapeGEV(i) = kappa;
    scaleGEV(i) = sigmaGEV;
    locGEV(i)   = muGEV;

    % quantile-quantile plot
    figQQ = figure('Visible','off');
    qqplot(peaks, gevinv(((1:length(peaks))'-.5)/length(peaks), kappa, sigmaGEV, muGEV));
    title(sprintf('%s QQ-plot', metric),'Interpreter','none');
    set(gca, 'FontSize', 14, 'LineWidth', 1.2);
    exportgraphics(figQQ, sprintf('QQplot_%s.png',metric),'Resolution',300);
    close(figQQ);

    % plot return level curve
    Tyears = [2 5 10 20 50 100 500 1000];
    zT = gevinv(1-1./Tyears, kappa, sigmaGEV, muGEV);
    figRL = figure('Visible','off');
    semilogx(Tyears, zT, '-o','LineWidth',1.5);
    xlabel('Return Period T (years)');
    ylabel('Return Level');
    title(sprintf('%s Return-Level Curve', metric),'Interpreter','none');
    grid on;
    set(gca, 'FontSize', 14, 'LineWidth', 1.2)          
    exportgraphics(figRL, sprintf('ReturnLevel_%s.png', metric), 'Resolution',300);
    close(figRL);


    % monte carlo
    N = 20000;
    simD = zeros(N,1);
    parfor j = 1:N
        k_i  = randsample(careerLengths, 1, true);
        draws = gevrnd(parmhat(1), parmhat(2), parmhat(3), k_i, 1);
        simD(j) = (max(draws) - runner_up) / sigma_p;
    end

    % probability of surpassing and confidence intervals
    p0 = mean(simD > Dg);
    P_surpass(i) = p0;
    B = 200;
    pbs = zeros(B,1);
    for b = 1:B
        idxb = randsample(N, N, true);
        pbs(b) = mean(simD(idxb) > Dg);
    end
    ci = prctile(pbs, [2.5 97.5]); 
    CI_low(i) = ci(1);
    CI_high(i) = ci(2);
    figMC = figure('Visible','off');
    histogram(simD, 50, 'Normalization','pdf', 'FaceColor',[.7 .7 .7]);
    hold on;
    yl = ylim;
    plot([Dg Dg], yl, 'r--', 'LineWidth',2);
    xlabel('Simulated Dominance Score');
    ylabel('Density');
    title(sprintf('%s Monte Carlo Histogram', metric), 'Interpreter','none');
    legend('Simulated','G.O.A.T.','Location','northeast');
    set(gca, 'FontSize', 12, 'LineWidth', 1);
    text(Dg + 0.1, yl(2)*0.8, 'Gretzky', 'Color','r', 'FontSize',12);
    exportgraphics(figMC, sprintf('MChistogram_%s.png', metric), 'Resolution',300);
    close(figMC);
end

%summary table
Results = table(metrics', D_goat, P_surpass*100, CI_low*100, CI_high*100,shapeGEV,scaleGEV,locGEV,'VariableNames',{'Metric','Dominance Goat','Surpass %','CI Low','CI High','GEV Shape','GEV Scale','GEV Loc'});
writetable(Results, 'sensitivity_results.csv');

% unweighted average
P_ens = mean(P_surpass);

% weighted average
deltas = CI_high - CI_low;           
inv_deltas = 1 ./ deltas;                
weights = inv_deltas / sum(inv_deltas);
P_ens_wt = sum(weights .* P_surpass);
TF = table(P_ens*100, P_ens_wt*100,'VariableNames',{'Unweighted Percent','Weighted Percent'});
writetable(TF,'ensemble_summary.csv');

%plot ensamble graphs
figure;
barH = bar(categorical(metrics), P_surpass*100, 'FaceColor',[.6 .6 .9]);
hold on;
line1 = yline(P_ens*100,    'r--','LineWidth',1.5, 'Label','Unweighted');
line2 = yline(P_ens_wt*100, 'g--','LineWidth',1.5, 'Label','Weighted');
ylabel('P(future > GOAT) [%]');
title('Ensemble Forecast');
legend([barH,line1,line2],{'Metrics','Unweighted Ens.','Weighted Ens.'});
grid on;
saveas(gcf,'combinedforecast.png');
