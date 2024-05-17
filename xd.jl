#xd

## Main Simulation Function
using Plots, LinearAlgebra, Statistics, Distributions, StatsBase, DataFrames

function schelling_sym(
    N_param::Float64 = 0.25, 
    bounds_param::Float64 = 1/1000,
    α₁::Float64 = 1.0,
    θ₁::Float64 = 0.1,
    α₂::Float64 = 2.0,
    θ₂::Float64 = 0.1,
    α₃::Float64 = 5.0,
    θ₃::Float64 = 0.1,
    T::Int64 = 12 * 40,
    przyrost_param::Float64 = 0.1
    )
    # N_param = 0.25
    # bounds_param = 1/1000

    # Liczba agentów rodzaju I
    Nᴵ = round(Int, 5000 * N_param)
    # Liczba agentów rodzaju II
    Nᴵᴵ = round(Int, 25000 * N_param) 
    # Liczba agentów rodzaju III
    Nᴵᴵᴵ = round(Int, 50000 * N_param)  # SUMA 80000 (8*10^4)
    #Ceny
    P_górna⁽¹⁾ = round(Int, 35000 * bounds_param)
    P_górna⁽²⁾ = round(Int, 25000 * bounds_param)
    P_dolna⁽¹⁾ = round(Int, 23000 * bounds_param)
    P_górna⁽³⁾ = round(Int, 19000 * bounds_param)
    P_dolna⁽²⁾ = round(Int, 18000 * bounds_param)
    P_dolna⁽³⁾ = round(Int, 8000 * bounds_param)

    # T = 12 * 40 #12 miesięcy - rok, 20 lat
    CZAS = 12 * 15 #Piętnastoletnie ,,pożyczki" - zablokowanie czasu do szukania nowego mieszkania (można szukać tylko gdy CZASₙ = 0);

    #Początkowe rozmieszczenie - przestrzenie trzech dzielnic: ciągłe
    # α₁ = 1 #Współczynnik kształtu - im większy tym ,,chudszy" ogon rozkładu PAreta
    # θ₁ = 0.1 #Skala - dla rozkładów Pareta x > θ (śmieszny błąd Julii - to co jest przed nawiasem to ,,vartheta", ale w komentarzach pojawia się również gdy wpiszemy \theta+TAB)
    # α₂ = 2
    # θ₂ = 0.1
    # α₃ = 5
    # θ₃ = 0.1

    Pocz_rozk_I = Pareto(α₁, θ₁)
    Pocz_rozk_II = Pareto(α₂, θ₂)
    Pocz_rozk_III = Pareto(α₃, θ₃)

    AGENCI = zeros(Float64, Nᴵ + Nᴵᴵ + Nᴵᴵᴵ, 5, T)  # [INDEKS AGENTA, [DZIELNICA,DOCHÓD,PIERWSZA WSPÓŁRZĘDNA,DRUGA WSPÓŁRZĘDNA,CZAS TRWANIA DŁUGU],T]
    # przyrost_param = 0.1
    
    for n in 1:Nᴵ
         while AGENCI[n,2,1] <= 0 || AGENCI[n,2,1] > P_górna⁽¹⁾ || AGENCI[n,2,1] < P_dolna⁽¹⁾
            AGENCI[n,2,1] = rand(Pocz_rozk_I) * (P_górna⁽¹⁾ - P_dolna⁽¹⁾) + P_dolna⁽¹⁾ #MOŻE TO BYĆ INNY MNOŻNIK, ALE SAMO P_górna MOŻE ZABRAĆ                                                                                                #WIĘCEJ CZASU
        end
        AGENCI[n,1,1:2] .= 1
        AGENCI[n,3,1:2] .= AGENCI[n,2,1] 
        AGENCI[n,4,1:2] .= rand(Uniform(0, 1))
    end
     
    for n in Nᴵ+1:Nᴵ+Nᴵᴵ
        while AGENCI[n,2,1] <= 0 || AGENCI[n,2,1] > P_górna⁽²⁾ || AGENCI[n,2,1] < P_dolna⁽²⁾
            AGENCI[n,2,1] = rand(Pocz_rozk_II) * (P_górna⁽²⁾ - P_dolna⁽²⁾) + P_dolna⁽²⁾ 
        end
        AGENCI[n,1,1:2] .= 2
        AGENCI[n,3,1:2] .= AGENCI[n,2,1] 
        AGENCI[n,4,1:2] .= rand(Uniform(0, 1))
    end
     
    for n in Nᴵ+Nᴵᴵ+1:Nᴵ+Nᴵᴵ+Nᴵᴵᴵ
        while AGENCI[n,2,1] <= 0 || AGENCI[n,2,1] > P_górna⁽³⁾ || AGENCI[n,2,1] < P_dolna⁽³⁾
            AGENCI[n,2,1] = rand(Pocz_rozk_III) * (P_górna⁽³⁾ - P_dolna⁽³⁾) + P_dolna⁽³⁾ 
        end
        AGENCI[n,1,1:2] .= 3
        AGENCI[n,3,1:2] .= AGENCI[n,2,1] 
        AGENCI[n,4,1:2] .= rand(Uniform(0, 1))
    end
    
    #ILU AGENTÓW MA POCZĄTKOWO NIEZEROWY DŁUG (SPŁATY POZA MODELEM)?
    Nᵖᵒᶜᶻᵈᵍ = Nᴵ+Nᴵᴵ+Nᴵᴵᴵ
    X = rand(1:Nᴵ + Nᴵᴵ + Nᴵᴵᴵ,Nᵖᵒᶜᶻᵈᵍ)
    for m in 1:Nᵖᵒᶜᶻᵈᵍ
        AGENCI[X[m],5,1] =  rand(1:CZAS) #LOSOWA ZAPADALNOŚĆ DŁUGU - TUTAJ JEST TO LICZBA MIESIĘCY OD ZACIĄGNIĘCIA
        if AGENCI[X[m],5,1] == CZAS
            AGENCI[X[m],5,2] = 0
        else
            AGENCI[X[m],5,2] = AGENCI[X[m],5,1] + 1
        end
    end
    
    for t in 2:T-1
        #WZROST/WAHANIA CEN?
        for n in 1:Nᴵ + Nᴵᴵ + Nᴵᴵᴵ
            # if n != 1
            #     continue
            # end 
            # Czy jestem w dzielnicy 3?
            if AGENCI[n,1,t] == 3
                przyrost = rand(Pocz_rozk_III)*P_górna⁽³⁾*przyrost_param
                while przyrost > P_górna⁽³⁾
                    przyrost = rand(Pocz_rozk_III)*P_górna⁽³⁾*przyrost_param
                end
                #Zwiększanie majątku
                AGENCI[n,2,t] = AGENCI[n,2,t-1] + przyrost
                #Jeżeli mój majątek wzrósł i nie mam długu
                if AGENCI[n,2,t] > AGENCI[n,2,t-1] && AGENCI[n,5,t] == 0
                   #Szukamy lepszego miejsca
                   #Jeżeli mieszkam w domu kwalifikującym mnie do dzielnicy 3
                    if AGENCI[n,3,t] < P_dolna⁽²⁾ 
                        # print("3.1")
                        #Losujemy jakiś do z dzielnicy 3
                        próba = rand(truncated(Pocz_rozk_III; lower=P_dolna⁽³⁾, upper=P_górna⁽³⁾))
                        AGENCI[n,1,t+1] = 3
                        # Jeżeli móju majątek jest większy niż cena domu, a dom droższy od aktualnego
                        # to go kupuje i losujemy lokalizacje
                        if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                            AGENCI[n,3,t+1] = próba
                            AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                            AGENCI[n,5,t+1] = 1 # Zakup zaciągnieciem długu
                        else
                            AGENCI[n,3,t+1] = AGENCI[n,3,t]
                            AGENCI[n,4,t+1] = AGENCI[n,4,t]
                            AGENCI[n,5,t+1] = 0 #Brak długu
                        end
                    #Jeśli mój majątek umożliwia mi przeniesienie się do dzielnicy wyżej
                    else
                        # print("3.2")
                         #Losujemy jakiś do z dzielnicy 2 (ale nie droższy niż najdroższy z 3)
                        próba = rand(truncated(Pocz_rozk_III; lower=P_dolna⁽²⁾, upper=P_górna⁽³⁾))
                        # Jeżeli móju majątek jest większy niż cena domu, a dom droższy od aktualnego
                        # to go kupuje i losujemy lokalizacje
                        if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                            AGENCI[n,1,t+1] = 2
                            AGENCI[n,3,t+1] = próba
                            AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                            AGENCI[n,5,t+1] = 1 # Zakup skutkuje długiem
                        else
                            AGENCI[n,1,t+1] = 3
                            AGENCI[n,3,t+1] = AGENCI[n,3,t]
                            AGENCI[n,4,t+1] = AGENCI[n,4,t]
                            AGENCI[n,5,t+1] = 0 #Brak długu
                        end
                    end
                 # Jeśli mój majątek "spadł" lub miałem dług to:
                else
                    # print("3.3")
                    AGENCI[n,1,t+1] = 3
                    AGENCI[n,3,t+1] = AGENCI[n,3,t]
                    AGENCI[n,4,t+1] = AGENCI[n,4,t]
                    # Jak długu nie miałem lub nadszedł czas jego spłaty to dług się zeruje
                    if AGENCI[n,5,t] == 0 || AGENCI[n,5,t] == CZAS
                        AGENCI[n,5,t+1] = 0
                    # W przeciwym wypadku mój dług rośnie
                    else
                        AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                    end
                end
            elseif AGENCI[n,1,t] == 2 
                przyrost = rand(Pocz_rozk_II)*P_górna⁽²⁾*przyrost_param
                while przyrost > P_górna⁽²⁾
                    przyrost = rand(Pocz_rozk_II)*P_górna⁽²⁾*przyrost_param
                end
                AGENCI[n,2,t] = AGENCI[n,2,t-1] + przyrost
                if AGENCI[n,2,t] > AGENCI[n,2,t-1] && AGENCI[n,5,t] == 0
                   #Szukamy lepszego miejsca
                    #próba = rand(Uniform(AGENCI[n,3,t-1],AGENCI[n,2,t]))
                    if AGENCI[n,3,t] < P_dolna⁽¹⁾
                        # print("2.1")
                        próba = rand(truncated(Pocz_rozk_II; lower=P_dolna⁽²⁾, upper=P_górna⁽²⁾))
                        AGENCI[n,1,t+1] = 2
                        if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                            AGENCI[n,1,t+1] = 2 # to musialem dodać
                            AGENCI[n,3,t+1] = próba
                            AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                            AGENCI[n,5,t+1] = 1
                        else
                            AGENCI[n,1,t+1] = 2 # to musialem dodać
                            AGENCI[n,3,t+1] = AGENCI[n,3,t]
                            AGENCI[n,4,t+1] = AGENCI[n,4,t]
                            AGENCI[n,5,t+1] = 0
                        end
                    else
                        # print("2.2")
                        próba = rand(truncated(Pocz_rozk_II; lower=P_dolna⁽¹⁾, upper=P_górna⁽²⁾))
                         if próba > AGENCI[n,3,t] && AGENCI[n,2,t] > próba
                            AGENCI[n,1,t+1] = 1
                            AGENCI[n,3,t+1] = próba
                            AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                            AGENCI[n,5,t+1] = 1
                        else
                            AGENCI[n,1,t+1] = 2
                            AGENCI[n,3,t+1] = AGENCI[n,3,t]
                            AGENCI[n,4,t+1] = AGENCI[n,4,t]
                            AGENCI[n,5,t+1] = 0
                        end
                    end
                else
                    # print("2.3")
                    AGENCI[n,1,t+1] = 2
                    AGENCI[n,3,t+1] = AGENCI[n,3,t]
                    AGENCI[n,4,t+1] = AGENCI[n,4,t]
                    if AGENCI[n,5,t] == 0 || AGENCI[n,5,t] == CZAS
                        AGENCI[n,5,t+1] = 0
                    else
                        AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                    end
                end
            else
                przyrost = rand(Pocz_rozk_I)*P_górna⁽¹⁾*przyrost_param
                while przyrost > P_górna⁽¹⁾
                    przyrost = rand(Pocz_rozk_I)*P_górna⁽¹⁾*przyrost_param
                end
                AGENCI[n,2,t] = AGENCI[n,2,t-1] + przyrost
                if AGENCI[n,2,t] > AGENCI[n,2,t-1]  && AGENCI[n,5,t] == 0
                    # print("1.1")
                   #Szukamy lepszego miejsca
                    #próba = rand(Uniform(AGENCI[n,3,t-1],AGENCI[n,2,t]))
                    próba = rand(truncated(Pocz_rozk_I; lower=P_górna⁽²⁾, upper=P_górna⁽¹⁾))
                    if AGENCI[n,3,t] < próba && AGENCI[n,2,t] > próba
                        # próba = rand(truncated(Pocz_rozk_I; lower=P_górna⁽²⁾, upper=P_górna⁽¹⁾))
                        AGENCI[n,1,t+1] = 1
                        AGENCI[n,3,t+1] = próba
                        AGENCI[n,4,t+1] = rand(Uniform(0, 1))
                        AGENCI[n,5,t+1] = 1
                    else
                        AGENCI[n,1,t+1] = 1
                        AGENCI[n,3,t+1] = AGENCI[n,3,t]
                        AGENCI[n,4,t+1] = AGENCI[n,4,t]
                        AGENCI[n,5,t+1] = 0
                    end
                else
                    # print("1.2")
                    AGENCI[n,1,t+1] = 1
                    AGENCI[n,3,t+1] = AGENCI[n,3,t]
                    AGENCI[n,4,t+1] = AGENCI[n,4,t]
                    if AGENCI[n,5,t] == 0 || AGENCI[n,5,t] == CZAS
                        AGENCI[n,5,t+1] = 0
                    else
                        AGENCI[n,5,t+1] = AGENCI[n,5,t] + 1
                    end
                end
            end 
        end
    end
    return AGENCI
