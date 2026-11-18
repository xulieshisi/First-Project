function afd = gpr_adaptive_lsdtd_coefficients(epsrModel, ds, fmax, M, varargin)
%GPR_ADAPTIVE_LSDTD_COEFFICIENTS 计算GPR自适应最小二乘交错网格差分系数。
%
% afd = gpr_adaptive_lsdtd_coefficients(epsrModel, ds, fmax, M)
% 根据相对介电常数、网格间距、最高有效频率和差分阶数，计算Maxwell方程一阶空间导数的自适应LSDTD系数。
%
% 理论关系：局部相对介电常数 -> 局部电磁波速度 -> 局部波数范围 -> 局部最小二乘差分系数。
%
% 输入参数
%   epsrModel : 相对介电常数，可以是一个数、一组数、二维矩阵或三维模型。
%   ds        : 空间网格间距，单位为m。
%   fmax      : 雷达子波最高有效频率，单位为Hz。
%   M         : 差分模板半宽，M=4时求c1...c4。
%
% 可选参数
%   'Mode'              : 'rtm'表示零时刻RTM反传速度取v/2；'forward'表示正演速度取v。
%   'EpsrSamples'       : 自主指定要求系数的相对介电常数采样点。
%   'NumTable'          : 未指定EpsrSamples时，自动生成的介电常数表长度。
%   'UseAngularMapping' : false表示严格使用[0,b]一维最小二乘公式；true表示加入三维传播角度扩展。
%   'NumTheta'          : 三维角度扩展时的极角采样数。
%   'NumPhi'            : 三维角度扩展时的方位角采样数。
%   'Wavelet'           : 可选雷达子波；若不输入，则默认频带[0,fmax]内各频率等权。
%   'Dt'                : Wavelet对应的时间采样间隔。
%   'NumFreq'           : 默认等权频带的频率采样点数。
%   'BetaLimit'         : 数值优化允许的最大无量纲波数上限，默认pi。
%   'ReturnCoeffGrid'   : true时返回每个网格点对应的c1...cM系数数组。
%
% 输出结果
%   afd.coeffTable      : 系数表，每一行对应一个介电常数采样点，每一列为c1...cM。
%   afd.epsrTable       : 实际用于求系数的相对介电常数表。
%   afd.velocityTable   : 每个介电常数对应的计算速度。
%   afd.betaRawTable    : 每个介电常数对应的理论b=2*pi*fmax*ds/v。
%   afd.betaMaxTable    : 实际用于优化的b，等于min(betaRawTable,BetaLimit)。
%   afd.indexMap        : epsrModel中每个网格点对应coeffTable的查表索引。
%   afd.coeffGrid       : 可选输出，每个网格点对应的c1...cM。
%
% 优化目标：2*sum_m c_m sin((m-1/2)*beta)逼近beta。
% 约束条件：2*sum_m c_m*(m-1/2)=1。

ip = inputParser; % 创建输入参数解析器
ip.addParameter('Mode', 'rtm'); % 默认用于零时刻RTM，速度取实际电磁波速度的一半
ip.addParameter('EpsrSamples', []); % 用户自主指定要求系数的相对介电常数
ip.addParameter('NumTable', 64); % 自动生成介电常数表时的采样数量
ip.addParameter('UseAngularMapping', false); % 默认严格使用理论中的一维[0,b]最小二乘公式
ip.addParameter('NumTheta', 13); % 三维角度扩展时的极角采样数
ip.addParameter('NumPhi', 13); % 三维角度扩展时的方位角采样数
ip.addParameter('Wavelet', []); % 可选输入雷达子波，用其频谱作为最小二乘权重
ip.addParameter('Dt', []); % 雷达子波的时间采样间隔
ip.addParameter('NumFreq', 256); % 未输入子波时的频率采样点数
ip.addParameter('BetaLimit', pi); % 无量纲奈奎斯特波数上限为pi
ip.addParameter('ReturnCoeffGrid', false); % 是否输出每个网格点的系数数组
ip.addParameter('CoefficientRegularization', 0);
ip.parse(varargin{:}); % 解析可选参数
opt = ip.Results; % 保存解析后的参数

validateattributes(epsrModel, {'numeric'}, {'real','positive','nonempty'}); % 相对介电常数必须为正实数
validateattributes(ds, {'numeric'}, {'real','positive','scalar'}); % 网格间距必须为正标量
validateattributes(fmax, {'numeric'}, {'real','positive','scalar'}); % 最高有效频率必须为正标量
validateattributes(M, {'numeric'}, {'integer','positive','scalar'}); % 差分模板半宽必须为正整数
validateattributes(opt.CoefficientRegularization, {'numeric'}, ...
    {'real','finite','scalar','nonnegative'});

epsrMin = min(epsrModel(:)); % 模型中的最小相对介电常数
epsrMax = max(epsrModel(:)); % 模型中的最大相对介电常数
if isempty(opt.EpsrSamples)
    if abs(epsrMax - epsrMin) < eps(epsrMax)
        epsrTable = epsrMin; % 均匀模型只需要一组系数
    else
        epsrTable = linspace(epsrMin, epsrMax, opt.NumTable); % 根据模型范围自动生成介电常数采样表
    end
