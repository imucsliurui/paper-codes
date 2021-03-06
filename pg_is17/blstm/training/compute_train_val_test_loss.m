% Check Validation Loss
if mod(num_up,check_valfreq) == 0
    
    tic
    [train_err] = compute_error(train_batchdata,train_batchtargets,train_clv,train_test_numbats,Wzf,Rzf,bzf,Wif,Rif,pif,bif,Wff,Rff,pff,bff,Wof,Rof,pof,bof,Uf,bu, ...
        Wzb,Rzb,bzb,Wib,Rib,pib,bib,Wfb,Rfb,pfb,bfb,Wob,Rob,pob,bob,Ub,f,nl,cfn);
    toc
    
    tic
    [val_err] = compute_error(val_batchdata,val_batchtargets,val_clv,val_numbats,Wzf,Rzf,bzf,Wif,Rif,pif,bif,Wff,Rff,pff,bff,Wof,Rof,pof,bof,Uf,bu, ...
        Wzb,Rzb,bzb,Wib,Rib,pib,bib,Wfb,Rfb,pfb,bfb,Wob,Rob,pob,bob,Ub,f,nl,cfn);
    toc
    
    fprintf('Epoch: %d, Train Loss: %f; Val Loss : %f \n',NE,train_err,val_err);
    
    if val_err < best_val_err
        
        best_val_err = val_err;
        best_epoch = NE;
        
        tic
        [test_err] = compute_error(test_batchdata,test_batchtargets,test_clv,test_numbats,Wzf,Rzf,bzf,Wif,Rif,pif,bif,Wff,Rff,pff,bff,Wof,Rof,pof,bof,Uf,bu, ...
            Wzb,Rzb,bzb,Wib,Rib,pib,bib,Wfb,Rfb,pfb,bfb,Wob,Rob,pob,bob,Ub,f,nl,cfn);
        toc
        
        % Print error (testing) per epoc
        fprintf('\t Epoch : %d  Update: %d Test Loss : %f \n',NE,num_up,test_err);
        
        % save weight ifle
        save_params
    end
    
    % Print error (validation and testing) per epoc
    fprintf(fid,'%d %d %f %f %f \n',NE,num_up,train_err,val_err,test_err);
end