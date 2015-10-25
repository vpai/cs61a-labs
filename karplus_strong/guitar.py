"""A Python implementation of the Karplus-Strong algorithm"""

import random

def create_noise(n):
    """Create a list of n random values between -0.5 and 0.5 representing
    initial string excitation (white noise).
    """
    # BEGIN SOLUTION
    return [random.random()-0.5 for _ in range(n)]
    # END SOLUTION


def apply_ks(s, n):
    """Apply n Karplus-Strong updates to the list s and return the result,
    using the initial length of s as the frequency.

    >>> s = [0.2, 0.4, 0.5]
    >>> apply_ks(s, 4)
    [0.2, 0.4, 0.5, 0.29880000000000007, 0.4482, 0.39780240000000006, 0.37200600000000006]
    """
    # BEGIN SOLUTION
    frequency = len(s)
    for t in range(n):
        s.append(0.996 * (s[t] + s[t+1])/2)
    return s
    # END SOLUTION


def songify(notes):
    """Given a list of notes (represented as strings), return a list of each
    note's samples, which themselves are lists. To get a particular note's
    samples, call guitar_string(note).
    """
    # BEGIN SOLUTION
    song = []
    for note in notes:
        song.append(guitar_string(note))
    return song
    # END SOLUTION


def make_chord(note1, note2, note3):
    """Return the samples for the chord defined by the three given notes. A
    chord's samples can be constructed from the superposition of the samples of
    its component notes.
    """
    # BEGIN SOLUTION
    samples1 = guitar_string(note1)
    samples2 = guitar_string(note2)
    samples3 = guitar_string(note3)
    return [a+b+c for (a,b,c) in zip(samples1, samples2, samples3)]
    # END SOLUTION


def make_song():
    # Fill in notes for a song below.  This example starts "Twinkle, Twinkle."
    notes = ['C', make_chord('C', 'E', 'G'), 'G', 'G', 'A', 'A', 'G']
    return songify(notes)


# Utility functions and initialization

def make_strings(quant=256):
    """Return a (key, note, samples) tuple for each key.

    key and note are strings;  samples is a list of ints in [-quant, quant].
    """
    strings = []
    for (key, note) in keys:
        string = guitar_string(note)
        strings.append([key, note, string])
    return strings


def guitar_string(note, num_samples=30000, sample_rate=44100, quant=256):
    """Return a list of num_samples samples synthesizing a guitar string."""

    # Deal with chords
    if type(note) == list:
        return note

    key = notes[note]
    frequency = frequencies[key]
    delay = int(sample_rate / frequency)
    noise = create_noise(delay)
    samples = apply_ks(noise, num_samples - delay)
    samples = [int(s*quant) for s in samples]
    return samples

keys = [
  ('a', 'C'),
  ('w', 'C#'),
  ('s', 'D'),
  ('e', 'D#'),
  ('d', 'E'),
  ('f', 'F'),
  ('t', 'F#'),
  ('g', 'G'),
  ('y', 'G#'),
  ('h', 'A'),
  ('u', 'A#'),
  ('j', 'B'),
  ('k', 'high_C')
]

A = 440
C = A * 2 ** (3/12)
frequencies, notes = {}, {}

for i, (key, note) in enumerate(keys):
    frequencies[key] = C * 2 ** (i/12)
    notes[note] = key
