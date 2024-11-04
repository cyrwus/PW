% PROJEKT - CZESC 1
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
% W czesci 1. projektu transformator ma stala indukcyjnosc wzajemna
Model.Trafo = CTrafo(0.8);
% Zainicjowano transformator o stalej indukcyjnosci wzajemnej M = 0.8


% *** Scenariusz ***

% Realizowane warianty ustawien wg Instrukcji do projektu:
% - cz. 1, przyklad  sig = 'sine';  u = 1;     T = 2*pi;  (sin t)
% - cz. 1, bad. 1    sig = 'sqre';  u = 120;   T = 3;
% - cz. 1, bad. 2    sig = 'sine';  u = 240;   T = 2*pi;  (sin t)
% - cz. 1, bad. 3    sig = 'sine';  u = 210;   T = 1/5;   (f = 5 Hz)
% - cz. 1, bad. 4    sig = 'sine';  u = 120;   T = 1/50;  (f = 50 Hz)
doIt = true;

if (doIt == false)
  fprintf("\n*** Cz.1, Przykład z instrukcji do projektu ***\n");
  research(Model, 30, 'sine', 1, 2*pi, 'normal');
end
if (doIt == true)
  fprintf("\n*** Cz.1, Badanie 1 ***\n");
  research(Model, 30, 'sqre', 120, 3, 'normal');
end
if (doIt == true)
  fprintf("\n*** Cz.1, Badanie 2 ***\n");
  research(Model, 30, 'sine', 240, 2*pi, 'normal');
end
if (doIt == true)
  fprintf("\n*** Cz.1, Badanie 3 ***\n");
  research(Model, 30, 'sine', 210, 1/5, 'normal');
end
if (doIt == true)
  fprintf("\n*** Cz.1, Badanie 4 ***\n");
  research(Model, 30, 'sine', 120, 1/50, 'light');
end


% *** Badanie i prezentacja wynikow ***

function research(Model, timespan, sig, u, T, density)
  % Zainicjowanie obiektu z szeregiem czasowym napiecia wymuszajacego, ...
  Signal = CSignal(timespan, sig, u, T, density);
  n = length(Signal.time);
  % ... z wypisaniem komunikatu na terminalu
  info = "Wygenerowano %d s. sygnał e(t) : ";
  fprintf(info, timespan); fprintf(Signal.caption + "\n");

  % Wykonanie obliczen stanow chwilowych z zastos. metody Eulera, ...
  StateArray = Model.solveEuler(Signal);
  % ... i wypisanie komunikatu na terminalu
  info = "\nWyliczono %d stanów układu ";
  fprintf(info + "stosując metodę Eulera.\n", n);
  % Utworzenie wykresow
  drawCharts(Signal, StateArray);

  % Wykonanie obliczen stanow chwilowych z zastos. metody ulepszonej Eulera, ...
  StateArray = Model.solveImprovedEuler(Signal);
  % ... i wypisanie komunikatu na terminalu
  fprintf(info + "stosując metodę ulepszoną Eulera.\n", n);
  % Utworzenie wykresow
  drawCharts(Signal, StateArray);
end


function drawCharts(Signal, StateArray)
  % Prezentacja wynikow na wykresach, w tym: ...
  % ... wykres napięcia wymuszajacego
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, Signal.voltage);
  chartTitle = "Napięcie wymuszające";
  title(chartTitle, "e(t) : " + Signal.caption);
  xlabel("t [s]");
  ylabel("e [V]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), chartTitle);

  % ... wykres pradow w obwodzie pierwotnym i wtornym
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray(1,:), ...
       Signal.time, StateArray(2,:));
  chartTitle = "Prąd w obwodzie pierwotnym i wtórnym";
  title(chartTitle, "e(t) : " + Signal.caption);
  legend("i_1", "i_2");
  xlabel("t [s]");
  ylabel("i [A]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), chartTitle);

  % ... wykres napiecia na kondensatorze
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray(3,:));
  chartTitle = "Napięcie na kondensatorze";
  title(chartTitle, "e(t) : " + Signal.caption);
  xlabel("t [s]");
  ylabel("u_C [V]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), chartTitle);
end
