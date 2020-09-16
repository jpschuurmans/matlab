models

whos stimMasks
figure,
for i = 1:200
    imagesc(squeeze(stimMasks(i,:,:)))
    drawnow
end

whos dm_conv
whos functional_ni
max(mask(:))

whos mask
figure, imagesc(squeeze(mask(:,1,:)))

data = [rand(5); rand(5)+6; rand(5)+2]
data_dm = kron(eye(3), ones(5,1))
betas = data_dm \ data
data_model = data_dm*betas
resid = data - data_model

sub2ind(map_size,[30 4 40])

figure,
subplot(131)
plot(data(:,1))
hold on
plot(data_model(:,1))
subplot(132)
plot(resid(:, 1))

rad2deg(0:0.1:2)

[min(theta(:)), max(theta(:))]
[min(theta_deg(:)), max(theta_deg(:))]

min(fitted_models.X(:))
max(fitted_models.X(:))
min(fitted_models.Y(:))
max(fitted_models.Y(:))

min(fitted_models.X(:)-210/2)
max(fitted_models.X(:)-210/2)
min(fitted_models.Y(:)-210/2)
max(fitted_models.Y(:)-210/2)
