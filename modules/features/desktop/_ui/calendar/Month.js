// The days a month view shows: plain functions, no QML.
.pragma library

// Six weeks from the one holding the 1st, so every month fills the same grid.
// firstDay is 0 for Sunday, as both Date and Qt's locale count. Built from calendar
// fields, as a day isn't always 24 hours when the clocks change.
function days(year, month, firstDay) {
  const lead = (new Date(year, month, 1).getDay() - firstDay + 7) % 7;
  const cells = [];

  for (let index = 0; index < 42; index++) {
    const date = new Date(year, month, 1 - lead + index);

    cells.push({
      day: date.getDate(),
      inMonth: date.getMonth() === month,
      date: date
    });
  }

  return cells;
}
