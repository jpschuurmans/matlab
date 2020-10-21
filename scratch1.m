figure
hist(reliability.mean_map(:),30)

vol = reliability.mean_map;
figure
for slice_idx = 1:size(vol,3)
    subplot(ceil(sqrt(size(vol,3))), ceil(sqrt(size(vol,3))), slice_idx)
    imagesc(squeeze(vol(:,:,slice_idx)))
    axis image off
    caxis([min(vol(:)), max(vol(:))])
end
