function h = hrf(timestep, duration)

    t = 1:timestep:duration; % MEASUREMENTS
    h = gampdf(t,6) + -.5*gampdf(t,10); % HRF MODEL
    h = h/max(h); % SCALE HRF TO HAVE MAX AMPLITUDE OF 1
