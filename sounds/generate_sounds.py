import os
import wave
import struct
import numpy as np

SAMPLE_RATE = 44100

def save_wav(filename, samples, sample_rate=SAMPLE_RATE):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    samples = np.clip(samples, -1.0, 1.0)
    int_samples = (samples * 32767).astype(np.int16)
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(int_samples.tobytes())

def adsr(length, attack, decay, sustain, release, sustain_level=0.7):
    total_samples = int(length * SAMPLE_RATE)
    a_samples = int(attack * SAMPLE_RATE)
    d_samples = int(decay * SAMPLE_RATE)
    r_samples = int(release * SAMPLE_RATE)
    s_samples = max(0, total_samples - a_samples - d_samples - r_samples)
    
    env = []
    if a_samples > 0:
        env.append(np.linspace(0, 1, a_samples))
    if d_samples > 0:
        env.append(np.linspace(1, sustain_level, d_samples))
    if s_samples > 0:
        env.append(np.full(s_samples, sustain_level))
    if r_samples > 0:
        env.append(np.linspace(sustain_level, 0, r_samples))
    
    res = np.concatenate(env) if env else np.zeros(total_samples)
    if len(res) < total_samples:
        res = np.pad(res, (0, total_samples - len(res)))
    elif len(res) > total_samples:
        res = res[:total_samples]
    return res

def synth_marimba_note(freq, duration, velocity=0.8):
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    decay1 = np.exp(-t * 12)
    decay2 = np.exp(-t * 28)
    decay3 = np.exp(-t * 45)
    sig = 0.7 * np.sin(2 * np.pi * freq * t) * decay1
    sig += 0.25 * np.sin(2 * np.pi * freq * 3.9 * t) * decay2
    sig += 0.1 * np.sin(2 * np.pi * freq * 9.2 * t) * decay3
    click = np.random.uniform(-0.1, 0.1, len(t)) * np.exp(-t * 200)
    sig += click
    return sig * velocity

def synth_bell_note(freq, duration, velocity=0.8):
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    env = np.exp(-t * (4.0 / duration))
    sig = 0.6 * np.sin(2 * np.pi * freq * t)
    sig += 0.3 * np.sin(2 * np.pi * freq * 2.0 * t)
    sig += 0.15 * np.sin(2 * np.pi * freq * 3.01 * t)
    sig += 0.08 * np.sin(2 * np.pi * freq * 4.2 * t)
    return sig * env * velocity

def synth_flute_note(freq, duration, velocity=0.7):
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    env = adsr(duration, 0.05, 0.08, duration - 0.2, 0.1, 0.8)
    vibrato = 1.0 + 0.015 * np.sin(2 * np.pi * 5.0 * t)
    sig = 0.7 * np.sin(2 * np.pi * freq * vibrato * t)
    sig += 0.2 * np.sin(2 * np.pi * freq * 2.0 * vibrato * t)
    sig += 0.08 * np.sin(2 * np.pi * freq * 3.0 * vibrato * t)
    breath = np.random.uniform(-0.03, 0.03, len(t))
    sig = (sig + breath) * env * velocity
    return sig

def synth_bass_note(freq, duration, velocity=0.8):
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), False)
    env = np.exp(-t * 6.0)
    sig = 0.8 * np.sin(2 * np.pi * freq * t)
    sig += 0.3 * np.sin(2 * np.pi * freq * 2.0 * t)
    return sig * env * velocity

def generate_sfx_footstep(out_path):
    dur = 0.14
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = np.exp(-t * 40)
    f_env = np.linspace(160, 60, len(t))
    sig = np.sin(2 * np.pi * f_env * t) * env * 0.6
    noise = np.random.uniform(-0.2, 0.2, len(t)) * np.exp(-t * 55)
    samples = sig + noise
    save_wav(out_path, samples)

