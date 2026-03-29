import pandas as pd
import numpy as np
from numpy import fft
import matplotlib.pyplot as plt
from scipy.signal import find_peaks
from scipy.optimize import curve_fit
from matplotlib import rcParams

rcParams['text.usetex'] = True
rcParams['font.family'] = 'serif'
rcParams['font.serif'] = 'cm'
rcParams['ytick.labelsize'] = 10.0
rcParams['xtick.labelsize'] = 10.0
rcParams['legend.handletextpad'] = 0.3
rcParams['legend.handlelength'] = 0.85
rcParams['legend.borderaxespad'] = 0.4
rcParams['legend.labelspacing'] = 0.10
rcParams['legend.framealpha'] = 1.00
rcParams['legend.borderpad'] = 0.5
rcParams['legend.handleheight'] = 1.0
rcParams['legend.edgecolor'] = 'k'
rcParams['axes.linewidth'] = 0.5
rcParams['lines.linewidth'] = 1.0

def analyze_data(file_path):
    df = pd.read_csv(file_path, skiprows=5, usecols=[0, 1])
    t = df['Time'].values
    v = df['Voltage'].values
    
    mask = (t >= 0) & (t <= 0.1)

    t_trim = t[mask]
    v_trim = v[mask]

    dt = t[1] - t[0]
    print(f"dt: {dt}")
    n = len(t_trim)
    print(f"Number of data points: {n}")

    res = (2*np.pi)/(n*dt)
    print(f"Frequency resolution: {res} ")

    F = fft.ifft(v_trim)
    w = fft.fftfreq(n, d=dt)

    F = fft.fftshift(F)
    w = fft.fftshift(w)

    F = np.abs(F)**2

    plt.figure()
    
    plt.plot(t_trim, v_trim)
    plt.xlabel(r"Time (s)", fontsize=15)
    plt.ylabel(r"Voltage (V)", fontsize=15)

    plt.tight_layout()

    plt.figure()
    plt.plot(w, F)
    plt.xlim([-500, 500])
    plt.xticks(np.arange(-500, 501, 100))

    w_vis = (w >= -500) & (w <= 500)
    F_vis = F[w_vis]

    peaks, _ = find_peaks(F_vis, height=np.max(F_vis)*0.05, distance=5)

    peak_freqs = w[w_vis][peaks]
    peak_powers = F_vis[peaks]

    plt.plot(peak_freqs[1], peak_powers[1], "x", color='red', label=f'Sensor Peak ({peak_freqs[1]:.0f} hz)', markersize=8, markeredgewidth=2)
    plt.plot(peak_freqs[2], peak_powers[2], "x", color='green', label=f'Hose Peak ({peak_freqs[2]:.0f} hz)', markersize=8, markeredgewidth=2)
    plt.xlabel(r"Frequency (Hz)", fontsize=15)
    plt.ylabel(r"$| \widehat{V}(\omega) |^2$", fontsize=15)

    plt.legend()

    plt.tight_layout()


def plot_omega_zeta(lengths, w_balloon, w_valve, z_balloon, z_valve):
    C = 343.0
    RHO = 1.225 
    MU = 1.81e-5
    D = 0.005
    V = 6.5548256e-8
    
    lengths_array = np.linspace(min(lengths), max(lengths), 100)
    
    V_t = (np.pi * D**2 / 4) * lengths_array
    
    w_theoretical = (C / lengths_array) * (0.5 + V / V_t)**(-0.5)
    z_theoretical = ((16 * MU * lengths_array) / (RHO * C * D**2)) * (0.5 + V / V_t)**0.5

    mask_w_valv = ~np.isnan(w_valve)
    mask_z_valv = ~np.isnan(z_valve)

    plt.figure(figsize=(6.4, 4.8))
    
    plt.plot(lengths, w_balloon, 'bo', label='Balloon Data')
    plt.plot(lengths[mask_w_valv], w_valve[mask_w_valv], 'ro', label='Valve Data')
    plt.plot(lengths_array, w_theoretical, 'k-', label=r'$\omega = \omega(l)$')
    
    plt.xlabel("Tube length (m)", fontsize=15)
    plt.ylabel(r"Damped natural frequency, $\omega$ (rad/s)", fontsize=15)
    plt.legend()

    plt.tight_layout()

    plt.figure(figsize=(6.4, 4.8))
    
    plt.plot(lengths, z_balloon, 'bo', label='Balloon Data')
    plt.plot(lengths[mask_z_valv], z_valve[mask_z_valv], 'ro', label='Valve Data')
    plt.plot(lengths_array, z_theoretical, 'k-', label=r'$\zeta = \zeta(l)$')
    
    plt.xlabel("Tube length (m)", fontsize=15)
    plt.ylabel(r"Damping ratio, $\zeta$", fontsize=15)
    plt.legend()
    
    plt.tight_layout()

if __name__ == "__main__":
    analyze_data("./Short/ShortBalloonOscilloscopeData.csv")
    analyze_data("./Medium/MediumBalloonOscilloscopeData.csv")
    analyze_data("./Long/LongBalloonOscilloscopeData.csv")

    lengths_measured = np.array([0.1524, 0.635, 1.016])
    w_ball = np.array([1811.4, 679.3, 452.8])
    w_valv = np.array([np.nan, 708.31, 463.11])
    z_ball = np.array([0.0450, 0.0500, 0.0650])
    z_valv = np.array([np.nan, 0.051, 0.081])
    plot_omega_zeta(lengths_measured, w_ball, w_valv, z_ball, z_valv)

    plt.show()