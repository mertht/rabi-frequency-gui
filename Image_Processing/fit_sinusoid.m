function [fit, freq] = fit_sinusoid(X, Y)
    % fits a sinusoid to the given data and returns the dominant frequency in [Hz]
    % X - the x axis of the sinusoid in [ns] (should be linspace)
    % Y - the experimental sinusoid data
    
    % As of 7/17/17, fit functionality is not operational
    
    L = length(X);
    
    if L < 2 || length(Y) ~= L
        error('lengths of arguments is invalid')
    end
    

    tsamp = (X(end) - X(1)) / L;                % time between samples (converted into seconds)
    Fs = 1 / tsamp;                             % sampling frequency (Hz)
    NFFT = 2^nextpow2(L);                       % sample rate for FFT
    YFT = fft(Y, NFFT) / L;                     % Fourier transformed signal of Y
    
    YFT_single = YFT(1:NFFT/2);                 % discard second half of FT
    f = (Fs / 2) * linspace(0, 1, NFFT/2);      % x-axis of plot
    
    [~, index] = max(YFT_single);
    freq = f(index);
    
    
    % plot singled-sided transform
    figure
    plot(f, 2 * abs(YFT_single))
    xlabel('Frequency (GHz)')
    ylabel('Density')
    title('Fourier Transformed Signal')
    
    fit = zeros(1, length(X)); % dummy value assigned for now
    
    
    
    
    
%     
%     % Use FFT to find frequency of sinusoid
%     len = length(X);
%     dt = (max(X) - min(X)) / len; % time separation of data points in ns
%     fs = 1 / dt; % sampling rate in GHz
%     
%     F = fft(Y, fs); % compute fast fourier transform
%     P2 = abs(F/len); % double sided spectrum
%     P1 = P2(1:len/2+1); % focus on single sided spectrum
%     P1(2:end-1) = 2*P1(2:end-1);
%     
%     [peak, index] = max(P1);
%     freq = (index * fs) * 10^9; % dominant frequency in Hz
%     angular_freq = freq * 2 * pi;
%     wavelength = 1 / freq; % wavelength of sinusoid in seconds
%     
%     % Now estimate phase, amplitude, and bias of data
%     bias = mean(Y);
%     maxY = max(Y);
%     minY = min(Y);
%     amplitude = maxY - minY;
%     Y_unbiased = Y - bias;
%     
%     % find first index where unbiased sinusoid crosses zero
%     found = -1;
%     for ii = 2:len
%         if Y_unbiased(ii) * Y_unbiased(1) <= 0
%             % we've found the first crossing point (opposing signs)
%             break
%         end
%     end
%     
%     if found == -1
%         error('cound not detect phase')
%     end
%     
%     angular_phase = X(ii) / wavelength * 2 * pi;
%     
%     % generate fit from estimated parameters
%     fit = amplitude * sin(angular_freq * X - angular_phase) + bias;
    
end