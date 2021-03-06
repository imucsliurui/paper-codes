%{
###########################################################################
##                                                                       ##
##                                                                       ##
##                       IIIT Hyderabad, India                           ##
##                      Copyright (c) 2015                               ##
##                        All Rights Reserved.                           ##
##                                                                       ##
##  Permission is hereby granted, free of charge, to use and distribute  ##
##  this software and its documentation without restriction, including   ##
##  without limitation the rights to use, copy, modify, merge, publish,  ##
##  distribute, sublicense, and/or sell copies of this work, and to      ##
##  permit persons to whom this work is furnished to do so, subject to   ##
##  the following conditions:                                            ##
##   1. The code must retain the above copyright notice, this list of    ##
##      conditions and the following disclaimer.                         ##
##   2. Any modifications must be clearly marked as such.                ##
##   3. Original authors' names are not deleted.                         ##
##   4. The authors' names are not used to endorse or promote products   ##
##      derived from this software without specific prior written        ##
##      permission.                                                      ##
##                                                                       ##
##  IIIT HYDERABAD AND THE CONTRIBUTORS TO THIS WORK                     ##
##  DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING      ##
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT   ##
##  SHALL IIIT HYDERABAD NOR THE CONTRIBUTORS BE LIABLE                  ##
##  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    ##
##  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN   ##
##  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,          ##
##  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF       ##
##  THIS SOFTWARE.                                                       ##
##                                                                       ##
###########################################################################
##                                                                       ##
##          Author :  Sivanand Achanta (sivanand.a@research.iiit.ac.in)  ##
##          Date   :  Jul. 2015                                          ##
##                                                                       ##
###########################################################################
%}

function [] = call_traindnn_fn(archname,sgd_type,spec_flag,f0_flag,mgcp_flag,f0p_flag,lno,hmvnf)

% Load configuration file
config

% Step 1 : Read data
readdata_rnn_v2

% Load RNN weights
lno = str2num(lno); % 1 - hidden layer ; 2 - output layer

spec_flag = str2num(spec_flag); % RNN trained on spectrum
f0_flag = str2num(f0_flag); % RNN trained on f0

if spec_flag
    % rnn_archname = '247L500R150L_rnn_di_l20_lr0.003_mf0.3_gc1_si0.01_ri0.1_so0.01_5';
    rnn_archname = '247L500R150L_rnn_lw_l20_lr3e-05_mf0.3_gc1_si0.01_ri0.1_so0.01_rnn_mvni_mvno_30';
    load(strcat(wtdir,'W_',rnn_archname,'.mat'))
    f_mgc  = 'RL'
    nl_mgc = [247 500 150];
    Wi_mgc = Wi; Wfr_mgc = Wfr; U_mgc = U;
    bh_mgc = bh; bo_mgc = bo;
    nl_rnn = nl_mgc; f_rnn = f_mgc;
    strmvn = 'mgc'; 
    hmvnf = str2num(hmvnf);
    if hmvnf
    compute_hiddenrep_stats
    load(strcat(datadir,'mvn_h_',strmvn,'.mat'));

    if lno == 2
       mh = my; 
       vh = vy;
    end
    mh_spec = mh;
    vh_spec = vh;
    end
end

if f0_flag
    rnn_archname = '247L250R4L_rnn_di_l20_lr0.01_mf0.3_gc1_si0.04_ri0.1_so0.25_rnn_mvni_mvno_39';
    load(strcat(wtdir,'W_',rnn_archname,'.mat'))
    f_f0  = 'RL'
    nl_f0 = [247 250 4];
    nl_rnn = nl_f0; f_rnn = f_f0;
    
    Wi_f0  = Wi; Wfr_f0 = Wfr; U_f0 = U;
    bh_f0  = bh; bo_f0 = bo;
    strmvn = 'f0';

    if ~spec_flag;    hmvnf = str2num(hmvnf);    end;
 
    if hmvnf
    compute_hiddenrep_stats
    load(strcat(datadir,'mvn_h_',strmvn,'.mat'));
    if lno == 2
       mh = my; 
       vh = vy;
    end

    mh_f0 = mh;
    vh_f0 = vh;
    end
end



% Step 2 : Set architecture
if spec_flag && f0_flag
din = din + nl_mgc(lno+1) + nl_f0(lno+1) ;
else
  if spec_flag; din = din + nl_mgc(lno+1);end;
  if f0_flag; din = din + nl_f0(lno+1); end;
end

arch_name1 = strcat(arch_name1,num2str(dout),ol_type);
arch_init

