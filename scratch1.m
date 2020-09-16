[4, 8, 12]/270

screen_height_pix = 1080
screen_height_cm = 39
screen_distance_cm = 200
screenVA = atand((screen_height_cm/2)/screen_distance_cm)
pixperVA = (screen_height_pix/2)/screenVA
r_pixperVA = pixperVA/(screen_height_pix/270)
[.25:.25:3].*r_pixperVA

figure, imagesc(circmask([270, 270], (270/2)-sigmas(end)*2))
(((270/2)-sigmas(end)*2)/r_pixperVA)

figure,

sigmas

tmp = fitted_models.sigma(:);
tmp(fitted_models.r_squared<0.10)=nan;
figure, hist(tmp,100)
