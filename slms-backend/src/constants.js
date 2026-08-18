// The timetable views carry no ordering of their own, and sorting DayOfWeek as
// text puts Friday before Monday. FIELD() imposes real weekday order.
const WEEKDAY_ORDER =
  "FIELD(DayOfWeek,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')";

module.exports = { WEEKDAY_ORDER };