% set hyper params
switch sgd_type
    
    case 'sgdcm'
        
        % Training DNN using Naive SGD with classical momentum
        
        disp('training with SGD-CM optimizer ...');
        
        for l2 = l2_vec
            for lr = lr_vec
                for mf = mf_vec
                    
                    % Step 4 : Weight initialization
                    wt_init
                    
                    arch_name2 = strcat('_l2',num2str(l2),'_lr',num2str(lr),'_mf',num2str(mf),'_',wtinit_meth,'_rnnmgcf0',num2str(spec_flag),num2str(f0_flag),'_',in_nml_meth,'_',out_nml_meth,'_hmvnf',num2str(hmvnf));
                    arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                    
                    if gpu_flag
                        disp('training on GPU !!! :) ');
                        Gb = gpuArray(b);  GW = gpuArray(W);
                        Gpdb = gpuArray(zeros(size(b)));  GpdW = gpuArray(zeros(size(W)));
                    else
                        disp('training on CPU ... ');
                        Gb = b;  GW = W;
                        Gpdb = zeros(size(b));  GpdW = zeros(size(W));
                    end
                    
                    trainer
                    
                end
            end
            
        end
        
        
    case 'adadelta'
        
        % Training DNN using ADA-DELTA
        % Ref : ADADELTA: An Adaptive Learning Rate Method - Matthew Zeiler
        
        disp('training with ADA-DELTA optimizer ...');      
        
        for l2 = l2_vec
            for rho = rho_vec
                for eps = eps_vec
                    for mf = mf_vec
                        
                        % Step 4 : Weight initialization
                        wt_init
                        
                        arch_name2 = strcat('_l2',num2str(l2),'_rho',num2str(rho),'_eps',num2str(eps),'_mf',num2str(mf),'_',wtinit_meth,'_rnnmgcf0',num2str(spec_flag),num2str(f0_flag),'_',in_nml_meth,'_',out_nml_meth,'_hmvnf',num2str(hmvnf))
                        arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                        
                        if gpu_flag
                            disp('training on GPU ... :( ');
                            Gb = gpuArray(b);
                            GW = gpuArray(W);
                            Gpdb = gpuArray(zeros(size(b)));  GpdW = gpuArray(zeros(size(W)));
                            Gpmsgbt = gpuArray(zeros(1,btl(end)-1));  GpmsgWt = gpuArray(zeros(1,wtl(end)-1));
                            Gpmsxbt = gpuArray(zeros(1,btl(end)-1));  GpmsxWt = gpuArray(zeros(1,wtl(end)-1));
                            
                        else
                            disp('training on CPU ... ');
                            Gb = b;  GW = W;
                            Gpdb = zeros(size(b));  GpdW = zeros(size(W));
                            Gpmsgbt = zeros(1,btl(end)-1);  GpmsgWt = zeros(1,wtl(end)-1);
                            Gpmsxbt = zeros(1,btl(end)-1);  GpmsxWt = zeros(1,wtl(end)-1);
                            
                        end
                        
                        trainer
                        
                    end
                end
            end
            
        end
        
    case 'adam'
        
        % Training DNN using ADAM - SGD
        % Ref: ADAM : A Method For Stochastic Optimization - ICLR 2015 - D.P.Kingma and J.L.Ba
        
        disp('training with ADAM optimizer ... ');

        for l2 = l2_vec
            for alpha = alpha_vec
                for beta1 = beta1_vec
                    for beta2 = beta2_vec
                        
                        % Step 4 : Weight initialization
                        wt_init
                        
                        arch_name2 = strcat('_l2',num2str(l2),'alpha',num2str(alpha),'_b1',num2str(beta1),'_b2',num2str(beta2),'_',wtinit_meth,'_rnnmgcf0',num2str(spec_flag),num2str(f0_flag),'_',in_nml_meth,'_',out_nml_meth,'_hmvnf',num2str(hmvnf));
                        arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                        
                        if gpu_flag
                            fprintf('training on GPU !!! :) \n');
                            Gb = gpuArray(b);
                            GW = gpuArray(W);
                            Gpmbt = gpuArray(zeros(1,btl(end)-1));
                            GpmWt = gpuArray(zeros(1,wtl(end)-1));
                            Gpvbt = gpuArray(zeros(1,btl(end)-1));
                            GpvWt = gpuArray(zeros(1,wtl(end)-1));
                            
                        else
                            disp('training on CPU ... ');
                            Gb = b;  GW = W;
                            Gpmbt = zeros(1,btl(end)-1);  GpmWt = zeros(1,wtl(end)-1);
                            Gpvbt = zeros(1,btl(end)-1);  GpvWt = zeros(1,wtl(end)-1);
                            
                        end
                        
                        trainer
                        
                    end
                end
            end
        end
        
        
end