def generate_sfx_wheelchair_roll(out_path):
    dur = 0.35
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = adsr(dur, 0.05, 0.05, dur - 0.18, 0.08, 0.8)
    whir1 = np.sin(2 * np.pi * 180 * t + 0.3 * np.sin(2 * np.pi * 35 * t)) * 0.2
    whir2 = np.sin(2 * np.pi * 360 * t) * 0.1
    noise = np.random.uniform(-0.08, 0.08, len(t))
    samples = (whir1 + whir2 + noise) * env * 0.5
    save_wav(out_path, samples)

def generate_sfx_block_pickup(out_path):
    dur = 0.18
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    freq = np.linspace(350, 680, len(t))
    env = adsr(dur, 0.01, 0.04, 0.06, 0.07, 0.6)
    sig = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(4 * np.pi * freq * t)
    samples = sig * env * 0.6
    save_wav(out_path, samples)

def generate_sfx_block_place(out_path):
    dur = 0.22
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env1 = np.exp(-t * 35)
    sig1 = np.sin(2 * np.pi * 240 * t) * env1 * 0.6
    env2 = np.exp(-t * 20)
    sig2 = np.sin(2 * np.pi * 520 * t) * env2 * 0.4
    noise = np.random.uniform(-0.15, 0.15, len(t)) * np.exp(-t * 60)
    samples = (sig1 + sig2 + noise) * 0.7
    save_wav(out_path, samples)

def generate_sfx_push_heavy(out_path):
    dur = 0.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = adsr(dur, 0.06, 0.1, 0.22, 0.12, 0.7)
    rumble = np.sin(2 * np.pi * 95 * t) * 0.4
    noise = np.random.uniform(-0.35, 0.35, len(t)) * 0.5
    samples = (rumble + noise) * env * 0.7
    save_wav(out_path, samples)

def generate_sfx_kick_paper(out_path):
    dur = 0.28
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    whoosh_f = np.linspace(150, 450, len(t))
    whoosh = np.sin(2 * np.pi * whoosh_f * t) * np.exp(-t * 18) * 0.4
    rustle = np.random.uniform(-0.4, 0.4, len(t)) * np.exp(-t * 22) * 0.5
    samples = (whoosh + rustle) * 0.8
    save_wav(out_path, samples)

def generate_sfx_yolanda_hoot(out_path):
    dur = 0.65
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    samples = np.zeros(len(t))
    
    t1_end = int(0.22 * SAMPLE_RATE)
    t1 = t[:t1_end]
    env1 = np.sin(np.pi * t1 / 0.22)
    f1 = 490 - 30 * (t1 / 0.22)
    samples[:t1_end] += (np.sin(2 * np.pi * f1 * t1) + 0.15 * np.sin(4 * np.pi * f1 * t1)) * env1 * 0.5
    
    t2_start = int(0.26 * SAMPLE_RATE)
    t2_len = int(0.35 * SAMPLE_RATE)
    t2 = np.linspace(0, 0.35, t2_len, False)
    env2 = np.sin(np.pi * t2 / 0.35)
    f2 = 540 - 50 * (t2 / 0.35)
    samples[t2_start:t2_start + t2_len] += (np.sin(2 * np.pi * f2 * t2) + 0.15 * np.sin(4 * np.pi * f2 * t2)) * env2 * 0.6
    
    save_wav(out_path, samples)

def generate_sfx_yolanda_hint(out_path):
    dur = 1.1
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    samples = np.zeros(len(t))
    notes = [
        (0.00, 523.25, 0.4),
        (0.12, 659.25, 0.4),
        (0.24, 783.99, 0.4),
        (0.38, 1046.50, 0.7)
    ]
    for start_t, freq, note_dur in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        note_samples = synth_bell_note(freq, note_dur, velocity=0.5)
        end_idx = min(len(samples), start_idx + len(note_samples))
        samples[start_idx:end_idx] += note_samples[:end_idx - start_idx]
    save_wav(out_path, samples)

