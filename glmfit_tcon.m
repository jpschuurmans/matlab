function tscore = glmfit_tcon(dm, con, betas, stats)
    var_est = stats.resid' * stats.resid / stats.dfe;
    if size(betas,1) > size(betas,2)
        betas = betas';
    end
    beta_con = betas * con';
    tscore = beta_con ./ sqrt(con * pinv(dm) * var_est * pinv(dm)' * con');

