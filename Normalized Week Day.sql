-- normalized US weekday: 1-SUNDAY .. 7-SATURDAY
 SET @dow = (DATEPART(dw, @newDate) + @@DATEFIRST - 1) % 7 + 1