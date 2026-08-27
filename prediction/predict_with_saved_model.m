clear; clc;
%% ========== Configuration ==========
modelFile = '../models/TrainedModel_BP.mat';   %  Enter the path of the model
Xnew = [5.26, -7.12, 22.4];   % Single sample, fill in according to the order of XNames
%% ==============================
S = load(modelFile);
mdl = S.PredTrainedModel;
Xnew = double(Xnew(:))'; 

fprintf('Type: %s\n', mdl.Type);
if isfield(mdl, 'XNames'), fprintf('XNames: %s\n', strjoin(string(mdl.XNames), ', ')); end
if isfield(mdl, 'YNames'), fprintf('YNames: %s\n', strjoin(string(mdl.YNames), ', ')); end

switch upper(string(mdl.Type))
    case 'BP'
        Yhat = mdl.Net(Xnew')';
        yNames = mdl.YNames;
    case {'RF', 'GBDT'}
        nY = numel(mdl.Models);
        Yhat = nan(1, nY);
        for j = 1:nY
            Yhat(j) = predict(mdl.Models{j}, Xnew);
        end
        yNames = mdl.YNames;
    case 'SER'
        [Yhat, yNames] = predictSER_one(mdl, Xnew);
    otherwise
        error('Unsupported type: %s', mdl.Type);
end

if isstring(yNames), yNames = cellstr(yNames); end
disp('Prediction:');
disp(array2table(Yhat(:)', 'VariableNames', matlab.lang.makeValidName(yNames)));

function [Yhat, yNames] = predictSER_one(mdl, Yin)
    eqs = mdl.Equations;
    if isfield(mdl, 'Unknowns') && ~isempty(mdl.Unknowns)
        yNames = mdl.Unknowns;
    else
        yNames = mdl.YNames;
    end
    if isstring(yNames), yNames = cellstr(yNames); end
    if isfield(mdl, 'Processing') && ~isempty(mdl.Processing)
        proc = char(string(mdl.Processing));
    else
        proc = 'Raw';
    end
    xNames = mdl.XNames;
    if isstring(xNames), xNames = cellstr(xNames); end
    nameToCol = containers.Map(xNames, num2cell(1:numel(xNames)));

    nEq = numel(eqs);
    nUnk = numel(yNames);
    M = zeros(nEq, nUnk);
    rhs = zeros(nEq, 1);
    validEq = true(nEq, 1);
    for i = 1:nEq
        [yp, ok] = applyProc(Yin(nameToCol(eqs(i).yName)), proc, true);
        if ~ok, validEq(i) = false; continue; end
        M(i, strcmp(yNames, eqs(i).x1Name)) = eqs(i).beta(1);
        M(i, strcmp(yNames, eqs(i).x2Name)) = eqs(i).beta(2);
        rhs(i) = yp - eqs(i).beta(3);
    end
    u = M(validEq, :) \ rhs(validEq);
    Yhat = nan(1, nUnk);
    for k = 1:nUnk
        [val, ok] = applyProc(u(k), proc, false);
        if ok, Yhat(k) = val; end
    end
end

function [v, ok] = applyProc(v, mode, forward)
    ok = true;
    switch mode
        case 'Logarithm'
            if forward
                if ~(isfinite(v) && v > 0), ok = false; return; end
                v = log(v);
            else
                v = exp(v);
            end
        case 'Reciprocal'
            if ~(isfinite(v) && v ~= 0), ok = false; return; end
            v = 1 / v;
        otherwise
            if ~isfinite(v), ok = false; end
    end
end
