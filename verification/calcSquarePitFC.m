clear; clc;
pipeLength = 1500;
piper      = 150;
pipes      = 10;
current    = 3;
pitLength  = 10;
pith       = [1,2,3,4,5];
rows       = 3;
cols       = 4;
spacing    = 30;
import com.comsol.model.*
import com.comsol.model.util.*
ensureComsolConnected();
pithList = pith(:).';
coord = buildElectrodeCoords(pipeLength, piper, rows, cols, spacing);
modelW = buildUncorrosionModel(pipeLength, piper, pipes, current);
modelW.study('std1').run();
voltageW = calcVoltage(extractPotential(modelW, coord), rows, cols);

modelP = buildPittedModel(pipeLength, piper, pipes, pitLength, pithList(1), current);
for k = 1:numel(pithList)
    h = pithList(k);
    modelP.param.set('pith', sprintf('%g[mm]', h));
    modelP.study('std1').run();
    voltageP = calcVoltage(extractPotential(modelP, coord), rows, cols);
    FC = calcFC(voltageP, voltageW);
    if numel(pithList) > 1
        fprintf('pith = %g mm\n', h);
    end
    disp(FC);
end

function ensureComsolConnected()
    try
        import com.comsol.model.util.*
        ModelUtil.tags();
    catch
        if exist('mphstart', 'file') ~= 2
            error('COMSOL LiveLink (mphstart) was not detected. Please start COMSOL and connect it to MATLAB first.');
        end
        mphstart;
        import com.comsol.model.util.*
    end
    ModelUtil.showProgress(true);
end

function coordinate = buildElectrodeCoords(pipeLength, piper, rows, cols, spacing)
    rows = round(rows);
    cols = round(cols);
    if rows < 1 || cols < 2
        error('The number of rows must be ≥1, and the number of columns must be ≥2！');
    end
    d = spacing;
    x0 = pipeLength / 2 + ((0:cols-1) - (cols-1)/2) * d;
    k  = ((0:rows-1) - (rows-1)/2);
    y0 = -piper * sin(k * d / piper);
    z0 =  piper * cos(k * d / piper);
    coordinate = zeros(3, rows * cols);
    n = 1;
    for ix = 1:cols
        for ir = 1:rows
            coordinate(:, n) = [x0(ix); y0(ir); z0(ir)];
            n = n + 1;
        end
    end
end

function V = extractPotential(model, coordinate)
    V = mphinterp(model, 'V', 'coord', coordinate);
end

function voltage = calcVoltage(V, rows, cols)
    Data_V = reshape(V, rows, cols);
    voltage = -diff(Data_V, 1, 2) .* 1e6;
end

function FC = calcFC(voltageP, voltageW)
    FC = (voltageP ./ voltageW - 1) * 1000;
end

