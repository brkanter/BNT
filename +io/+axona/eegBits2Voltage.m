% Convert Axona EEG signal from bits to volts
%
% This function is used to convert Axona binary signals (eeg, spike waveforms)
% from bits to volts. The actual units depend on the parameter adcFullscale.
% For example, if that parameter is in microvolts, then the resulting signal
% will be in microvolts as well. If the parameter is in millivolts, then the
% signal will be in millivolts.
% The conversion equation was taken from an e-mail from Jim Donnett (Axona).
%
%  USAGE
%   eeg_V = io.axona.eegBits2Voltage(eeg, gain adcFullscale, bytesPerSample)
%   eeg             Binary signal, vector of signed bytes (i.e. in range -128 +127).
%   gain            Recording channel gain (extracted from .set file).
%   adcFullscale    ADC resolution in volts.
%   bytesPerSample  Number of encoding bytes per sample of signal. Can be extracted
%                   from the eeg file header.
%   eeg_V           Converted signal in volts.
%
function eeg = eegBits2Voltage(eeg, gain, adcFullscale, bytesPerSample)
    bits = 8 * bytesPerSample - 1;
    bitsCoef = 2^bits;

    eeg = adcFullscale/gain * eeg/bitsCoef;
end