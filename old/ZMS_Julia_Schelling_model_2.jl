using Plots, LinearAlgebra, Statistics, Distributions

#Liczba agentów rodzaju I
Nᴵ = 5000
#Liczba agentów rodzaju II
Nᴵᴵ = 25000
#Liczba agentów rodzaju III
Nᴵᴵᴵ = 50000  #SUMA 80000 (8*10^4)
#Ceny
P_górna⁽¹⁾= 35000
P_górna⁽²⁾= 25000
P_dolna⁽¹⁾= 23000
P_górna⁽³⁾=19000
P_dolna⁽²⁾= 18000
P_dolna⁽³⁾= 8000;
T = 12*20 #12 miesięcy - rok, 20 lat
CZAS = 15*12 #Piętnastoletnie ,,pożyczki" - zablokowanie czasu do szukania nowego mieszkania (można szukać tylko gdy CZASₙ = 0);

#Początkowe rozmieszczenie - przestrzenie trzech dzielnic: ciągłe
α₁ = 1 #Współczynnik kształtu - im większy tym ,,chudszy" ogon rozkładu PAreta
θ₁ = 0.1 #Skala - dla rozkładów Pareta x > θ (śmieszny błąd Julii - to co jest przed nawiasem to ,,vartheta", ale w komentarzach pojawia się również gdy wpiszemy \theta+TAB)
α₂ = 2
θ₂ = 0.1
α₃ = 5
θ₃ = 0.1

Pocz_rozk_I = Pareto(α₁, θ₁)
Pocz_rozk_II = Pareto(α₂, θ₂)
Pocz_rozk_III = Pareto(α₃, θ₃)
AGENCI = zeros(Nᴵ+Nᴵᴵ+Nᴵᴵᴵ,5,T) #[INDEKS AGENTA, [DZIELNICA,DOCHÓD,PIERWSZA WSPÓŁRZĘDNA,DRUGA WSPÓŁRZĘDNA,CZAS TRWANIA DŁUGU]]

for n in 1:Nᴵ
    AGENCI[n,2,1] = rand(Pocz_rozk_I)
    AGENCI[n,1,1] = 1
    AGENCI[n,3,1] = AGENCI[n,2,1] 
    AGENCI[n,4,1] = rand(Uniform(0, 1))
end



for n in Nᴵ+1:Nᴵᴵ
    AGENCI[n,2,1] = rand(Pocz_rozk_II)
    AGENCI[n,1,1] = 2
    AGENCI[n,3,1] = AGENCI[n,2,1] 
    AGENCI[n,4,1] = rand(Uniform(0, 1))
end

for n in Nᴵᴵ+1:Nᴵᴵᴵ
    AGENCI[n,2,1] = rand(Pocz_rozk_III)
    AGENCI[n,1,1] = 2
    AGENCI[n,3,1] = AGENCI[n,2,1] 
    AGENCI[n,4,1] = rand(Uniform(0, 1))
end

#ILU AGENTÓW MA POCZĄTKOWO NIEZEROWY DŁUG (SPŁATY POZA MODELEM)?
Nᵖᵒᶜᶻᵈᵍ = 
for m in Nᴵ+ Nᴵᴵ + Nᴵᴵᴵ
    n_random = rand(1:Nᴵ+ Nᴵᴵ + Nᴵᴵᴵ) #LOSOWA ZAPADALNOŚĆ DŁUGU - TUTAJ JEST TO LICZBA MIESIĘCY OD ZACIĄGNIĘCIA
    AGENCI[n,5,1] = n_random 
end


rand()

rand(Uniform(0, 1))