def generate_sfx_magic_sparkle(out_path):
    dur = 0.85
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    samples = np.zeros(len(t))
    freqs = [880, 1046.5, 1174.66, 1318.51, 1567.98, 1760, 2093]
    for i, freq in enumerate(freqs):
        start_t = i * 0.08
        start_idx = int(start_t * SAMPLE_RATE)
        note = synth_bell_note(freq, 0.35, velocity=0.35)
        end_idx = min(len(samples), start_idx + len(note))
        samples[start_idx:end_idx] += note[:end_idx - start_idx]
    save_wav(out_path, samples)

def generate_sfx_seal_collect(out_path):
    dur = 1.6
    samples = np.zeros(int(dur * SAMPLE_RATE))
    arpeggio = [
        (0.00, 523.25, 0.25, 0.5),
        (0.10, 659.25, 0.25, 0.5),
        (0.20, 783.99, 0.25, 0.55),
        (0.32, 1046.50, 0.45, 0.7),
        (0.48, 880.00, 0.3, 0.55),
        (0.60, 1046.50, 0.3, 0.65),
        (0.75, 1318.51, 0.8, 0.8)
    ]
    for start_t, freq, note_dur, vel in arpeggio:
        idx = int(start_t * SAMPLE_RATE)
        s1 = synth_marimba_note(freq, note_dur, velocity=vel * 0.6)
        s2 = synth_bell_note(freq, note_dur, velocity=vel * 0.5)
        note = s1 + s2
        end_idx = min(len(samples), idx + len(note))
        samples[idx:end_idx] += note[:end_idx - idx]
    save_wav(out_path, samples)

def generate_sfx_puzzle_correct(out_path):
    dur = 0.7
    samples = np.zeros(int(dur * SAMPLE_RATE))
    notes = [
        (0.00, 659.25, 0.25, 0.5),
        (0.12, 783.99, 0.25, 0.55),
        (0.24, 1046.50, 0.45, 0.7)
    ]
    for start_t, freq, note_dur, vel in notes:
        idx = int(start_t * SAMPLE_RATE)
        s = synth_marimba_note(freq, note_dur, velocity=vel)
        end_idx = min(len(samples), idx + len(s))
        samples[idx:end_idx] += s[:end_idx - idx]
    save_wav(out_path, samples)

def generate_sfx_books_fall_soft(out_path):
    dur = 0.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    samples = np.zeros(len(t))
    thuds = [0.05, 0.18, 0.32, 0.48]
    for start_t in thuds:
        idx = int(start_t * SAMPLE_RATE)
        sub_len = int(0.25 * SAMPLE_RATE)
        st = np.linspace(0, 0.25, sub_len, False)
        f_drop = np.linspace(180, 80, sub_len)
        thud = np.sin(2 * np.pi * f_drop * st) * np.exp(-st * 25) * 0.4
        paper = np.random.uniform(-0.15, 0.15, sub_len) * np.exp(-st * 30)
        sound = thud + paper
        end_idx = min(len(samples), idx + len(sound))
        samples[idx:end_idx] += sound[:end_idx - idx]
    save_wav(out_path, samples)

def generate_sfx_mist_ambient(out_path):
    dur = 2.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = adsr(dur, 0.4, 0.3, dur - 1.2, 0.5, 0.7)
    noise = np.random.uniform(-0.25, 0.25, len(t))
    mod = 0.5 + 0.5 * np.sin(2 * np.pi * 0.8 * t)
    tone = np.sin(2 * np.pi * 220 * t + 0.5 * np.sin(2 * np.pi * 1.5 * t)) * 0.15
    samples = (noise * mod + tone) * env * 0.5
    save_wav(out_path, samples)

def generate_sfx_door_open(out_path):
    dur = 1.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = adsr(dur, 0.08, 0.15, 0.45, 0.32, 0.6)
    slide = np.sin(2 * np.pi * np.linspace(150, 420, len(t)) * t) * 0.3
    crystal = np.sin(2 * np.pi * 880 * t) * np.exp(-t * 6) * 0.25
    samples = (slide + crystal) * env * 0.7
    save_wav(out_path, samples)

