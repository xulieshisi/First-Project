function epsr = gpr_uniform_permittivity_model_epsr20(X, Z)
%GPR_UNIFORM_PERMITTIVITY_MODEL_EPSR20 Uniform relative-permittivity model.
% The whole 2-D model uses epsr = 20, matching the lower half-space of the
% epsr10_15_20_25_30_bg20 semicircular model.

validateattributes(X, {'numeric'}, {'real','finite'});
validateattributes(Z, {'numeric'}, {'real','finite','size',size(X)});

epsr = 20*ones(size(X), 'like', X);
end
