function screenfig(filename, format, fullscreen)

    orig_pos = get(gcf, 'position');

    if strcmp(fullscreen, 'fullscreen')
        set(gcf, 'units','normalized','outerposition',[0 0 1 1])
    end

    if nargin < 1
        error('Not enough input arguments!')
    end
    fmt = ['-d', format];

    set(gcf,'Units','pixels');
    scrpos = get(gcf,'Position');
    newpos = scrpos/100;
    set(gcf,'PaperUnits','inches',...
        'PaperPosition',newpos)

    print(fmt, filename, '-r100');
    drawnow

    set(gcf, 'position', orig_pos)