def generate_sfx_coop_button_press(out_path):
    dur = 0.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    click1 = np.sin(2 * np.pi * 320 * t) * np.exp(-t * 40) * 0.5
    t2 = np.maximum(0, t - 0.06)
    click2 = np.sin(2 * np.pi * 480 * t2) * np.exp(-t2 * 35) * 0.5
    res = np.sin(2 * np.pi * 640 * t) * np.exp(-t * 12) * 0.3
    samples = (click1 + click2 + res) * 0.8
    save_wav(out_path, samples)

def generate_ui_button_hover(out_path):
    dur = 0.08
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    f = np.linspace(440, 587.33, len(t))
    env = np.sin(np.pi * t / dur)
    samples = np.sin(2 * np.pi * f * t) * env * 0.4
    save_wav(out_path, samples)

def generate_ui_button_select(out_path):
    dur = 0.18
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    f = np.linspace(523.25, 783.99, len(t))
    env = np.sin(np.pi * t / dur)
    samples = (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)) * env * 0.5
    save_wav(out_path, samples)

def generate_ui_page_flip(out_path):
    dur = 0.36
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), False)
    env = adsr(dur, 0.03, 0.08, 0.15, 0.1, 0.7)
    noise = np.random.uniform(-0.35, 0.35, len(t))
    swish = np.sin(2 * np.pi * np.linspace(250, 600, len(t)) * t) * 0.2
    samples = (noise + swish) * env * 0.6
    save_wav(out_path, samples)

def generate_ui_game_start(out_path):
    dur = 1.3
    samples = np.zeros(int(dur * SAMPLE_RATE))
    chords = [
        (0.00, [392.00, 523.25, 659.25], 0.35),
        (0.30, [440.00, 587.33, 698.46], 0.35),
        (0.60, [523.25, 659.25, 783.99, 1046.50], 0.68)
    ]
    for start_t, freqs, note_dur in chords:
        idx = int(start_t * SAMPLE_RATE)
        chord_sig = np.zeros(int(note_dur * SAMPLE_RATE))
        for f in freqs:
            chord_sig += synth_marimba_note(f, note_dur, 0.3)
            chord_sig += synth_bell_note(f, note_dur, 0.2)
        end_idx = min(len(samples), idx + len(chord_sig))
        samples[idx:end_idx] += chord_sig[:end_idx - idx]
    save_wav(out_path, samples)

def generate_ui_time_warning(out_path):
    dur = 1.4
    samples = np.zeros(int(dur * SAMPLE_RATE))
    pings = [0.0, 0.4, 0.8]
    for pt in pings:
        idx = int(pt * SAMPLE_RATE)
        bell = synth_bell_note(698.46, 0.55, velocity=0.4)
        end_idx = min(len(samples), idx + len(bell))
        samples[idx:end_idx] += bell[:end_idx - idx]
    save_wav(out_path, samples)

