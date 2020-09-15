models

whos stimMasks
figure,
for i = 1:200
    imagesc(squeeze(stimMasks(i,:,:)))
    drawnow
end

