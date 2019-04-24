extensions [CSV matrix Nw]

; global variables set from the interface:
; axes-per-producer (units of axes per producer per year, 5 in Wright and Zeder 1977)
; salt-per-producer (units of salt per producer per year, 150.0 in Wright and Zeder 1977)
; feathers-per-producer (units of feathers per producer per year, 10 in Wright and Zeder 1977)
; shell-per-producer (units of shell per producer per year, 20 in Wright and Zeder 1977)
; proportion-shell-producers (proportion of the Village 1 population involved in shell production, 0.15 in Wright and Zeder 1977)
; proportion-feather-producers (proportion of the Village 8 population involved in feather production, 0.17 in Wright and Zeder 1977)
; pass-through-rate (proportion of feather and shell passed on by each village, 0.5 in Wright and Zeder 1977)
; axe-need-per-person (units of axes needed per person per year, 0.5 in Wright and Zeder 1977)
; salt-need-per-person (units of salt needed per person per year, 1.6 in Wright and Zeder 1977)
; proportion-ax-producers (proportion of the Village 1 population involved in ax production in Year 1, .091 in Wright and Zeder 1977)
; proportion-salt-producers (proportion of the Village 8 population involved in salt production in Year 1, .097 in Wright and Zeder 1977)
; max-years (the number of years to run the simulation, 60 in Wright and Zeder 1977)
; orginal-population (a switch to turn on or off the use of the original population figures used by Wright and Zeder 1977. If true, the populations for each village for each year are read from WZpop.csv)
; regulation (a switch that turns on or off the original production regulation method described by Wright and Zeder 1977 (this is not yet implemented)


globals
[
 village-spacing
 nvillages
 pop
 yearpop
 year
 salt-proportion
 axe-proportion ; salt-proportion and axe-proportion are only needed to allow the variables set on the slider to vary with Wright and Zeder's regulation mechanism
 feathers
 shell
 salt
 axes
 assess-axe ; number by which production is increased or decreased in response to shortfalls
 assess-salt
]

breed [villages village]


villages-own
[
village-number
population
axe-need
salt-need
feathers-exported
previous-feathers-exported
salt-exported
axes-exported
shells-exported
previous-shells-exported
war-year
epidemic-year
]

;=================================================================================================================================================
to setup
  clear-all
  reset-ticks
  ask patches
  [
  set pcolor 99
  ]
  set nvillages 8
  locate-villages
  if original-population = true
    [
      set pop csv:from-file "WZpop.csv"
      set yearpop  matrix:from-row-list pop
      set max-years 60
    ]

; random seeds with interesting results 10005 (mixed results, increasing axe production has an effect on salt); 10009 (no failures with salt, few with axes); 10014 (in 100 years, no failures with salt, many with axes, but if it runs longer, axes do better);
  ; 10016, a few early failures with axes, otherwise everything is good; 10050 (increasing axe production from 5 to 6 increases the salt failures)
random-seed seed
end
;=================================================================================================================================================
to go
set year ticks + 1
ifelse original-population = true
    [
      read-population
    ]
    [
      find-population
    ]

produce
exchange

if year = max-years
  [
    stop
  ]
tick

end


;====================================================================================================================================================
to locate-villages ; this runs from the setup procedure. It creates seeds for "villages" and assigns each village seed a village number

    let x 1
    set village-spacing (max-pxcor / nvillages) ; sets distance between village seeds, measured only on the x-axis
    while [x <= nvillages]
    [
      ask patch ((x * village-spacing) - (.5 * village-spacing)) (max-pycor / 2) ; this creates village seeds evenly spaced in a straight line on the display
     [
       set pcolor red
       sprout-villages 1
       [
         set village-number x
         set label x

       ]
     ]
     set x x + 1
     ]




    ask patches with [pcolor = red]
    [
    ask patches in-radius 8 ; this draws circles representing villages around the village seeds created by the locate-villages procedure, and numbers the villages. This is purely for visualization purposes and affects nothing but the display.
     [
       set pcolor red
     ]
    ]

end

;=========================================================================================================================================================
to produce

ifelse year = 1
  [
    set salt-proportion proportion-salt-producers
    set axe-proportion proportion-axe-producers
    set assess-axe 1
    set assess-salt 1
  ]
;start else
  [
    if regulation = true
      [
        ifelse [salt-exported] of village 1 > 0
          [
            ;set assessment value for axe producers
            set assess-axe (1 + (([feathers-exported] of village 1 - [previous-feathers-exported] of village 1) / shell))
          ]
        ;start else
          [
            ;alternative assessment value for axe producers if no salt is received
            if [previous-feathers-exported] of village 1 > 0
              [
                set assess-axe ([feathers-exported] of village 1 / [previous-feathers-exported] of village 1)
              ]
          ]
        ifelse [axes-exported] of village 6 > 0
          [
            ;set assessment value for salt producers
            set assess-salt (1 + (([shells-exported] of village 6 - [previous-shells-exported] of village 6) / feathers))
          ]
        ;start else
          [
            ;alternative assessment value for axe producers if no salt is received
            if [previous-shells-exported] of village 6 > 0
              [
                set assess-salt ([shells-exported] of village 6 / [previous-shells-exported] of village 6)
              ]
          ]
         ;adjust proportion of the population involved in production by multiplying by the assessment value
        set salt-proportion (salt-proportion * assess-salt)
        set axe-proportion (axe-proportion * assess-axe)
      ]

  ]



set feathers (feathers-per-producer * proportion-feather-producers * ([population] of village 7))
set shell (shell-per-producer * proportion-shell-producers * ([population] of village 0))
set salt (salt-per-producer * salt-proportion * ([population] of village 7))
set axes (axes-per-producer * axe-proportion * ([population] of village 0))


end

;==========================================================================================================================================================
to exchange

ask villages
  [
    set previous-shells-exported shells-exported
    set previous-feathers-exported feathers-exported
  ]

let i 1
while [i <= nvillages]
  [
    ask villages with [village-number = i]
    [
      set axe-need (population * axe-need-per-person)
      set salt-need (population * salt-need-per-person)
    ]
    set i (i + 1)
  ]

ask village 0
  [
    set axes-exported (axes - axe-need)
    set shells-exported (shell * pass-through-rate)
  ]

ask village 7
  [
    set feathers-exported (feathers * pass-through-rate)
    set salt-exported (salt - salt-need)
  ]

set i  1
while [i <= nvillages - 1]
  [
    ask village i
      [
        set axes-exported (([axes-exported] of village (i - 1)) - axe-need)
        set shells-exported ([shells-exported] of village (i - 1) * pass-through-rate)
      ]
    set i (i + 1)
  ]

set i 6
while [i >= 0]
  [
    ask village i
      [
        set feathers-exported ([feathers-exported] of village (i + 1) * pass-through-rate)
        set salt-exported ([salt-exported] of village (i + 1)) - salt-need
      ]
    set i (i - 1)
  ]

end
;========================================================================================================================================================
to read-population

let i 1
while [i <= nvillages]
   [
     ask villages with [village-number = i]
       [
         set population matrix:get yearpop (year - 1) (i - 1)
       ]
     set i (i + 1)
   ]

end

;===============================================================================================================================================================
to find-population


; initialize local variables
let births 0
let deaths 0

let i 0

ifelse year = 1  ; set initial populations to equal the first year populations used by Wright and Zeder
  [
   ask village 0
     [
       set population 178
     ]
   ask village 1
     [
       set population 199
     ]
   ask village 2
     [
       set population 200
     ]
  ask village 3
     [
       set population 181
     ]
  ask village 4
     [
       set population 215
     ]
  ask village 5
     [
       set population 230
     ]
  ask village 6
     [
       set population 210
     ]
   ask village 7
     [
       set population 180
     ]

  ;find years in which villages are impacted by epidemics and wars
   while [i < 8]
     [
       ask village i
        [
         set epidemic-year ((random 9) + 5)
         set war-year ((random 42) + 14)
        ]
       set i (i + 1)
     ]
  ]
;start else
; finds population in a normal year; need to build in wars and epidemics
  [
    set i 0
    while [i < 8]
      [
        set births (random 11) + 2 ; after the addition, this returns a random integer between 2 and 12
        set deaths (random 11)
        ask village i
        [
          set population (population + births - deaths)
        ]
        if year = [epidemic-year] of village i
          [
            ask village i
              [
                set population (population - ((random 3) + 10))
                set epidemic-year (epidemic-year + ((random 9) + 5))
              ]
          ]
        if year = [war-year] of village i
          [
            ask village i
              [
                set population (population - ((random 21) + 15))
                set war-year (war-year + ((random 42) + 14))
              ]
          ]
        if [population] of village i < 0
          [
            ask village i
              [
                set population 0
              ]
          ]

        set i (i + 1)
      ]


  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
195
30
803
239
-1
-1
2.0
1
16
1
1
1
0
0
0
1
0
299
0
99
0
0
1
ticks
30.0

SLIDER
840
30
1012
63
axes-per-producer
axes-per-producer
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
840
75
1012
108
salt-per-producer
salt-per-producer
0
300
150.0
5
1
NIL
HORIZONTAL

SLIDER
840
120
1014
153
feathers-per-producer
feathers-per-producer
1
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
840
165
1012
198
shell-per-producer
shell-per-producer
1
40
20.0
1
1
NIL
HORIZONTAL

SLIDER
1040
30
1232
63
proportion-shell-producers
proportion-shell-producers
0
1
0.15
.01
1
NIL
HORIZONTAL

SLIDER
1040
75
1252
108
proportion-feather-producers
proportion-feather-producers
0
1
0.17
.01
1
NIL
HORIZONTAL

SLIDER
1040
120
1212
153
pass-through-rate
pass-through-rate
0
1
0.5
.01
1
NIL
HORIZONTAL

SLIDER
1040
165
1212
198
axe-need-per-person
axe-need-per-person
0
1
0.05
.01
1
NIL
HORIZONTAL

SLIDER
1040
210
1212
243
salt-need-per-person
salt-need-per-person
0
10
1.6
.1
1
NIL
HORIZONTAL

BUTTON
50
55
113
88
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
135
113
168
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
95
113
128
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
17
233
170
266
original-population
original-population
0
1
-1000

SLIDER
10
275
183
308
max-years
max-years
0
500
60.0
1
1
NIL
HORIZONTAL

SLIDER
830
205
1032
238
proportion-salt-producers
proportion-salt-producers
0
1
0.097
.001
1
NIL
HORIZONTAL

SLIDER
830
245
1022
278
proportion-axe-producers
proportion-axe-producers
0
1
0.091
.001
1
NIL
HORIZONTAL

SWITCH
42
318
149
351
regulation
regulation
0
1
-1000

PLOT
195
245
490
395
Village 1 Salt Received - Salt-Needed 
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if year >= 1 \n[\n  plot [salt-exported] of village 0\n]"

PLOT
490
245
800
395
Village 8 Axes Received - Axes Needed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if year >= 1 \n[\n  plot [axes-exported] of village 7\n]"

INPUTBOX
1155
370
1220
430
seed
100050.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <metric>seed</metric>
    <metric>salt</metric>
    <metric>axes</metric>
    <metric>feathers</metric>
    <metric>shell</metric>
    <metric>assess-axe</metric>
    <metric>assess-salt</metric>
    <metric>proportion-axe-producers</metric>
    <metric>proportion-salt-producers</metric>
    <metric>axe-proportion</metric>
    <metric>salt-proportion</metric>
    <metric>[population] of village 0</metric>
    <metric>[population] of village 1</metric>
    <metric>[population] of village 2</metric>
    <metric>[population] of village 3</metric>
    <metric>[population] of village 4</metric>
    <metric>[population] of village 5</metric>
    <metric>[population] of village 6</metric>
    <metric>[population] of village 7</metric>
    <metric>[salt-exported] of village 0</metric>
    <metric>[salt-exported] of village 1</metric>
    <metric>[salt-exported] of village 2</metric>
    <metric>[salt-exported] of village 3</metric>
    <metric>[salt-exported] of village 4</metric>
    <metric>[salt-exported] of village 5</metric>
    <metric>[salt-exported] of village 6</metric>
    <metric>[salt-exported] of village 7</metric>
    <metric>[axes-exported] of village 0</metric>
    <metric>[axes-exported] of village 1</metric>
    <metric>[axes-exported] of village 2</metric>
    <metric>[axes-exported] of village 3</metric>
    <metric>[axes-exported] of village 4</metric>
    <metric>[axes-exported] of village 5</metric>
    <metric>[axes-exported] of village 6</metric>
    <metric>[axes-exported] of village 7</metric>
    <metric>[war-year] of village 0</metric>
    <metric>[war-year] of village 1</metric>
    <metric>[war-year] of village 2</metric>
    <metric>[war-year] of village 3</metric>
    <metric>[war-year] of village 4</metric>
    <metric>[war-year] of village 5</metric>
    <metric>[war-year] of village 6</metric>
    <metric>[war-year] of village 7</metric>
    <metric>[epidemic-year] of village 0</metric>
    <metric>[epidemic-year] of village 1</metric>
    <metric>[epidemic-year] of village 2</metric>
    <metric>[epidemic-year] of village 3</metric>
    <metric>[epidemic-year] of village 4</metric>
    <metric>[epidemic-year] of village 5</metric>
    <metric>[epidemic-year] of village 6</metric>
    <metric>[epidemic-year] of village 7</metric>
    <enumeratedValueSet variable="regulation">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