def generate_bgm_library_hub(out_path):
    bpm = 108
    beat_dur = 60.0 / bpm
    total_beats = 32
    total_dur = total_beats * beat_dur
    samples = np.zeros(int(total_dur * SAMPLE_RATE))
    
    bass_line = [
        (0, 130.81), (2, 164.81), (4, 174.61), (6, 196.00),
        (8, 130.81), (10, 164.81), (12, 174.61), (14, 196.00),
        (16, 146.83), (18, 174.61), (20, 196.00), (22, 130.81),
        (24, 174.61), (26, 196.00), (28, 130.81), (30, 196.00)
    ]
    for b_beat, freq in bass_line:
        t_start = b_beat * beat_dur
        idx = int(t_start * SAMPLE_RATE)
        note = synth_bass_note(freq, beat_dur * 1.6, velocity=0.45)
        end_idx = min(len(samples), idx + len(note))
        samples[idx:end_idx] += note[:end_idx - idx]
        
    melody = [
        (0, 523.25, 1.0), (1, 659.25, 1.0), (2, 783.99, 1.5), (3.5, 659.25, 0.5),
        (4, 880.00, 1.0), (5, 783.99, 1.0), (6, 659.25, 1.5), (7.5, 587.33, 0.5),
        (8, 523.25, 1.0), (9, 659.25, 1.0), (10, 783.99, 1.0), (11, 880.00, 1.0),
        (12, 1046.50, 2.0), (14, 783.99, 1.8),
        (16, 880.00, 1.0), (17, 783.99, 1.0), (18, 698.46, 1.5), (19.5, 659.25, 0.5),
        (20, 587.33, 1.0), (21, 659.25, 1.0), (22, 783.99, 1.8),
        (24, 698.46, 1.0), (25, 659.25, 1.0), (26, 587.33, 1.5), (27.5, 523.25, 0.5),
        (28, 523.25, 2.5), (31, 392.00, 0.8)
    ]
    for m_beat, freq, m_len in melody:
        t_start = m_beat * beat_dur
        idx = int(t_start * SAMPLE_RATE)
        dur = m_len * beat_dur
        m_note = synth_marimba_note(freq, dur, velocity=0.55)
        f_note = synth_flute_note(freq, dur, velocity=0.25)
        note = m_note + f_note
        end_idx = min(len(samples), idx + len(note))
        samples[idx:end_idx] += note[:end_idx - idx]

    chimes = [
        (0.5, 1046.50), (4.5, 1318.51), (8.5, 1046.50), (12.5, 1567.98),
        (16.5, 1318.51), (20.5, 1046.50), (24.5, 1174.66), (28.5, 1046.50)
    ]
    for c_beat, freq in chimes:
        t_start = c_beat * beat_dur
        idx = int(t_start * SAMPLE_RATE)
        b_note = synth_bell_note(freq, beat_dur * 1.5, velocity=0.22)
        end_idx = min(len(samples), idx + len(b_note))
        samples[idx:end_idx] += b_note[:end_idx - idx]

    save_wav(out_path, samples * 0.8)

def generate_bgm_puzzle_room(out_path):
    bpm = 116
    beat_dur = 60.0 / bpm
    total_beats = 32
    total_dur = total_beats * beat_dur
    samples = np.zeros(int(total_dur * SAMPLE_RATE))
    
    bass = [
        (0, 110.00), (2, 130.81), (4, 146.83), (6, 164.81),
        (8, 110.00), (10, 130.81), (12, 146.83), (14, 164.81),
        (16, 110.00), (18, 146.83), (20, 130.81), (22, 164.81),
        (24, 146.83), (26, 130.81), (28, 110.00), (30, 164.81)
    ]
    for b_beat, freq in bass:
        idx = int(b_beat * beat_dur * SAMPLE_RATE)
        note = synth_bass_note(freq, beat_dur * 1.5, velocity=0.45)
        end_idx = min(len(samples), idx + len(note))
        samples[idx:end_idx] += note[:end_idx - idx]
        
    kalimba = [
        (0, 440.00), (0.5, 523.25), (1, 659.25), (2, 587.33), (3, 523.25),
        (4, 440.00), (4.5, 659.25), (5, 587.33), (6, 523.25), (7, 440.00),
        (8, 523.25), (8.5, 659.25), (9, 783.99), (10, 659.25), (11, 587.33),
        (12, 880.00), (13, 783.99), (14, 659.25), (15, 587.33),
        (16, 659.25), (17, 587.33), (18, 523.25), (19, 440.00),
        (20, 523.25), (21, 587.33), (22, 659.25), (23, 783.99),
        (24, 880.00), (25, 659.25), (26, 587.33), (27, 523.25),
        (28, 440.00), (30, 392.00)
    ]
    for k_beat, freq in kalimba:
        idx = int(k_beat * beat_dur * SAMPLE_RATE)
        dur = beat_dur * 1.2
        note = synth_marimba_note(freq, dur, velocity=0.5)
        end_idx = min(len(samples), idx + len(note))
        samples[idx:end_idx] += note[:end_idx - idx]
        
    save_wav(out_path, samples * 0.8)

