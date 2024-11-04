% PROJEKT - CZESC 2
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
% W czesci 2. projektu transformator ma zmienna indukcyjnosc wzajemna,
% ktora okresla ponizsza charakterystyka M = f(|uL|) [H]
Model.Trafo = CTrafo([  20,   50,  100,  150,  200,  250,  280,  300;
                      0.46, 0.64, 0.78, 0.68, 0.44, 0.23, 0.18, 0.18]);
% Zainicjowano transformator o ww. nieliniowej indukcyjnosci


% *** Scenariusz ***

% Realizowane warianty ustawien wg instrukcji do projektu 
% oraz dodatkowa wskazowka podana na forum:
% - cz. 2, bad. 1    sig = 'sine';  u = 240;   T = pi;    (sin 2t)
% - cz. 2, bad. 1.a    "Lagrange"
% - cz. 2, bad. 1.b    "Spline"
% - cz. 2, bad. 1.c    "3degPolynomial"
% - cz. 2, bad. 1.d    "5degPolynomial"
% - cz. 2, bad. 2    sig = 'sine';  u = 120;   T = 1/50;  (f = 50 Hz)
% - cz. 2, bad. 2.a    "Lagrange"
% - cz. 2, bad. 2.b    "Spline"
% - cz. 2, bad. 2.c    "3degPolynomial"
% - cz. 2, bad. 2.d    "5degPolynomial"
doIt = true;

if (doIt == true)
  fprintf("\n*** Cz.2, Badanie 1 ***\n");
  research(Model, 30, 'sine', 240, pi, 'normal');
end
if (doIt == true)
  fprintf("\n*** Cz.2, Badanie 2 ***\n");
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

  % Wykonanie obliczen stanow chwilowych dla pkt. a) ...
  Model.Trafo.smoothing = Model.Trafo.smoothingMethod('Lagrange');
  S = Model.solveImprovedEuler(Signal);
  StateArray = S;
  % ... i wypisanie komunikatu na terminalu
  info = "Wyliczono %d stanów układu z nieliniową indukcyjnością wzajemną,";
  fprintf(info + " stosując interpolację wielomianem Langrange'a.\n", n);

  % Wykonanie obliczen stanow chwilowych dla pkt. b) ...
  Model.Trafo.smoothing = Model.Trafo.smoothingMethod('Spline');
  S = Model.solveImprovedEuler(Signal);
  StateArray = [StateArray; S];
  % ... i wypisanie komunikatu na terminalu
  fprintf(info + " stosując interpolację funkcjami sklejanymi 3. stopnia.\n", n);

  % Wykonanie obliczen stanow chwilowych dla pkt. c) ...
  Model.Trafo.smoothing = Model.Trafo.smoothingMethod('3degPolynomial');
  S = Model.solveImprovedEuler(Signal);
  StateArray = [StateArray; S];
  % ... i wypisanie komunikatu na terminalu
  fprintf(info + " stosując aproksymację wielomianem 3. stopnia.\n", n);

  % Wykonanie obliczen stanow chwilowych dla pkt. d) ...
  Model.Trafo.smoothing = Model.Trafo.smoothingMethod('5degPolynomial');
  S = Model.solveImprovedEuler(Signal);
  StateArray = [StateArray; S];
  % ... i wypisanie komunikatu na terminalu
  fprintf(info + " stosując aproksymację wielomianem 5. stopnia.\n", n);

  % Naniesienie wynikow na wykresy
  drawCharts(Signal, StateArray, Model.R2);
end


function drawCharts(Signal, StateArray, R2)
  % Prezentacja wynikow na wykresach, w tym: ...
  % ... wykres pradow w obwodzie pierwotnym (zaleznie od metody int./apr.)
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray( 1,:), ...
       Signal.time, StateArray( 4,:), ...
       Signal.time, StateArray( 7,:), ...
       Signal.time, StateArray(10,:));
  title("Prąd i_1 dla różnych metod wygładzania charakterystyki M = f(u_L)", ...
        "e(t) : " + Signal.caption);
  series = ["interpolacja wielom. Legendre'a", ...
            "interpolacja funkcją sklejaną 3. stopnia", ...
            "aproksymacja wielom. 3. stopnia", ...            
            "aproksymacja wielom. 5. stopnia"];
  legend(series);
  xlabel("t [s]");
  ylabel("i_1 [A]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), ...
          "Prąd i1 (w obwodzie pierwotnym)");

  % ... wykres pradow w obwodzie wtornym (zaleznie od metody int./apr.)
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray( 2,:), ...
       Signal.time, StateArray( 5,:), ...
       Signal.time, StateArray( 8,:), ...
       Signal.time, StateArray(11,:));
  title("Prąd i_2 dla różnych metod wygładzania charakterystyki M = f(u_L)", ...
        "e(t) : " + Signal.caption);
  legend(series);
  xlabel("t [s]");
  ylabel("i_2 [A]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), ...
          "Prąd i2 (w obwodzie wtórnym)");

  % ... wykres napiecia na oporniku R2 (zaleznie od metody int./apr.)
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, R2 * StateArray( 2,:), ...
       Signal.time, R2 * StateArray( 5,:), ...
       Signal.time, R2 * StateArray( 8,:), ...
       Signal.time, R2 * StateArray(11,:));
  title("Napięcie na oporniku R_2 " + ...
        "dla różnych metod wygładzania charakterystyki M = f(u_L)", ...
        "e(t) : " + Signal.caption);
  legend(series);
  xlabel("t [s]");
  ylabel("u_{R2} [V]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), ...
          "Napięcie na oporniku R2 (w obwodzie wtórnym)");

  % ... wykres napiecia na kondensatorze
  figure;
  set(gcf, 'Color', [0xf7,0xf7,0xf7]);
  plot(Signal.time, StateArray( 3,:), ...
       Signal.time, StateArray( 6,:), ...
       Signal.time, StateArray( 9,:), ...
       Signal.time, StateArray(12,:));
  title("Napięcie na kondensatorze " + ...
        "dla różnych metod wygładzania charakterystyki M = f(u_L)", ...
        "e(t) : " + Signal.caption);
  legend(series);
  xlabel("t [s]");
  ylabel("u_C [V]");
  grid on;
  fprintf("Wykres w oknie %d: %s ...\n", get(gcf, 'Number'), ...
          "Napięcie na kondensatorze");
end
