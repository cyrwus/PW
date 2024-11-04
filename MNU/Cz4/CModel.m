
classdef CModel
  properties
    % Wlasciwosci elementow ukladu
    R1;    % rezystancja opornika R1 [Ω]
    R2;    % rezystancja opornika R2 [Ω]
    C;     % pojemnosc kondensatora C [F]
    L1;    % indukcyjnosc uzwojenia pierwotnego L1 [H]
    L2;    % indukcyjnosc uzwojenia wtornego L2 [H]
    M;     % indukcyjnosc wzajemna M [H]
    % Transformator, jako instancja klasy CTrafo
    Trafo;
  end
  properties (Access = private)
    A, V;  % macierzowa postac ukladu rownan rozniczkowych opisujacych obwod
  end


  methods
    % Konstruktor
    function obj = CModel
      obj.M = 0;
    end

    function [StateArray] = solveEuler(obj, Signal)
      % Alokacja tablicy wynikowej (beda to szeregi zmiennych stanu ukladu)
      n = length(Signal.time);
      StateArray = zeros(3, n);

      h = Signal.step;
      % Dla calego zadanego szeregu czasowego, ...
      for i = 1 : n -1
        % ... pobranie napiecia chwilowego, a takze wektora zmiennych stanu
        % dla biezacej chwili czasowej ...
        e = Signal.voltage(i);
        Y = StateArray(1 : 3, i);
        % ... i wyliczenie kolejnego stanu ukladu metoda Eulera
        % z uzyciem funkcji response zwracajacej wektor rozniczek dY
        StateArray(1 : 3, i +1) = calcEuler(@obj.response, Y, e, h);
      end
    end

    function [StateArray] = solveImprovedEuler(obj, Signal)
      % Alokacja tablicy wynikowej (beda to szeregi zmiennych stanu ukladu)
      n = length(Signal.time);
      StateArray = zeros(3, n);

      h = Signal.step;
      % Dla calego zadanego szeregu czasowego, ...
      for i = 1 : n -1
        % ... pobranie napiecia chwilowego i wektora zmiennych stanu ukladu
        % dla biezacej chwili czasowej ...
        e = Signal.voltage(i);
        Y = StateArray(1 : 3, i);
        % ... i wyliczenie kolejnego stanu ukladu metoda ulepszona Eulera
        % z uzyciem funkcji response zwracajacej wektor rozniczek dY
        StateArray(1 : 3, i +1) = calcImprovedEuler(@obj.response, Y, e, h);
      end
    end
  end % end of public methods

  
  methods (Access = private)
    function obj = update(obj)
      % Przeliczenie macierzy A
      obj.A = [ -obj.R1 / obj.M,   obj.R2 / obj.L2,  -1 / obj.M
                -obj.R1 / obj.L1,  obj.R2 / obj.M,   -1 / obj.L1
                      1 / obj.C,          0,            0 ];
      D1 = (obj.L1 / obj.M) - (obj.M / obj.L2);
      D2 = (obj.M / obj.L1) - (obj.L2 / obj.M);
      obj.A(1,:) = obj.A(1,:) / D1;
      obj.A(2,:) = obj.A(2,:) / D2;
      % Przeliczenie wektora V
      obj.V = [1 / obj.M  / D1
               1 / obj.L1 / D2
               0];
    end

    function dY = response(obj, Y, e)
      % Jesli indukcyjnosc wzajemna jest wielkoscia stala, to ...
      if (~ obj.Trafo.variableInductance)
        % ... o ile jeszcze nie obliczano modelu z tym transformatorem ...
        if (obj.M ~= obj.Trafo.M)
            obj.M = obj.Trafo.M;
            % ... jednokrotne obliczenie elementow macierzy A i wektora V
            obj = update(obj);
        end
      else
      % W przeciwnym razie, gdy indukcyjnosc wzajemna jest zmienna
      % (tzn. zalezna od uL na uzwojeniu pierwotnym transformatora), to ...
        % ... wyliczenie biezacego napiecia uL
        uL = e - obj.R1 * Y(1) - Y(3);
        % ... przeliczenie indukcyjnosci wzajemnej dla uL
        obj.M = obj.Trafo.MutualInductance(uL);
        % ... i zaktualizowanie ukladu rownan (tj. macierzy A i wektora V)
        % dla nowej wartosci M 
        obj = update(obj);
      end
      % Wyliczenie odpowiedzi ukladu w postaci wektora rozniczek 
      % dla wszystkich zmiennych stanu
      dY = (obj.A * Y) + (obj.V * e);
    end
  end % end of private methods
end % end of classdef


% *** Funkcje numeryczne **

function Yn = calcEuler(dY, Y, e, h)
  % Obliczenie wektora rozniczek za pomoca funkcji dY,
  % a nastepnie wyliczenie nowego wektora zmiennych stanu
  % stosujac formule Eulera
  Yn = Y + h * dY(Y, e);
end

function Yn = calcImprovedEuler(dY, Y, e, h)
  % Obliczenie wektora rozniczek (wewn. i zewn.) za pomoca funkcji dY,
  % a nastepnie wyliczenie nowego wektora zmiennych stanu
  % stosujac formule ulepszona Eulera
  Yn = Y + h * dY(Y + h/2 * dY(Y, e), e);
end