def generate_bgm_victory_fanfare(out_path):
    dur = 5.2
    samples = np.zeros(int(dur * SAMPLE_RATE))
    
    progression = [
        (0.00, [523.25, 659.25, 783.99], 0.35),
        (0.35, [523.25, 659.25, 783.99], 0.35),
        (0.70, [523.25, 659.25, 783.99], 0.35),
        (1.05, [587.33, 698.46, 880.00], 0.5),
        (1.55, [659.25, 783.99, 987.77], 0.5),
        (2.10, [783.99, 987.77, 1174.66], 0.6),
        (2.70, [1046.50, 1318.51, 1567.98, 2093.00], 2.4)
    ]
    for start_t, freqs, chord_dur in progression:
        idx = int(start_t * SAMPLE_RATE)
        chord_sig = np.zeros(int(chord_dur * SAMPLE_RATE))
        for f in freqs:
            chord_sig += synth_marimba_note(f, chord_dur, 0.35)
            chord_sig += synth_bell_note(f, chord_dur, 0.3)
            chord_sig += synth_flute_note(f, chord_dur, 0.25)
        end_idx = min(len(samples), idx + len(chord_sig))
        samples[idx:end_idx] += chord_sig[:end_idx - idx]
        
    save_wav(out_path, samples * 0.85)

def main():
    base_dir = r"c:\Users\carlo\OneDrive\Área de Trabalho\sounds"
    
    sfx_dir = os.path.join(base_dir, "sfx")
    ui_dir = os.path.join(base_dir, "ui")
    bgm_dir = os.path.join(base_dir, "bgm")
    
    generate_sfx_footstep(os.path.join(sfx_dir, "sfx_footstep.wav"))
    generate_sfx_wheelchair_roll(os.path.join(sfx_dir, "sfx_wheelchair_roll.wav"))
    generate_sfx_block_pickup(os.path.join(sfx_dir, "sfx_block_pickup.wav"))
    generate_sfx_block_place(os.path.join(sfx_dir, "sfx_block_place.wav"))
    generate_sfx_push_heavy(os.path.join(sfx_dir, "sfx_push_heavy.wav"))
    generate_sfx_kick_paper(os.path.join(sfx_dir, "sfx_kick_paper.wav"))
    generate_sfx_yolanda_hoot(os.path.join(sfx_dir, "sfx_yolanda_hoot.wav"))
    generate_sfx_yolanda_hint(os.path.join(sfx_dir, "sfx_yolanda_hint.wav"))
    generate_sfx_magic_sparkle(os.path.join(sfx_dir, "sfx_magic_sparkle.wav"))
    generate_sfx_seal_collect(os.path.join(sfx_dir, "sfx_seal_collect.wav"))
    generate_sfx_puzzle_correct(os.path.join(sfx_dir, "sfx_puzzle_correct.wav"))
    generate_sfx_books_fall_soft(os.path.join(sfx_dir, "sfx_books_fall_soft.wav"))
    generate_sfx_mist_ambient(os.path.join(sfx_dir, "sfx_mist_ambient.wav"))
    generate_sfx_door_open(os.path.join(sfx_dir, "sfx_door_open.wav"))
    generate_sfx_coop_button_press(os.path.join(sfx_dir, "sfx_coop_button_press.wav"))
    
    generate_ui_button_hover(os.path.join(ui_dir, "ui_button_hover.wav"))
    generate_ui_button_select(os.path.join(ui_dir, "ui_button_select.wav"))
    generate_ui_page_flip(os.path.join(ui_dir, "ui_page_flip.wav"))
    generate_ui_game_start(os.path.join(ui_dir, "ui_game_start.wav"))
    generate_ui_time_warning(os.path.join(ui_dir, "ui_time_warning.wav"))
    
    generate_bgm_library_hub(os.path.join(bgm_dir, "bgm_library_hub.wav"))
    generate_bgm_puzzle_room(os.path.join(bgm_dir, "bgm_puzzle_room.wav"))
    generate_bgm_victory_fanfare(os.path.join(bgm_dir, "bgm_victory_fanfare.wav"))

if __name__ == "__main__":
    main()
