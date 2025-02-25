function img = make_grating(TrialRecord, MLConfig)
% MKLG GEN function, called by the conditions file / userloop to generate gratings.
 
% Prerequisite variables (HARDCODED):
lab = "Ray"; % Required for retrieving the correct monitor specifications when working across labs

% read required variables from TrialRecord struct
stim_per_trial = TrialRecord.Editable.stim_per_trial; % TrialRecord.User.conds_per_trial;
stim_idx = TrialRecord.User.stim_idx;

var_list = string(fieldnames(TrialRecord.CurrentConditionInfo))';
var_subset = var_list(stim_idx:stim_per_trial:end);

% get monitor details
view_dist = MLConfig.ViewingDistance;
[X, Y] = monitor_XY_deg(view_dist=view_dist, lab=lab);

RF = TrialRecord.CurrentConditionInfo.(var_subset(1)); % Receptive Field condition (IN/OUT)
azi = TrialRecord.CurrentConditionInfo.(var_subset(2)); % Azimuth (dva)
ele = TrialRecord.CurrentConditionInfo.(var_subset(3)); % Elevation (dva)
r = TrialRecord.CurrentConditionInfo.(var_subset(4)); % Aperture radius (dva)
sf = TrialRecord.CurrentConditionInfo.(var_subset(5)); % Spatial Frequency (cpd)
ori = TrialRecord.CurrentConditionInfo.(var_subset(6)); % Orientation (deg)
con = TrialRecord.CurrentConditionInfo.(var_subset(7)); % Contrast (%)

% Fullscreen grating display:
X_ = (X - azi)*cosd(ori) + (Y - ele)*sind(ori); % Shifted and rotated X coordinate grid
img = flipud(uint8((255/2)*(con*1e-2*sin(2*pi*sf*X_) + 1))); % Sinusoidal grating applied to X_, to obtain a grating with desired sf, ori, and con

circ = @(X, Y, azi, ele, r) (((X - azi).^2 + (Y - ele).^2) <= r^2); % Anon function for circular boundaries
mask_in = flipud(circ(X, Y, azi, ele, r));
mask_out = ~mask_in;

% Introducing mask:
if RF == "IN"
    img(mask_out) = 128;
elseif RF == "OUT"
    img(mask_in) = 128;
end

TrialRecord.User.stim_idx = stim_idx+1;
end