% PROJEKT - CZESC 3Z
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
% W czesci 3Z projektu transformator ma zmienna indukcyjnosc wzajemna,
% ktora okresla ponizsza charakterystyka M = f(|uL|) [H]
Model.Trafo = CTrafo([  20,   50,  100,  150,  200,  250,  280,  300;
                      0.46, 0.64, 0.78, 0.68, 0.44, 0.23, 0.18, 0.18]);
% Zainicjowano transformator o ww. nieliniowej indukcyjnosci


% *** Scenariusz ***

% Realizowane warianty ustawien wg Instrukcji do projektu:
% - cz. 3Z, przyklad  sig = 'sine';  u = 1;     T = 2*pi;  (sin t)
% - cz. 3Z, bad. 1    sig = 'DC';    u = 1;     T = 0;     (staly)
% - cz. 3Z, bad. 1.1    "metoda prostokatow"
% - cz. 3Z, bad. 1.2    "metoda parabol"
% - cz. 3Z, bad. 2    sig = 'sqre';  u = 120;   T = 3;
% - cz. 3Z, bad. 2.1    "metoda prostokatow"
% - cz. 3Z, bad. 2.2    "metoda parabol"
% - cz. 3Z, bad. 3    sig = 'sine';  u = 240;   T = 2*pi;  (sin t)
% - cz. 3Z, bad. 3.1    "metoda prostokatow"
% - cz. 3Z, bad. 3.2    "metoda parabol"
% - cz. 3Z, bad. 4    sig = 'sine';  u = 210;   T = 1/5;   (f = 5 Hz)
% - cz. 3Z, bad. 4.1    "metoda prostokatow"
% - cz. 3Z, bad. 4.2    "metoda parabol"
% - cz. 3Z, bad. 5    sig = 'sine';  u = 120;   T = 1/50;  (f = 50 Hz)
% - cz. 3Z, bad. 5.1    "metoda prostokatow"
% - cz. 3Z, bad. 5.2    "metoda parabol"
doIt = true;

% Seria A - Z MALYM KROKIEM CZASOWYM

if (doIt == true)
  % Zarezerwowanie wektorow wynikowych
  Pa = zeros(5,1);  % wyniki calkowania metoda prostokatow
  Pb = zeros(5,1);  % wyniki calkowania metoda Simpsona (parabol)

  if (doIt == false)
    fprintf("\n*** Cz.3Z, Przykład z instrukcji do projektu ***\n");
    research(Model, 30, 'sine', 1, 2*pi, 'normal');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 1A ***\n");
    [Pa(1), Pb(1)] = research(Model, 30, 'DC', 1, 1/0, 'dense');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 2A ***\n");
    [Pa(2), Pb(2)] = research(Model, 30, 'sqre', 120, 3, 'dense');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 3A ***\n");
    [Pa(3), Pb(3)] = research(Model, 30, 'sine', 240, 2*pi, 'dense');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 4A ***\n");
    [Pa(4), Pb(4)] = research(Model, 30, 'sine', 210, 1/5, 'dense');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 5A ***\n");
    [Pa(5), Pb(5)] = research(Model, 30, 'sine', 120, 1/50, 'dense');
  end

  % Wypisanie na terminalu tabeli z wynikami
  fprintf("\n*** Wyniki obliczeń z małym krokiem czasowym ***\n");
  printTable(Pa, Pb);
end

% Seria B - Z DUZYM KROKIEM CZASOWYM

if (doIt == true)
  % Zarezerwowanie wektorow wynikowych
  Pa = zeros(5,1);  % wyniki calkowania metoda prostokatow
  Pb = zeros(5,1);  % wyniki calkowania metoda Simpsona (parabol)

  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 1B ***\n");
    [Pa(1), Pb(1)] = research(Model, 30, 'DC', 1, 1/0, 'light');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 2B ***\n");
    [Pa(2), Pb(2)] = research(Model, 30, 'sqre', 120, 3, 'light');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 3B ***\n");
    [Pa(3), Pb(3)] = research(Model, 30, 'sine', 240, 2*pi, 'light');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 4B ***\n");
    [Pa(4), Pb(4)] = research(Model, 30, 'sine', 210, 1/5, 'light');
  end
  if (doIt == true)
    fprintf("\n*** Cz.3Z, Badanie 5B ***\n");
    [Pa(5), Pb(5)] = research(Model, 30, 'sine', 120, 1/50, 'light');
  end

  % Wypisanie na terminalu tabeli z wynikami
  fprintf("\n*** Wyniki obliczeń z dużym krokiem czasowym ***\n");
  printTable(Pa, Pb);