function model = buildUncorrosionModel(pipeLength, piper, pipes, current)
    import com.comsol.model.*
    import com.comsol.model.util.*

    model = ModelUtil.create('Model_uncorrosion');
    model.param.set('pipes',   sprintf('%g[mm]', pipes));
    model.param.set('piper',   sprintf('%g[mm]', piper));
    model.param.set('length',  sprintf('%g[mm]', pipeLength));
    model.param.set('current', sprintf('%g[A]',  current));

    model.component.create('comp1', true);
    model.component('comp1').geom.create('geom1', 3);
    model.component('comp1').mesh.create('mesh1');
    model.component('comp1').geom('geom1').lengthUnit('mm');

    model.component('comp1').geom('geom1').create('cyl1', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl1').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('cyl1').set('r', 'piper');
    model.component('comp1').geom('geom1').feature('cyl1').set('h', 'length');
    model.component('comp1').geom('geom1').create('cyl2', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl2').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('cyl2').set('r', 'piper-pipes');
    model.component('comp1').geom('geom1').feature('cyl2').set('h', 'length');
    model.component('comp1').geom('geom1').create('dif1', 'Difference');
    model.component('comp1').geom('geom1').feature('dif1').selection('input').set({'cyl1'});
    model.component('comp1').geom('geom1').feature('dif1').selection('input2').set({'cyl2'});
    model.component('comp1').geom('geom1').create('cyl3', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl3').set('pos', {'20' '0' 'piper-1'});
    model.component('comp1').geom('geom1').feature('cyl3').set('r', 3);
    model.component('comp1').geom('geom1').feature('cyl3').set('h', 7);
    model.component('comp1').geom('geom1').create('mir1', 'Mirror');
    model.component('comp1').geom('geom1').feature('mir1').set('keep', true);
    model.component('comp1').geom('geom1').feature('mir1').set('pos', {'length/2' '0' '0'});
    model.component('comp1').geom('geom1').feature('mir1').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('mir1').selection('input').set({'cyl3'});
    model.component('comp1').geom('geom1').create('blk1', 'Block');
    model.component('comp1').geom('geom1').feature('blk1').set('pos', {'0' '-piper-5' '-piper-1'});
    model.component('comp1').geom('geom1').feature('blk1').set('size', {'length' '2*piper+10' 'piper+1'});
    model.component('comp1').geom('geom1').create('dif3', 'Difference');
    model.component('comp1').geom('geom1').feature('dif3').selection('input').set({'dif1'});
    model.component('comp1').geom('geom1').feature('dif3').selection('input2').set({'blk1'});
    model.component('comp1').geom('geom1').run;

    model.view.create('view2', 2);
    applySteelMaterial(model);

    model.component('comp1').physics.create('ec', 'ConductiveMedia', 'geom1');
    model.component('comp1').physics('ec').create('term1', 'DomainTerminal', 3);
    model.component('comp1').physics('ec').feature('term1').selection.set([3]);
    model.component('comp1').physics('ec').create('gnd1', 'Ground', 2);
    model.component('comp1').physics('ec').feature('gnd1').selection.set([27]);
    model.component('comp1').physics('ec').feature('term1').set('I0', 'current');

    model.component('comp1').mesh('mesh1').autoMeshSize(1);
    model.component('comp1').view('view1').set('transparency', true);

    model.study.create('std1');
    model.study('std1').create('stat', 'Stationary');
end

function model = buildPittedModel(pipeLength, piper, pipes, pitLength, pith, current)
    import com.comsol.model.*
    import com.comsol.model.util.*

    model = ModelUtil.create('Model_pitted');
    model.param.set('pipes',    sprintf('%g[mm]', pipes));
    model.param.set('piper',    sprintf('%g[mm]', piper));
    model.param.set('pitlegth', sprintf('%g[mm]', pitLength));
    model.param.set('pith',     sprintf('%g[mm]', pith));
    model.param.set('length',   sprintf('%g[mm]', pipeLength));
    model.param.set('current',  sprintf('%g[A]',  current));

    model.component.create('comp1', true);
    model.component('comp1').geom.create('geom1', 3);
    model.component('comp1').mesh.create('mesh1');
    model.component('comp1').geom('geom1').lengthUnit('mm');

    model.component('comp1').geom('geom1').create('cyl1', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl1').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('cyl1').set('r', 'piper');
    model.component('comp1').geom('geom1').feature('cyl1').set('h', 'length');
    model.component('comp1').geom('geom1').create('cyl2', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl2').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('cyl2').set('r', 'piper-pipes');
    model.component('comp1').geom('geom1').feature('cyl2').set('h', 'length');
    model.component('comp1').geom('geom1').create('dif1', 'Difference');
    model.component('comp1').geom('geom1').feature('dif1').selection('input').set({'cyl1'});
    model.component('comp1').geom('geom1').feature('dif1').selection('input2').set({'cyl2'});
    model.component('comp1').geom('geom1').create('cyl3', 'Cylinder');
    model.component('comp1').geom('geom1').feature('cyl3').set('pos', {'20' '0' 'piper-1'});
    model.component('comp1').geom('geom1').feature('cyl3').set('r', 3);
    model.component('comp1').geom('geom1').feature('cyl3').set('h', 7);
    model.component('comp1').geom('geom1').create('mir1', 'Mirror');
    model.component('comp1').geom('geom1').feature('mir1').set('keep', true);
    model.component('comp1').geom('geom1').feature('mir1').set('pos', {'length/2' '0' '0'});
    model.component('comp1').geom('geom1').feature('mir1').set('axis', [1 0 0]);
    model.component('comp1').geom('geom1').feature('mir1').selection('input').set({'cyl3'});
    model.component('comp1').geom('geom1').create('blk2', 'Block');
    model.component('comp1').geom('geom1').feature('blk2').set('pos', {'length/2' '0' '(pith+piper-pipes)/2'});
    model.component('comp1').geom('geom1').feature('blk2').set('base', 'center');
    model.component('comp1').geom('geom1').feature('blk2').set('size', {'pitlegth' 'pitlegth' 'pith+piper-pipes'});
    model.component('comp1').geom('geom1').create('dif2', 'Difference');
    model.component('comp1').geom('geom1').feature('dif2').selection('input').set({'dif1'});
    model.component('comp1').geom('geom1').feature('dif2').selection('input2').set({'blk2'});
    model.component('comp1').geom('geom1').create('blk1', 'Block');
    model.component('comp1').geom('geom1').feature('blk1').set('pos', {'0' '-piper-5' '-piper-1'});
    model.component('comp1').geom('geom1').feature('blk1').set('size', {'length' '2*piper+10' 'piper+1'});
    model.component('comp1').geom('geom1').create('dif3', 'Difference');
    model.component('comp1').geom('geom1').feature('dif3').selection('input').set({'dif2'});
    model.component('comp1').geom('geom1').feature('dif3').selection('input2').set({'blk1'});
    model.component('comp1').geom('geom1').run;

    model.view.create('view2', 2);
    applySteelMaterial(model);

    model.component('comp1').physics.create('ec', 'ConductiveMedia', 'geom1');
    model.component('comp1').physics('ec').create('term1', 'DomainTerminal', 3);
    model.component('comp1').physics('ec').feature('term1').selection.set([3]);
    model.component('comp1').physics('ec').create('gnd1', 'Ground', 2);
    model.component('comp1').physics('ec').feature('gnd1').selection.set([27]);
    model.component('comp1').physics('ec').feature('term1').set('I0', 'current');

    model.component('comp1').mesh('mesh1').autoMeshSize(1);
    model.component('comp1').view('view1').set('transparency', true);

    model.study.create('std1');
    model.study('std1').create('stat', 'Stationary');
end

function applySteelMaterial(model)
    model.component('comp1').material.create('mat1', 'Common');
    model.component('comp1').material('mat1').info.create('UNS');
    model.component('comp1').material('mat1').info.create('WNR');
    model.component('comp1').material('mat1').info.create('EN_DIN');
    model.component('comp1').material('mat1').info.create('JIS');
    model.component('comp1').material('mat1').info.create('ASTM');
    model.component('comp1').material('mat1').info.create('AISI');
    model.component('comp1').material('mat1').info.create('SAE');
    model.component('comp1').material('mat1').info.create('AMS');
    model.component('comp1').material('mat1').info.create('AFNOR');
    model.component('comp1').material('mat1').info.create([native2unicode(hex2dec({'7e' 'c4'}), 'unicode')  native2unicode(hex2dec({'52' '06'}), 'unicode') ]);
    model.component('comp1').material('mat1').propertyGroup('def').func.create('k', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('res', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('alpha', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('C', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('sigma', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('rho', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func.create('TD', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup.create('ThermalExpansion', [native2unicode(hex2dec({'70' 'ed'}), 'unicode')  native2unicode(hex2dec({'81' 'a8'}), 'unicode')  native2unicode(hex2dec({'80' 'c0'}), 'unicode') ]);
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func.create('dL', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func.create('CTE', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup.create('Enu', [native2unicode(hex2dec({'67' '68'}), 'unicode')  native2unicode(hex2dec({'6c' '0f'}), 'unicode')  native2unicode(hex2dec({'6a' '21'}), 'unicode')  native2unicode(hex2dec({'91' 'cf'}), 'unicode')  native2unicode(hex2dec({'54' '8c'}), 'unicode')  native2unicode(hex2dec({'6c' 'ca'}), 'unicode')  native2unicode(hex2dec({'67' '7e'}), 'unicode')  native2unicode(hex2dec({'6b' 'd4'}), 'unicode') ]);
    model.component('comp1').material('mat1').propertyGroup('Enu').func.create('E', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('Enu').func.create('nu', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup.create('KG', [native2unicode(hex2dec({'4f' '53'}), 'unicode')  native2unicode(hex2dec({'79' 'ef'}), 'unicode')  native2unicode(hex2dec({'6a' '21'}), 'unicode')  native2unicode(hex2dec({'91' 'cf'}), 'unicode')  native2unicode(hex2dec({'54' '8c'}), 'unicode')  native2unicode(hex2dec({'52' '6a'}), 'unicode')  native2unicode(hex2dec({'52' '07'}), 'unicode')  native2unicode(hex2dec({'6a' '21'}), 'unicode')  native2unicode(hex2dec({'91' 'cf'}), 'unicode') ]);
    model.component('comp1').material('mat1').propertyGroup('KG').func.create('mu', 'Piecewise');
    model.component('comp1').material('mat1').propertyGroup('KG').func.create('kappa', 'Piecewise');

    model.component('comp1').material('mat1').label('1020 [solid,annealed]');
    model.component('comp1').material('mat1').set('family', 'iron');
    model.component('comp1').material('mat1').set('info', {'UNS' '' 'G10200';  ...
        'WNR' '' '1.0402';  ...
        'EN_DIN' '' 'C22/CK22';  ...
        'JIS' '' 'S20C/S22C/SWRCH20A';  ...
        'ASTM' '' 'A510/A519/A544/A576/A659';  ...
        'AISI' '' '1020';  ...
        'SAE' '' 'J403/J412/J414';  ...
        'AMS' '' '5032/5045';  ...
        'AFNOR' '' 'S20C/S22C/SWRCH20A';  ...
        [native2unicode(hex2dec({'7e' 'c4'}), 'unicode')  native2unicode(hex2dec({'52' '06'}), 'unicode') ] '' 'bal. Fe, (0.18-0.23) C, (0.3-0.6) Mn, 0.04 P max, 0.05 S max (wt%)'});
    model.component('comp1').material('mat1').propertyGroup('def').func('k').label('Piecewise');
    model.component('comp1').material('mat1').propertyGroup('def').func('k').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('k').set('pieces', {'26.0' '200.0' '-5.435137+1.615324*T^1-0.01440223*T^2+6.259829E-5*T^3-1.325386E-7*T^4+1.087384E-10*T^5'; '200.0' '1073.16' '61.1315+0.05272897*T^1-2.040655E-4*T^2+2.105727E-7*T^3-8.423301E-11*T^4'});
    model.component('comp1').material('mat1').propertyGroup('def').func('k').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('k').set('fununit', 'W/(m*K)');
    model.component('comp1').material('mat1').propertyGroup('def').func('res').label('Piecewise 1');
    model.component('comp1').material('mat1').propertyGroup('def').func('res').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('res').set('pieces', {'293.0' '1073.0' '9.391673E-8+7.568236E-12*T^1+8.641318E-13*T^2'; '1073.0' '1573.16' '-3.625E-7+2.652646E-9*T^1-1.562286E-12*T^2+3.333333E-16*T^3'});
    model.component('comp1').material('mat1').propertyGroup('def').func('res').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('res').set('fununit', 'ohm*m');
    model.component('comp1').material('mat1').propertyGroup('def').func('alpha').label('Piecewise 2');
    model.component('comp1').material('mat1').propertyGroup('def').func('alpha').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('alpha').set('pieces', {'0.0' '680.0' '6.731035E-6+3.918624E-8*T^1-1.534406E-10*T^2+3.517965E-13*T^3-3.827522E-16*T^4+1.565546E-19*T^5';  ...
        '680.0' '977.0' '8.614185E-6+1.013631E-8*T^1-2.26181E-12*T^2-1.569696E-15*T^3';  ...
        '977.0' '1061.0' '6.292031E-5-4.915637E-8*T^1';  ...
        '1061.0' '1144.0' '-1.563678E-6+1.162025E-8*T^1'});
    model.component('comp1').material('mat1').propertyGroup('def').func('alpha').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('alpha').set('fununit', '1/K');
    model.component('comp1').material('mat1').propertyGroup('def').func('C').label('Piecewise 3');
    model.component('comp1').material('mat1').propertyGroup('def').func('C').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('C').set('pieces', {'293.0' '848.16' '-215.730638+6.0184999*T^1-0.0183429321*T^2+2.414973E-5*T^3-1.07882432E-8*T^4'});
    model.component('comp1').material('mat1').propertyGroup('def').func('C').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('C').set('fununit', 'J/(kg*K)');
    model.component('comp1').material('mat1').propertyGroup('def').func('sigma').label('Piecewise 4');
    model.component('comp1').material('mat1').propertyGroup('def').func('sigma').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('sigma').set('pieces', {'293.0' '1073.0' '1/(8.641318E-13*T^2+7.568236E-12*T+9.391673E-08)'; '1073.0' '1573.16' '1/(3.333333E-16*T^3-1.562286E-12*T^2+2.652646E-09*T-3.625E-07)'});
    model.component('comp1').material('mat1').propertyGroup('def').func('sigma').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('sigma').set('fununit', 'S/m');
    model.component('comp1').material('mat1').propertyGroup('def').func('rho').label('Piecewise 5');
    model.component('comp1').material('mat1').propertyGroup('def').func('rho').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('rho').set('pieces', {'0.0' '60.0' '7907.978-0.01549395*T^1';  ...
        '60.0' '977.0' '7911.3-0.01678428*T^1-8.018711E-4*T^2+1.172796E-6*T^3-1.015971E-9*T^4+3.677737E-13*T^5';  ...
        '977.0' '1061.0' '7116.994+0.5195388*T^1';  ...
        '1061.0' '1144.0' '8166.523-0.4696497*T^1'});
    model.component('comp1').material('mat1').propertyGroup('def').func('rho').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('rho').set('fununit', 'kg/m^3');
    model.component('comp1').material('mat1').propertyGroup('def').func('TD').label('Piecewise 6');
    model.component('comp1').material('mat1').propertyGroup('def').func('TD').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('def').func('TD').set('pieces', {'295.0' '1048.0' '1.908565E-5-1.445398E-8*T^1'; '1048.0' '1248.16' '-6.844E-5+1.158517E-7*T^1-4.46478E-11*T^2'});
    model.component('comp1').material('mat1').propertyGroup('def').func('TD').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('def').func('TD').set('fununit', 'm^2/s');
    model.component('comp1').material('mat1').propertyGroup('def').set('thermalconductivity', {'k(T)' '0' '0' '0' 'k(T)' '0' '0' '0' 'k(T)'});
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:thermalconductivity', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': E.A. Eldridge and H.W. Deem, Report on Physical Properties of Metals and Alloys from Cryogenic to Elevated Temperatures, ASTM, Special Technical Publication No. 296 (1961) https://doi.org/10.1520/STP296-EB and High-Temperature Property Data: Ferrous Alloys, Editor M.F. Rothman, ASM International (1988) and Engineering Properties of Steel, P.D. Harvey, ASM (1982)' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': data above 20 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (293 K) is from 1023 and multiplied by 1.2 to match the low temperature data']);
    model.component('comp1').material('mat1').propertyGroup('def').set('resistivity', {'res(T)' '0' '0' '0' 'res(T)' '0' '0' '0' 'res(T)'});
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:resistivity', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': ASM Handbook, v1, Properties and Selection: Irons, Steels, and High-Performance Alloys, 10th edition, ASM International (1990)' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values, annealed']);
    model.component('comp1').material('mat1').propertyGroup('def').set('thermalexpansioncoefficient', {'(alpha(T)+(Tempref-293[K])*if(abs(T-Tempref)>1e-3,(alpha(T)-alpha(Tempref))/(T-Tempref),d(alpha(T),T)))/(1+alpha(Tempref)*(Tempref-293[K]))' '0' '0' '0' '(alpha(T)+(Tempref-293[K])*if(abs(T-Tempref)>1e-3,(alpha(T)-alpha(Tempref))/(T-Tempref),d(alpha(T),T)))/(1+alpha(Tempref)*(Tempref-293[K]))' '0' '0' '0' '(alpha(T)+(Tempref-293[K])*if(abs(T-Tempref)>1e-3,(alpha(T)-alpha(Tempref))/(T-Tempref),d(alpha(T),T)))/(1+alpha(Tempref)*(Tempref-293[K]))'});
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:thermalexpansioncoefficient', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': MIL-HDBK-5H, 1 Dec 1998 p2-9 and R.J. Corruccini and J.J. Gniewek, Thermal Expansion of Technical Solids at Low Temperatures: A Compilation From the Literature, NBS Monograph 29 (1961) https://digital.library.unt.edu/ark:/67531/metadc70437/' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': the reference temperature is 20 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (293 K), same data as 1025 steel' newline  native2unicode(hex2dec({'53' 'c2'}), 'unicode')  native2unicode(hex2dec({'80' '03'}), 'unicode')  native2unicode(hex2dec({'6e' '29'}), 'unicode')  native2unicode(hex2dec({'5e' 'a6'}), 'unicode') ': 293.00[K]']);
    model.component('comp1').material('mat1').propertyGroup('def').set('heatcapacity', 'C(T)');
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:heatcapacity', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': ASM Handbook, v1, Properties and Selection: Irons, Steels, and High-Performance Alloys, 10th edition, ASM International (1990)' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values, annealed']);
    model.component('comp1').material('mat1').propertyGroup('def').set('electricconductivity', {'1/1.60E-7' '0' '0' '0' '1/1.60E-7' '0' '0' '0' '1/1.60E-7'});
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:electricconductivity', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': ASM Handbook, v1, Properties and Selection: Irons, Steels, and High-Performance Alloys, 10th edition, ASM International (1990)' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values, annealed, calculated as the reciprocal of the resistivity']);
    model.component('comp1').material('mat1').propertyGroup('def').set('density', 'rho(T)');
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:density', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': MIL-HDBK-5H, 1 Dec 1998 p2-9 and R.J. Corruccini and J.J. Gniewek, Thermal Expansion of Technical Solids at Low Temperatures: A Compilation From the Literature, NBS Monograph 29 (1961) https://digital.library.unt.edu/ark:/67531/metadc70437/' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': calculated from the linear expansion and the room temperature density']);
    model.component('comp1').material('mat1').propertyGroup('def').set('TD', 'TD(T)');
    model.component('comp1').material('mat1').propertyGroup('def').set('INFO_PREFIX:TD', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': C.P. Butler and E.C.Y. Inn, Thermal Diffusivity of Metals at elevated Temperatures, in Thermodynamic and Transport Properties of Gases, Liquids and Solids, ASME Symposium on Thermal Properties, Mc-Graw-Hill Book Co., p377-90 (1959)' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': hot-rolled, 5% to 10% error']);
    model.component('comp1').material('mat1').propertyGroup('def').set('relpermittivity', {'1E6' '0' '0' '0' '1E6' '0' '0' '0' '1E6'});
    model.component('comp1').material('mat1').propertyGroup('def').addInput('temperature');
    model.component('comp1').material('mat1').propertyGroup('def').addInput('strainreferencetemperature');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('dL').label('Piecewise');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('dL').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('dL').set('pieces', {'0.0' '50.0' '-0.002022973+3.918919E-7*T^1';  ...
        '50.0' '212.0' '-0.002063267-3.508062E-7*T^1+2.838477E-8*T^2';  ...
        '212.0' '977.0' '-0.00252395773+5.644256E-6*T^1+1.0799E-8*T^2-1.801872E-12*T^3-1.569701E-15*T^4';  ...
        '977.0' '1061.0' '0.03264232-2.297313E-5*T^1';  ...
        '1061.0' '1144.0' '-0.01351301+2.053771E-5*T^1'});
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('dL').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('CTE').label('Piecewise 1');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('CTE').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('CTE').set('pieces', {'293.0' '1065.0' '5.044861E-6+2.5188E-8*T^1-1.418195E-11*T^2'});
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('CTE').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').func('CTE').set('fununit', '1/K');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').set('alphatan', {'CTE(T)' '0' '0' '0' 'CTE(T)' '0' '0' '0' 'CTE(T)'});
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').set('INFO_PREFIX:alphatan', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': MIL-HDBK-5H, 1 Dec 1998 p2-9 and R.J. Corruccini and J.J. Gniewek, Thermal Expansion of Technical Solids at Low Temperatures: A Compilation From the Literature, NBS Monograph 29 (1961) https://digital.library.unt.edu/ark:/67531/metadc70437/' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': same data as 1025 steel, calculated from the mean coefficient of thermal expansion']);
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').set('dL', {'(dL(T)-dL(Tempref))/(1+dL(Tempref))' '0' '0' '0' '(dL(T)-dL(Tempref))/(1+dL(Tempref))' '0' '0' '0' '(dL(T)-dL(Tempref))/(1+dL(Tempref))'});
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').set('INFO_PREFIX:dL', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': MIL-HDBK-5H, 1 Dec 1998 p2-9 and R.J. Corruccini and J.J. Gniewek, Thermal Expansion of Technical Solids at Low Temperatures: A Compilation From the Literature, NBS Monograph 29 (1961) https://digital.library.unt.edu/ark:/67531/metadc70437/' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': the reference temperature is 20 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (293 K), same data as 1025 steel, calculated from the mean coefficient of thermal expansion' newline  native2unicode(hex2dec({'53' 'c2'}), 'unicode')  native2unicode(hex2dec({'80' '03'}), 'unicode')  native2unicode(hex2dec({'6e' '29'}), 'unicode')  native2unicode(hex2dec({'5e' 'a6'}), 'unicode') ': 293.00[K]']);
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').addInput('temperature');
    model.component('comp1').material('mat1').propertyGroup('ThermalExpansion').addInput('strainreferencetemperature');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('E').label('Piecewise');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('E').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('E').set('pieces', {'4.0' '273.0' '2.217366E11+5020008.0*T^1-305140.4*T^2+926.6601*T^3-1.145454*T^4'; '273.0' '1050.0' '2.11026989E11+3.572844E7*T^1-106319.6*T^2'; '1050.0' '1500.0' '2.02449497E11-6.77381E7*T^1'});
    model.component('comp1').material('mat1').propertyGroup('Enu').func('E').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('E').set('fununit', 'Pa');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('nu').label('Piecewise 1');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('nu').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('Enu').func('nu').set('pieces', {'4.0' '120.0' '0.2850355-1.662951E-6*T^1';  ...
        '120.0' '273.0' '0.28474914-7.147353E-6*T^1+6.558945E-8*T^2';  ...
        '273.0' '1053.0' '0.271114512+7.030261E-5*T^1-3.856929E-8*T^2+1.246582E-11*T^3';  ...
        '1053.0' '1500.0' '0.316398425-1.242823E-6*T^1+1.661461E-9*T^2'});
    model.component('comp1').material('mat1').propertyGroup('Enu').func('nu').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('Enu').set('E', 'E(T)');
    model.component('comp1').material('mat1').propertyGroup('Enu').set('INFO_PREFIX:E', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': M. Fukuhara and A. Sanpei, ISIJ International, v33, No. 4, p508 (1993) https://doi.org/10.2355/isijinternational.33.508 and J.A. Rayne and B.S. Chandrasekhar, Physical Review, v122, p1714 (1961) https://doi.org/10.1103/PhysRev.122.1714' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values for plain carbon and low alloy steels, values below 0 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (273 K) were calculated with C11, C12 and C44 from the average of Voigt and Reuss values']);
    model.component('comp1').material('mat1').propertyGroup('Enu').set('nu', 'nu(T)');
    model.component('comp1').material('mat1').propertyGroup('Enu').set('INFO_PREFIX:nu', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': M. Fukuhara and A. Sanpei, ISIJ International, v33, No. 4, p508 (1993) https://doi.org/10.2355/isijinternational.33.508 and J.A. Rayne and B.S. Chandrasekhar, Physical Review, v122, p1714 (1961) https://doi.org/10.1103/PhysRev.122.1714' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values for plain carbon and low alloy steels, values below 0 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (273 K) were calculated with C11, C12 and C44 from the average of Voigt and Reuss values']);
    model.component('comp1').material('mat1').propertyGroup('Enu').addInput('temperature');
    model.component('comp1').material('mat1').propertyGroup('KG').func('mu').label('Piecewise');
    model.component('comp1').material('mat1').propertyGroup('KG').func('mu').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('KG').func('mu').set('pieces', {'4.0' '273.0' '8.626526E10+1636497.0*T^1-108981.6*T^2+291.1261*T^3-0.3377859*T^4'; '273.0' '1050.0' '8.30237093E10+9184755.0*T^1-38834.5*T^2'; '1050.0' '1500.0' '7.69464143E10-2.580357E7*T^1'});
    model.component('comp1').material('mat1').propertyGroup('KG').func('mu').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('KG').func('mu').set('fununit', 'Pa');
    model.component('comp1').material('mat1').propertyGroup('KG').func('kappa').label('Piecewise 1');
    model.component('comp1').material('mat1').propertyGroup('KG').func('kappa').set('arg', 'T');
    model.component('comp1').material('mat1').propertyGroup('KG').func('kappa').set('pieces', {'4.0' '100.0' '1.800573E11-3478717.0*T^1+151512.1*T^2-5485.327*T^3+28.28329*T^4'; '100.0' '273.0' '1.81842391E11-4.023792E7*T^1+84204.68*T^2-93.09453*T^3'; '273.0' '1500.0' '1.84220483E11-2.509462E7*T^1-28588.37*T^2'});
    model.component('comp1').material('mat1').propertyGroup('KG').func('kappa').set('argunit', 'K');
    model.component('comp1').material('mat1').propertyGroup('KG').func('kappa').set('fununit', 'Pa');
    model.component('comp1').material('mat1').propertyGroup('KG').set('K', 'kappa(T)');
    model.component('comp1').material('mat1').propertyGroup('KG').set('INFO_PREFIX:K', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': M. Fukuhara and A. Sanpei, ISIJ International, v33, No. 4, p508 (1993) https://doi.org/10.2355/isijinternational.33.508 and J.A. Rayne and B.S. Chandrasekhar, Physical Review, v122, p1714 (1961) https://doi.org/10.1103/PhysRev.122.1714' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values for plain carbon and low alloy steels, values below 0 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (273 K) were calculated with C11, C12 and C44 from the average of Voigt and Reuss values and were increased by 6% to match the high temperature values']);
    model.component('comp1').material('mat1').propertyGroup('KG').set('G', 'mu(T)');
    model.component('comp1').material('mat1').propertyGroup('KG').set('INFO_PREFIX:G', [native2unicode(hex2dec({'5f' '15'}), 'unicode')  native2unicode(hex2dec({'75' '28'}), 'unicode') ': M. Fukuhara and A. Sanpei, ISIJ International, v33, No. 4, p508 (1993) https://doi.org/10.2355/isijinternational.33.508 and J.A. Rayne and B.S. Chandrasekhar, Physical Review, v122, p1714 (1961) https://doi.org/10.1103/PhysRev.122.1714' newline  native2unicode(hex2dec({'6c' 'e8'}), 'unicode') ': approximate values for plain carbon and low alloy steels, values below 0 ' native2unicode(hex2dec({'00' 'b0'}), 'unicode') 'C (273 K) were calculated with C11, C12 and C44 from the average of Voigt and Reuss values']);
    model.component('comp1').material('mat1').propertyGroup('KG').addInput('temperature');
end

