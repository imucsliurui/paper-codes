function [bap_p_mlpg,ap_p_mlpg] = gen_ap(bap_p_deltas,bapdim,nfftby2,vo,outvec_bap)

% Purpose : Compute BAP distortion and convert them to aperiodicity params

% load sptk commands
sptk_cmd

% BAP distortion
bap_p = bap_p_deltas(:,1:bapdim);


% Convert bap to ap
[ap_p] = bap2ap(bap_p,nfftby2);

% MLPG for band-aperiodicity
S = vo(outvec_bap).^2;
[bap_p_mlpg] = mlpg(S,bap_p_deltas);
bap_p_mlpg = bap_p_mlpg(2:end-1,1:bapdim);

[ap_p_mlpg] = bap2ap(bap_p_mlpg,nfftby2);

end