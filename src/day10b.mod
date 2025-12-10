set counters;
set buttons;

param target{counters};
param wiring{buttons, counters};

var clicks{buttons}, integer, >= 0;

s.t. target_met{c in counters}:
    target[c] == sum{b in buttons} wiring[b, c] * clicks[b];

minimize total_clicks: sum{b in buttons} clicks[b];

solve;
printf{b in buttons} "button %s: %d\n", b, clicks[b];
printf "total clicks: %d\n", sum{b in buttons} clicks[b];
