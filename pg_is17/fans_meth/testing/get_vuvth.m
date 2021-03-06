% Purpose : Test RNN

clear all; close all; clc;

% config

config_IndicTTS
acousticparam_config

% read data
load(strcat(statdir,'mvni.mat'))
load(strcat(statdir,'mvno.mat'))
%testdataname = strcat('train',num2str(1),'.mat');
%readtestdata
din = length(m);
dout = length(mo);

% architecture init
arch_name1 = strcat(arch_name1,num2str(dout),ol_type);
arch_init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tot_trainbats = 2000;
vuvth_utt = zeros(tot_trainbats,1);
vuvth_vec       = [0.2:0.01:0.9];
vuvth_vec_orig  = [0.2:0.01:0.9];
err_vuv_mat     = zeros(tot_trainbats,length(vuvth_vec));


lang_list = {'tel','tam','kan','mal','hin'};

for j = 1:length(lang_list)
    
    datadir = strcat('../../../../../../../',lang_list{j},'/M/nnspss/matfiles_16KHz/');
    nb = dir(strcat(datadir,'train*'));
    nb = length(nb);
    
    for i = 1%:nb
        
        data = [];
        clv = [];
        total_err = 0;
        testdataname = strcat('train',num2str(i),'.mat');
        readtestdata
        
        % error computation
        for li = 1:test_numbats
            fprintf('Processing batch no %d; lang %d; file %d of %d ... \n',i,j,li,test_numbats);
            
            [X,Y,sl] = get_XY_seqver(test_batchdata, test_batchtargets, test_clv, (1:test_numbats), li, gpu_flag);
            
            fp_model
            
            switch cfn
                case 'nll'
                    me = compute_zerooneloss(ol_mat,Y);
                case 'ls'
                    me = compute_nmlMSE(ol_mat,Y);
            end
            
            
            total_err = total_err + me/test_numbats;
            
            % Optimum Transformation Parameter Estimation using Min. GV Error Criterion
            % denormalize
            pcmp_deltas = denormalize(ol_mat,mo,vo,outvec,outtmvnf);
            ocmp_deltas = denormalize(Y,mo,vo,outvec,outtmvnf);
            
            % Compute VUV (% error)
            pvuv = pcmp_deltas(:,232); % for error computation
            gvuv = ocmp_deltas(:,232);
            gvuv(gvuv<0.2) = 0;
            gvuv(gvuv>=0.2) = 1;
            
            len_gvuv = length(gvuv);
            len_pvuv = length(pvuv);
            
            if len_gvuv > len_pvuv
                gvuv = gvuv(1:len_pvuv);
            else
                pvuv = pvuv(1:len_gvuv);
            end
            
            for vix = 1:length(vuvth_vec)
                vuvth = vuvth_vec(vix);
                pvuv_final = zeros(size(pvuv));
                pvuv_final(pvuv > vuvth) = 1;
                err_vuv_mat(li+ (j-1)*400,vix) = ((sum(abs(pvuv_final - gvuv))/length(gvuv))*100);
            end
            
        end
        total_err
    end
    
end


err_vuv_mean = mean(err_vuv_mat);
[minval,minix] = min(err_vuv_mean);
vuvth_final = vuvth_vec_orig(minix)
save(strcat(model_stats_dir,'vuvth.mat'),'vuvth_final');
