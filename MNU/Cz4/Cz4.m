% PROJEKT - CZESC 4
%                   ____                  ____     
%              .---|____|---||---.   .---|____|---.
%              |     R1      C  *| M |*    R2     |
%              |                  )|(             |
%            E ~               L1 )|( L2          |
%              |                  )|(             |
%              |                 |   |            |
%              '-----------------'   '------------'
% 
clc;
clear;

% *** Zainicjowanie modelu ukladu RLC ***

Model = CModel;
% Ustawienie zadanych parametrow, tj:
Model.C = 0.5;   % pojemnosc kondensatora C [F]
Model.R1 = 0.1;  % rezystancja opornika R1 [Ω]
Model.R2 = 10;   % rezystancja opornika R2 [Ω]
Model.L1 = 3;    % indukcyjnosc uzwojenia pierwotnego L1 [H]
Model.L2 = 5;    % indukcyjnosc uzwojenia wtornego L2 [H]
% W czesci 4. projektu transformator ma stala indukcyjnosc wzajemna
Model.Trafo = CTrafo(0.8);
% Zainicjowano transformator o stalej indukcyjnosci wzajemnej M = 0.8


% *** Scenariusz ***

% Realizowane wariant ustawien wg Instrukcji do projektu:
% - cz. 4, bad. 1    sig = 'sine';  u = 100;   T = 1/f;  (0.15-0.20 Hz)
doIt = true;

% Parametry
P = 406;          % zadana moc
a = 0.15;         % dolna granica przedzialu izolacji pierwiastka
b = 0.20;         % gorna granica przedzialu izolacji pierwiastka
e = 1E-4;         % wymagana precyzja oszacowania wartosci pierwiastka

% Zarezerwowanie wektorow wynikowych
F = zeros(3,1);   % wyniki dopasowana czestotliwosci
Z = zeros(3,1);   % wyniki obliczenia funkcji celu (bezwzgl. blad mocy)
I = zeros(3,1);   % liczby iteracji
C = zeros(3,1);   % liczby kalkulacji mocy

if (doIt == true)
  fprintf("\n*** Cz.4, Badanie 1 - Metoda bisekcji ***\n");
  [f,z,n] = research(Model, 30, 'sine', 100, 'dense', P, a,b, @bisectionRoot, e);
  % Umieszczenie wynikow w wektorach
  F(1) = f;  Z(1) = z;  I(1) = n;  C(1) = 3*n;
end 
if (doIt == true)
  fprintf("\n*** Cz.4, Badanie 2 - Metoda siecznych ***\n");
  [f,z,n] = research(Model, 30, 'sine', 100, 'dense', P, a,b, @secantRoot, e);
  % Umieszczenie wynikow w wektorach
  F(2) = f;  Z(2) = z;  I(2) = n;  C(2) = 2 + (2*n);
end 
if (doIt == true)
  fprintf("\n*** Cz.4, Badanie 3 - Metoda Newtona-Raphsona ***\n");
  [f,z,n] = research(Model, 30, 'sine', 100, 'dense', P, a,b, @newtonRoot, e);
  % Umieszczenie wynikow w wektorach
  F(3) = f;  Z(3) = z;  I(3) = n;  C(3) = 8 + (3*n);
end

% Wypisanie na terminalu tabeli z wynikami
printTable(F,Z,I,C);


% *** Funkcje numeryczne ***

function [r, n] = bisectionRoot(Fn, a,b, epsilon)
  % Poszukiwanie pierwiastka iteracyjne - metoda bisekcji,
  % z uzyciem podanej funkcji celu, w zadanym przedziale izolacji
  c = 0;
  % Dopoki nie osiagnieto wystarczajacej dokladnosci, ...
  while ((abs(b - a) > epsilon) && c < 99)
    % ... wyznaczenie srodka przedzialu, ...
    m = (a + b) / 2;
    % ... sprawdzenie czy funkcja zmiena znak 
    %     w pierwszej polowie przedzialu
    if (Fn(a) * Fn(m) < 0)
      % ... - jesli tak, to skroc przedzial przez odciecie gornej polowy
      b = m;
    % ... czy moze w drugiej polowie przedzialu
    elseif (Fn(m) * Fn(b) < 0)
      % ... - jesli tak, to skroc przedzial przez odciecie dolnej polowy
      a = m;
    end
    c = c +1;
  end
  % Zwrocenie wyniku oraz liczby wykonanych iteracji
  r = (a + b) / 2;
  n = c;
end


function [r, n] = secantRoot(Fn, a,b, epsilon)
  % Przyjecie wartosci poczatkowych z krancow przedzialu izolacji
  % i wyliczenie pierwszej poprawki
  y = Fn(b);  delta = y * (b - a) / (y - Fn(a));

  % Poszukiwanie pierwiastka iteracyjne - metoda siecznych,
  % z uzyciem podanej funkcji celu, w zadanym przedziale izolacji
  c = 0;
  % Dopoki nie osiagnieto wystarczajacej dokladnosci, ...
  while ((abs(delta) > epsilon) && c < 99)
    % ... wprowadzenie przyblizenia ...
    a = b;
    b = b - delta;
    % ... i obliczenie kolejnej poprawki
    y = Fn(b);  delta =  y * (b - a) / (y - Fn(a));
    c = c +1;
  end
  % Zwrocenie wyniku oraz liczby wykonanych iteracji
  r = a;
  n = c;
end


function [r, n] = newtonRoot(Fn, a,b, epsilon)
  Dx = 1E-4;
  function d = dFn(x)
    % Wyliczenie pochodnej dla zadanej funkcji Fn,
    % numerycznie, stosujac przyrost Dx wyznaczony eksperymentalnie
    d = (Fn(x + Dx) - Fn(x)) / Dx;
  end
  function d = d2Fn(x)
    % Wyliczenie drugiej pochodnej dla zadanej funkcji Fn,
    % numerycznie, stosujac przyrost Dx wyznaczony eksperymentalnie
    d = (dFn(x + Dx) - dFn(x)) / Dx;
  end

  % Przyjecie wartosci poczatkowej z kranca przedzialu izolacji
  if (Fn(a) * d2Fn(a) > 0)
    x = a;
  else
    x = b;
  end
  % Wyliczenie pierwszej poprawki
  delta = Fn(x) / dFn(x);

  % Poszukiwanie pierwiastka iteracyjne - metoda Newtona-Raphsona,
  % z uzyciem podanej funkcji celu, w zadanym przedziale izolacji
  c = 0;
  % Dopoki nie osiagnieto wystarczajacej dokladnosci, ...
  while ((abs(delta) > epsilon) && c < 99)
    % ... wprowadzenie przyblizenia ...
    x = x - delta;
    % ... i obliczenie kolejnej poprawki
    delta = Fn(x) / dFn(x);
    c = c +1;
  end
  % Zwrocenie wyniku oraz liczby wykonanych iteracji
  r = x;
  n = c;
end


% Numeryczne calkowanie metoda prostokatow
function f = intRect(Y, dx)
  % Ustalenie ilosci podprzedzialow
  n = length(Y) -1;
  f = 0;
  % Dla kazdego podprzedzialu ...
  for i = 1 : n
    % ... doliczenie powierzchni slupka (prostokata)
    f = f + Y(i) * dx;
  end
end


% *** Badanie i prezentacja wynikow ***

function [f, z, n] = research(Model, timespan, sig, U, density, P, a,b, method, epsilon)

  function z = Fn(f)
    % Zainicjowanie obiektu z szeregiem czasowym napiecia wymuszajacego
    Signal = CSignal(timespan, sig, U, 1/f, density);
    h = Signal.step;
    % Wykonanie obliczen stanow chwilowych
    StateArray = Model.solveImprovedEuler(Signal);

    % Wyliczenie chwilowych wartosci mocy wydzielanej na opornikach
    % wzor: P = R * i^2
    Pf = Model.R1 * StateArray(1, :).^2 ...
       + Model.R2 * StateArray(2, :).^2;
    % Wyliczenie mocy przez scalkowanie wartosci chwilowych oraz zwrocenie
    % roznicy miedzy moca wyliczona a oczekiwana (wynik tzw. funkcji celu)
    z = (intRect(Pf, h) / Signal.time(end)) - P;
  end

  % Poszukiwanie miejsca zerowego funkcji celu Fn 
  % (tj. takiej czestotliwosci z przedzialu <a,b>, dla ktorej moc wynosi P)
  [f, n] = method(@Fn, a,b, epsilon);
  fprintf("Znaleziono wynik %.6G Hz (%d iteracji).\n", f, n);
  % Zwrocenie wartosci potrzebnych do raportu
  z = Fn(f);
end


function printTable(F,Z,I,C)
  fprintf("\nWyniki:\n");
  % Przygotowanie tabelki z zestawieniem wynikow
  Metoda = ["bisekcji"
            "siecznych"
            "quasi Newtona"];
  Czestotliwosc = F;
  FunkcjaCelu = Z;
  Iteracje = I;
  Kalkulacje = C;
  disp(table(Metoda, Czestotliwosc, FunkcjaCelu, Iteracje, Kalkulacje));
end
