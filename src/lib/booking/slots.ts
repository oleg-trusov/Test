export type TimeRange = { start: Date; end: Date };

export type SlotGenerationInput = {
  dayStart: Date;
  dayEnd: Date;
  durationMinutes: number;
  bufferBeforeMinutes?: number;
  bufferAfterMinutes?: number;
  slotIntervalMinutes: number;
  busy: TimeRange[];
  minimumStart?: Date;
};

const addMinutes = (date: Date, minutes: number) =>
  new Date(date.getTime() + minutes * 60_000);

export function rangesOverlap(a: TimeRange, b: TimeRange) {
  return a.start < b.end && b.start < a.end;
}

export function generateSlots(input: SlotGenerationInput): Date[] {
  const {
    dayStart,
    dayEnd,
    durationMinutes,
    bufferBeforeMinutes = 0,
    bufferAfterMinutes = 0,
    slotIntervalMinutes,
    busy,
    minimumStart,
  } = input;

  if (durationMinutes <= 0 || slotIntervalMinutes <= 0 || dayStart >= dayEnd) return [];

  const results: Date[] = [];
  for (
    let cursor = new Date(dayStart);
    cursor < dayEnd;
    cursor = addMinutes(cursor, slotIntervalMinutes)
  ) {
    if (minimumStart && cursor < minimumStart) continue;

    const serviceEnd = addMinutes(cursor, durationMinutes);
    const occupied: TimeRange = {
      start: addMinutes(cursor, -bufferBeforeMinutes),
      end: addMinutes(serviceEnd, bufferAfterMinutes),
    };

    if (occupied.start < dayStart || occupied.end > dayEnd) continue;
    if (busy.some((range) => rangesOverlap(occupied, range))) continue;
    results.push(new Date(cursor));
  }

  return results;
}