else
    epsrTable = sort(opt.EpsrSamples(:).'); % 使用用户自主指定的相对介电常数采样点
    validateattributes(epsrTable, {'numeric'}, {'real','positive','nonempty'}); % 指定采样点必须为正实数
end

c0 = 299792458; % 真空光速，单位m/s
vPhysical = c0 ./ sqrt(epsrTable); % GPR电磁波实际传播速度v=c0/sqrt(epsr)
if strcmpi(opt.Mode, 'rtm')
    velocityTable = 0.5 * vPhysical; % 零时刻RTM反传速度取实际速度的一半
elseif strcmpi(opt.Mode, 'forward')
    velocityTable = vPhysical; % 正演时使用实际电磁波速度
else
    error('Mode must be ''rtm'' or ''forward''.');
end

[freq, freqWeight] = local_frequency_weights(fmax, opt); % 生成频率采样点和频谱权重
[dirCos, dirWeight] = local_direction_weights(opt); % 生成方向余弦权重，默认只有1

nTable = numel(epsrTable); % 需要求解的介电常数采样点数量
coeffTable = zeros(nTable, M); % 系数表，每行对应一个介电常数
betaRawTable = zeros(nTable, 1); % 保存理论最大无量纲波数b_raw=2*pi*fmax*ds/v
betaMaxTable = zeros(nTable, 1); % 保存实际用于优化的最大无量纲波数b_used

for it = 1:nTable
    v = velocityTable(it); % 当前介电常数对应的计算速度
    betaRawTable(it) = 2*pi*fmax*ds/v; % 理论中的b(r)=kmax(r)*ds
    beta0 = 2*pi*freq(:)*ds./v; % beta=k*ds=2*pi*f*ds/v
    keep = beta0 > 0 & beta0 <= opt.BetaLimit; % 只保留有效波数范围
    beta0 = beta0(keep); % 当前介电常数对应的无量纲波数采样
    w0 = freqWeight(keep); % 当前波数采样对应的权重

    betaMaxTable(it) = min(betaRawTable(it), opt.BetaLimit); % 实际用于优化的b不能超过奈奎斯特上限
    if isempty(beta0)
        warning('No usable frequency samples for epsr=%g. Using Taylor M=1 fallback.', epsrTable(it));
        coeffTable(it,1) = 1; % 极端参数下退化为二阶FDTD
        continue;
    end

    if opt.UseAngularMapping
        beta = []; % 三维角度扩展后的beta集合
        w = []; % 三维角度扩展后的权重集合
        for id = 1:numel(dirCos)
            beta = [beta; beta0 .* dirCos(id)]; %#ok<AGROW>
            w = [w; w0 .* dirWeight(id)]; %#ok<AGROW>
        end
    else
        beta = beta0; % 默认严格使用理论公式中的[0,b]一维波数区间
        w = w0; % 默认使用频率权重
    end

    keep = beta > 1e-10 & beta <= opt.BetaLimit & w > 0; % 删除零波数和无效权重
    beta = beta(keep); % 最终用于最小二乘的beta
    w = w(keep); % 最终用于最小二乘的权重
    coeffTable(it,:) = local_solve_staggered_coeff(beta, w, M, ...
        opt.CoefficientRegularization); % 求解当前介电常数对应的c1...cM
end

indexMap = local_nearest_index(epsrModel, epsrTable); % 每个网格点对应的介电常数查表索引

afd = struct(); % 输出结构体
afd.coeffTable = coeffTable; % 自适应最小二乘差分系数表
afd.epsrTable = epsrTable(:); % 介电常数采样表
afd.velocityTable = velocityTable(:); % 每个介电常数对应的计算速度
afd.betaRawTable = betaRawTable(:); % 每个介电常数对应的理论b值
afd.betaMaxTable = betaMaxTable(:); % 每个介电常数对应的实际优化b值
afd.indexMap = indexMap; % 模型网格点到系数表的索引
afd.ds = ds; % 空间网格间距
afd.fmax = fmax; % 最高有效频率
afd.M = M; % 差分模板半宽
afd.mode = opt.Mode; % 计算模式
afd.formula = '2*sum(c_m*sin((m-1/2)*beta)) ~= beta'; % 对应的差分响应公式
afd.coefficientRegularization = opt.CoefficientRegularization;

if opt.ReturnCoeffGrid
    sz = size(epsrModel); % 原始介电常数模型尺寸
    coeffGrid = zeros([sz, M], 'like', epsrModel); % 每个网格点的c1...cM数组
    for m = 1:M
        cm = coeffTable(:,m); % 当前阶数的系数列
        coeffGridSubs = cm(double(indexMap)); % 根据索引图查出每个网格点的系数
        coeffGridSubs = reshape(coeffGridSubs, sz); % 恢复为介电常数模型尺寸
        idx = repmat({':'}, 1, ndims(epsrModel)); % 适配二维或三维模型的索引
        coeffGrid(idx{:}, m) = coeffGridSubs; % 写入第m个系数分量
    end
    afd.coeffGrid = coeffGrid; % 输出逐网格点系数
end
end

function [freq, weight] = local_frequency_weights(fmax, opt)
if isempty(opt.Wavelet)
    freq = linspace(0, fmax, opt.NumFreq).'; % 在[0,fmax]内均匀采样频率
    freq = freq(2:end); % 去掉零频点
    weight = ones(size(freq)); % 不输入子波时，各频率等权
else
    if isempty(opt.Dt)
        error('Dt is required when Wavelet is supplied.');
    end
    wv = opt.Wavelet(:); % 雷达子波列向量
    nfft = 2^nextpow2(max(numel(wv)*4, 256)); % FFT长度
    spec = abs(fft(wv, nfft)); % 子波振幅谱
    nf = floor(nfft/2) + 1; % 正频率点数
    freq = (0:nf-1).' ./ (nfft * opt.Dt); % 频率轴
    amp = spec(1:nf); % 正频率振幅谱
    keep = freq > 0 & freq <= fmax & amp > max(amp)*1e-6; % 保留有效频带
    freq = freq(keep); % 有效频率采样
    amp = amp(keep); % 有效频率对应振幅
    weight = amp.^2; % 使用能量谱作为最小二乘权重
end
weight = weight(:) ./ max(weight(:)); % 权重归一化
end

function [dirCos, dirWeight] = local_direction_weights(opt)
if ~opt.UseAngularMapping
    dirCos = 1; % 默认不做角度扩展
    dirWeight = 1; % 默认方向权重为1
    return;
end

theta = linspace(0, pi/2, opt.NumTheta); % 第一卦限极角采样
phi = linspace(0, pi/2, opt.NumPhi); % 第一卦限方位角采样
dirCos = []; % 保存方向余弦
dirWeight = []; % 保存方向权重
for it = 1:numel(theta)
    for ip = 1:numel(phi)
        st = sin(theta(it)); % 球坐标权重项
        nx = abs(st*cos(phi(ip))); % x方向方向余弦
        ny = abs(st*sin(phi(ip))); % y方向方向余弦
        nz = abs(cos(theta(it))); % z方向方向余弦
        wt = max(st, 1e-3); % 避免极点权重为0
        dirCos = [dirCos; nx; ny; nz]; %#ok<AGROW>
        dirWeight = [dirWeight; [wt; wt; wt]./3]; %#ok<AGROW>
    end
end
keep = dirCos > 1e-8; % 删除近似为零的方向投影
dirCos = dirCos(keep); % 有效方向余弦
dirWeight = dirWeight(keep); % 有效方向权重
dirWeight = dirWeight ./ mean(dirWeight); % 方向权重归一化
end

function c = local_solve_staggered_coeff(beta, weight, M, regularization)
m = 1:M; % 系数编号
A = 2*sin(beta(:) * (m - 0.5)); % 差分算子频率响应矩阵
d = beta(:); % 理想一阶导数频率响应
w = sqrt(weight(:) ./ max(weight(:))); % 最小二乘权重的平方根
Aw = A .* w; % 加权后的系数矩阵
dw = d .* w; % 加权后的目标向量

E = 2*(m - 0.5); % 低波数一致性约束系数
if regularization > 0
    prior = local_taylor_staggered_coeff(M);
    normalMatrix = Aw.'*Aw + regularization*eye(M);
    normalRhs = Aw.'*dw + regularization*prior(:);
else
    normalMatrix = Aw.'*Aw;
    normalRhs = Aw.'*dw;
end
rhs = [normalRhs; 1]; % KKT方程右端项
K = [normalMatrix, E.'; E, 0]; % 带约束最小二乘KKT矩阵
sol = K \ rhs; % 求解带约束最小二乘
c = sol(1:M).'; % 输出c1...cM
end

function c = local_taylor_staggered_coeff(M)
% 用交错网格泰勒展开构造稳定的高阶先验系数。
m = (1:M) - 0.5;
B = zeros(M, M);
rhs = zeros(M, 1);
for p = 0:(M-1)
    B(p+1,:) = 2*(-1)^p/factorial(2*p+1) .* m.^(2*p+1);
end
rhs(1) = 1;
c = (B \ rhs).';
end

function indexMap = local_nearest_index(epsrModel, epsrTable)
if numel(epsrTable) == 1
    indexMap = ones(size(epsrModel), 'uint16'); % 均匀模型所有点都使用第1组系数
    return;
end

edges = [-inf, (epsrTable(1:end-1) + epsrTable(2:end))/2, inf]; % 最近邻查表分界点
[~,~,bin] = histcounts(epsrModel, edges); % 计算每个网格点对应的表索引
indexMap = uint16(bin); % 使用整数索引节省内存
end