end

## Calulate percent changes
function percent_change!(df::DataFrame, column::String)
    df[!, Symbol(string(column, "_pct"))] = [missing; diff(df[!, column])./ df[1:end-1, column]]
end

## Calc counts
function calc_counts(AGENCI::Array)
    dzielnice_counts_df = DataFrame()
    for t in 1:T
        to_count = string.(AGENCI[:,1:1,t])
        counts = countmap(to_count)
        # print(t)
        for key in ["1.0", "2.0", "3.0"]
            if !(key in keys(counts))
                counts[key] = 0
            end 
        end
        if t == 1
            dzielnice_counts_df = DataFrame(counts)
        else
            tmp_df = DataFrame(copy(counts))
            dzielnice_counts_df = vcat(dzielnice_counts_df,tmp_df)
        end
    end
    dzielnice_counts_df[!,:RowSum] = [sum(row) for row in eachrow(dzielnice_counts_df)];
    
    rename!(dzielnice_counts_df, Dict(:1 => :district_1));
    rename!(dzielnice_counts_df, Dict(:2 => :district_2));
    rename!(dzielnice_counts_df, Dict(:3 => :district_3));
    for col in names(dzielnice_counts_df)
        percent_change!(dzielnice_counts_df, col)
        # add_log_returns!(dzielnice_counts_df, col)
    end
    dzielnice_counts_df[!,:district_1_shr] = dzielnice_counts_df[:, :district_1] ./ dzielnice_counts_df[:, :RowSum]
    dzielnice_counts_df[!,:district_2_shr] = dzielnice_counts_df[:, :district_2] ./ dzielnice_counts_df[:, :RowSum]
    dzielnice_counts_df[!,:district_3_shr] = dzielnice_counts_df[:, :district_3] ./ dzielnice_counts_df[:, :RowSum]
    return (dzielnice_counts_df)
end