end


% *** Funkcje numeryczne ***

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

% Numeryczne calkowanie metoda parabol
function f = intSimpson(Y, dx)
  % Ustalenie ilosci podprzedzialow
  n = length(Y) -1;
  f = 0;
  % Dla kazdego co drugiego podprzedzialu ...
  for i = 2 : 2 : n
    % ... doliczenie powierzchni slupka (prostokata zwienczonego parabola)
    f = f + 1/3 * (Y(i -1) + 4 * Y(i) + Y(i +1)) * dx;
  end
  % ... z ewentualna korekta (doliczeniem ostatniego slupka prostokatnego),
  % gdy ilosc podprzedzialow byla nieparzysta, bo parabole da sie stworzyc
  % tylko z parzystej ilosci podprzedzialow
  if (mod(n, 2) ~= 0)
    f = f + Y(end) * dx;
  end
end


% *** Badanie i prezentacja wynikow ***

function [Pa, Pb] = research(Model, timespan, sig, u, T, density)
  % Zainicjowanie obiektu z szeregiem czasowym napiecia wymuszajacego, ...
  Signal = CSignal(timespan, sig, u, T, density);
  n = length(Signal.time);
  h = Signal.step;
  % ... z wypisaniem komunikatu na terminalu
  info = "Wygenerowano %d s. sygnał e(t) : ";
  fprintf(info, timespan); fprintf(Signal.caption + "\n");

  % Wykonanie obliczen stanow chwilowych, ...
  StateArray = Model.solveImprovedEuler(Signal);
  fprintf("Wyliczono metodą ulepszoną Eulera %d stanów układu, " ...
        + "z krokiem czasowym %.6G s.\n", n, h);
  % ... i utworzenie wykresow (dla wizualnej oceny czy rozwiazanie jest stabilne)
  drawCharts(Signal, StateArray);

  % Wyliczenie chwilowych wartosci mocy wydzielanej na opornikach
  % wzor: P = R * i^2
  P = Model.R1 * StateArray(1, :).^2 ...
    + Model.R2 * StateArray(2, :).^2;

  % Wyliczenie mocy - metoda 1), ...
  % ... tj. scalkowanie wartosci chwilowych metoda prostokatow ...
  Pa = intRect(P, h) / timespan;
  % ... i wypisanie komunikatu na terminalu
  info = "Moc wydzielana na opornikach, obliczona przez scałkowanie stanów chwilowych ";
  fprintf(info + "metodą prostokątów, wynosi: %.6G W\n", Pa);

  % Wyliczenie mocy - metoda 2), ...
  % ... tj. scalkowanie wartosci chwilowych metoda parabol (Simpsona) ...
  Pb = intSimpson(P, h) / timespan;
  % ... i wypisanie komunikatu na terminalu
  fprintf(info + "metodą Simpsona, wynosi: %.6G W\n", Pb);
end


function printTable(Pa, Pb)
  fprintf("\n");
  % Przygotowanie tabelki z zestawieniem wynikow
  Wymuszenie = ["e(t) = 1"
                "E = .5T:120 / .5T:0, T = 3 s"
                "e(t) = 240 sin(t)"
                "e(t) = 210 sin(2πft), f = 5 Hz"
                "e(t) = 120 sin(2πft), f = 50 Hz"];
  Prostokaty = Pa;
  Parabole = Pb;
  disp(table(Wymuszenie, Prostokaty, Parabole));
end


function drawCharts(Signal, StateArray)
  % Prezentacja przebiegow na wykresach, w tym: ...
  % ... wykres napiecia
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, Signal.voltage);
  title("Napięcie wymuszające", "e(t) : " + Signal.caption);
  xlabel("t [s]");
  ylabel("e [V]");
  grid on;

  % ... wykres pradow w obwodzie pierwotnym i wtornym
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray(1,:), ...
       Signal.time, StateArray(2,:));
  title("Prąd w obwodzie pierwotnym i wtórnym", "e(t) : " + Signal.caption);
  legend("i_1", "i_2");
  xlabel("t [s]");
  ylabel("i [A]");
  grid on;
end
