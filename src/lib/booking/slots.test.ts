import { describe, expect, it } from 'vitest';
import { generateSlots, rangesOverlap } from './slots';

const utc = (hour: number, minute = 0) =>
  new Date(Date.UTC(2026, 8, 24, hour, minute));

describe('booking slot generation', () => {
  it('generates slots that fully fit into the working window', () => {
    const slots = generateSlots({
      dayStart: utc(9),
      dayEnd: utc(11),
      durationMinutes: 60,
      slotIntervalMinutes: 30,
      busy: [],
    });

    expect(slots.map((slot) => slot.toISOString())).toEqual([
      utc(9).toISOString(),
      utc(9, 30).toISOString(),
      utc(10).toISOString(),
    ]);
  });

  it('respects buffers and busy ranges', () => {
    const slots = generateSlots({
      dayStart: utc(9),
      dayEnd: utc(12),
      durationMinutes: 30,
      bufferBeforeMinutes: 10,
      bufferAfterMinutes: 10,
      slotIntervalMinutes: 30,
      busy: [{ start: utc(10), end: utc(10, 30) }],
    });

    expect(slots.map((slot) => slot.toISOString())).toEqual([
      utc(11).toISOString(),
    ]);
  });

  it('uses half-open overlap semantics', () => {
    expect(rangesOverlap(
      { start: utc(9), end: utc(10) },
      { start: utc(10), end: utc(11) },
    )).toBe(false);
  });
});