for t in 1:T-1
    #WZROST/WAHANIA CEN?
    for n in 1:Nᴵ + Nᴵᴵ + Nᴵᴵᴵ
        if AGENCI[n,1,t] == 3
            AGENCI[n,2,t] == AGENCI[n,2,t-1] + 0.1*rand(Pocz_rozk_III)
            if AGENCI[n,2,t] > AGENCI[n,2,t-1]
               #Szukamy lepszego miejsca
                #próba = rand(Uniform(AGENCI[n,3,t-1],AGENCI[n,2,t]))
                if AGENCI[n,3,t] < P_dolna⁽²⁾ && AGENCI[n,5,t] == 0
                    próba = rand(truncated(Pocz_rozk_III; lower=P_dolna⁽³⁾, upper=P_górna⁽³⁾))
                    AGENCI[n,1,t+1] == 3
                    if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                        AGENCI[n,3,t+1] = próba
                        AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                        AGENCI[n,5,t+1] = 1
                    else
                        AGENCI[n,3,t+1] = AGENCI[n,3,t]
                        AGENCI[n,4,t+1] = AGENCI[n,4,t]
                        AGENCI[n,5,t+1] = 0
                    end
                else
                    próba = rand(truncated(Pocz_rozk_III; lower=P_dolna⁽²⁾, upper=P_górna⁽³⁾))
                    if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                        AGENCI[n,1,t+1] == 2
                        AGENCI[n,3,t+1] = próba
                        AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                        AGENCI[n,5,t+1] = 1
                    else
                        AGENCI[n,1,t+1] == 3
                        AGENCI[n,3,t+1] = AGENCI[n,3,t]
                        AGENCI[n,4,t+1] = AGENCI[n,4,t]
                        AGENCI[n,5,t+1] = 0
                    end
                end
            else
                AGENCI[n,1,t+1] == 3
                AGENCI[n,3,t+1] = AGENCI[n,3,t]
                AGENCI[n,4,t+1] = AGENCI[n,4,t]
                if AGENCI[n,5,t] == 0 | AGENCI[n,5,t] == CZAS
                    AGENCI[n,5,t+1] = 0
                else
                    AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                end
            end
        elseif AGENCI[n,1,t] == 2
            AGENCI[n,2,t] == AGENCI[n,2,t-1] + 0.1*rand(Pocz_rozk_II)
            if AGENCI[n,2,t] > AGENCI[n,2,t-1]
               #Szukamy lepszego miejsca
                #próba = rand(Uniform(AGENCI[n,3,t-1],AGENCI[n,2,t]))
                if AGENCI[n,3,t] < P_dolna⁽²⁾
                    próba = rand(truncated(Pocz_rozk_II; lower=P_dolna⁽²⁾, upper=P_górna⁽²⁾))
                    AGENCI[n,1,t+1] == 2
                    if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                        AGENCI[n,3,t+1] = próba
                        AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                        AGENCI[n,5,t+1] = 1
                    else
                        AGENCI[n,3,t+1] = AGENCI[n,3,t]
                        AGENCI[n,4,t+1] = AGENCI[n,4,t]
                        AGENCI[n,5,t+1] = 0
                    end
                else
                    próba = rand(truncated(Pocz_rozk_II; lower=P_dolna⁽¹⁾, upper=P_górna⁽²⁾))
                     if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                        AGENCI[n,1,t+1] == 1
                        AGENCI[n,3,t+1] = próba
                        AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                        AGENCI[n,5,t+1] = 1
                    else
                        AGENCI[n,1,t+1] == 2
                        AGENCI[n,3,t+1] = AGENCI[n,3,t]
                        AGENCI[n,4,t+1] = AGENCI[n,4,t]
                        AGENCI[n,5,t+1] = 0
                    end
                end
            else
                AGENCI[n,1,t+1] == 3
                AGENCI[n,3,t+1] = AGENCI[n,3,t]
                AGENCI[n,4,t+1] = AGENCI[n,4,t]
                if AGENCI[n,5,t] == 0 | AGENCI[n,5,t] == CZAS
                    AGENCI[n,5,t+1] = 0
                else
                    AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                end
            end
        else
            AGENCI[n,2,t] == AGENCI[n,2,t] + 0.1*rand(Pocz_rozk_I)
            if AGENCI[n,2,t] > AGENCI[n,2,t-1]
               #Szukamy lepszego miejsca
                #próba = rand(Uniform(AGENCI[n,3,t-1],AGENCI[n,2,t]))
                próba = rand(truncated(Pocz_rozk_I; lower=P_górna⁽²⁾, upper=P_górna⁽¹⁾))
                if AGENCI[n,3,t] < próba && AGENCI[n,2,t] > próba
                    próba = rand(truncated(Pocz_rozk_I; lower=P_górna⁽²⁾, upper=P_górna⁽¹⁾))
                    AGENCI[n,1,t+1] == 1
                    AGENCI[n,3,t+1] = próba
                    AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                    AGENCI[n,5,t+1] = 1
                else
                    AGENCI[n,1,t+1] == 1
                    AGENCI[n,3,t+1] = AGENCI[n,3,t]
                    AGENCI[n,4,t+1] = AGENCI[n,4,t]
                    AGENCI[n,5,t+1] = 0
                end
            else
                AGENCI[n,1,t+1] == 1
                AGENCI[n,3,t+1] = AGENCI[n,3,t]
                AGENCI[n,4,t+1] = AGENCI[n,4,t]
                if AGENCI[n,5,t] == 0 | AGENCI[n,5,t] == CZAS
                    AGENCI[n,5,t+1] = 0
                else
                    AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                end
            end
        end 
    end
end

if 2 > 3
    print("Hurra!")
else
    print("Na pohybel!")
end

truncated(Pocz_rozk_I; lower=10, upper=20)

for n in 1:1 + 1 + 1
    println("Działa")
end

println("Działa")
println("Działa")


