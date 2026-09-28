using GLPK, JuMP

model = Model(GLPK.Optimizer)

T = 10      # Time
N = 20     # Anzahl Zeiteinheiten
h = T/NaN   # Zeiteinheiten

# 1 = Wärmepumpe        heat pump
# 2 = Biomassekessel    biomass boiler
# 3 = Gaskessel         gas boiler
# 4 = Speichertank      thermal storage discharge

# je Heizquelle
c = [25, 35, 80, 5]       # €/MWh
m = [120, 150, 100, 60]   # MW
# je Zeitpunkt      
"""Demand darf 430 nicht überschreiten"""
d = [430, 200, 230, 270, 300,       
     280, 240, 210, 260, 190,
     180, 200, 0, 270, 300,
     280, 240, 210, 260, 190]   # MW
k = [60,30,100,0]

@variable(model, x[1:4,1:N] >= 0)

# KOSTEN minimieren
@objective( model, Min,  sum( sum(x[j,i]*c[j]  for i=1:N) for j=1:4) )

# CONSTRAINTS:
# kann maximalen Wirkungsgrad nicht übersteigen    -    je Heizquelle
@constraint(model, [j=1:4,i=1:N], x[j,i] <= m[j])
# DEMAND muss erfüllt sein      -    für alle Zeitpunkte i
@constraint(model, [i=1:N],   sum( x[j,i] for j=1:4) >= d[i]    )

# Steuerungsspontanität
# increase
@constraint(model, [j=1:4, i=2:N],
    x[j,i] - x[j,i-1] <= k[j])
# decrease
@constraint(model, [j=1:4, i=2:N],
    x[j,i-1] - x[j,i] <= k[j])

optimize!(model)

println("Solver status: ", termination_status(model))
println("Solution status: ", primal_status(model))
## Printing the solution
println("Objective value = ", objective_value(model)) 


for j=1:4
    for i=1:N
        print(value(x[j,i]),"\t")
    end
    println(".")
end

