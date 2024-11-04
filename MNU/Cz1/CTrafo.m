
classdef CTrafo
  properties
    smoothing;           % metoda wygladzania charakterystyki M = f(|uL|)
  end
  properties (SetAccess = private, GetAccess = public)
    M;                   % indukcyjnosc wzajemna [H] (skalar lub tablica)
    variableInductance;  % wartosc logiczna czy indukcyjnosc jest zmienna
    smoothingMethod;     % slownik nazw metod wygladzania charakterystyki
  end
  properties (SetAccess = private, GetAccess = private)
    s3Knots = [];        % tablica wezlow interpolacji funkcji sklejanej
    s3Coeffs = [];       % wektor wspolczynnikow dla funkcji sklejanej
    s3Alpha, s3Beta;     % parametry graniczne dla funkcji sklejanej
  end


  methods
    % Konstruktor
    function obj = CTrafo(MI)
      % Utworzenie slownika z nazwami metod wygladzania charakterystyki
      obj.smoothingMethod = containers.Map( ...
        {'Lagrange', ...
         'Polyline', ...
         'Spline', ...
         '3degPolynomial', ...
         '5degPolynomial'}, ...
         [1 2 3 4 5]);

      % Ustawienie indukcyjnosci wzajemnej ...
      obj.M = MI;
      % ... oraz domyslnych parametrow kontrolnych ...
      if isscalar(MI)
        % ... gdy indukcyjnosc jest wielkoscia skalarna, ...
        obj.variableInductance = false;
        obj.smoothing = '';
        return;
      end

      % Gdy indukcyjnosc okresla charakterystyka M = f(|uL|), to: ...
      % ... ustawienie parametrow 
      obj.variableInductance = true;
      obj.smoothing = obj.smoothingMethod('Lagrange');
      % ... jednokrotne obliczenie parametrow splajnu
      if isempty(obj.s3Knots)
        obj.s3Knots = splineKnots(MI(1, :), MI(2, :), 6);
        obj.s3Beta = 1 / 2048;
        obj.s3Alpha = 13 / 2048;
        obj.s3Coeffs = splineCoeffs(obj.s3Knots, obj.s3Alpha, obj.s3Beta);
      end
      % UWAGA Przy pierwszym wyliczeniu nastepuje jednorazowe obliczenie
      %       wspolrzednych wezlow interpolacji i wektora wspolczynnikow. 
      %       Wektory te zostaja zapisane w polach obiektu, by w trakcie
      %       kolejnych wyliczen korzystac z gotowych wartosci co znacznie
      %       ogranicza zakres obliczen.
    end


    function m = MutualInductance(obj, uL)
      % Jesli indukcyjnosc wzajemna jest stala ...
      if (~ obj.variableInductance)
        % ... zwrocenie wielkosci skalarnej
        m = obj.M;
        return;
      end
      % ... w przeciwnym razie zaklada sie, ze indukcyjnosc wzajemna
      % okresla charakterystyka w postaci tablicy liczb

      % Pobranie punktow charakterystyki - wspolrzedne U, M jako wektory
      vecU = obj.M(1,:);
      vecM = obj.M(2,:);

      % Sciecie wartosci uL przekraczajacych zakres na charakterystyce
      uL = abs(uL);
      if (uL > vecU(end))
          uL = vecU(end);
      end

      % Wyliczenie wartosci M = f(|uL|) z uzyciem zadanej metody
      % interpolacyjnej/aproksymacyjnej, tj.: ...
      switch (obj.smoothing)
        case 1
          % - interpolacja wielomianem Lagrange'a
          m = LagrangePolynomial(uL, vecU, vecM);
        case 2
          % - interpolacja funkcjami sklejanymi 1. stopnia
          m = Polyline(uL, vecU, vecM);
        case 3
          % - interpolacja funkcjami sklejanymi 3. stopnia
          m = Spline(obj.s3Knots, obj.s3Coeffs, uL);
        case 4
          % - aproksymacja wielomianem 3. stopnia
          m = PolynomialApprox(3, uL, vecU, vecM);
        case 5
          % - aproksymacja wielomianem 5. stopnia
          m = PolynomialApprox(5, uL, vecU, vecM);
        otherwise
          m = Polyline(abs(uL), vecU, vecM);
      end
    end
  end % end of methods
end % end of classdef


% *** Funkcje numeryczne ***

% Funkcja interpolujaca wielomianem Lagrange'a
function y = LagrangePolynomial(x, X, Y)
  n = length(X);
  sum = 0.0;  
  for i = 1 : n
    prod = 1.0;
    for j = 1 : n
      if (j ~= i)
        prod = prod * (x - X(j)) / (X(i) - X(j));
      end
    end
    sum = sum + Y(i) * prod;
  end
  y = sum;
end


% Funkcja aproksymujaca wielomianem stopnia deg = {1, 2, ... 5}
function y = PolynomialApprox(deg, x, X, Y)
  % Zbudowanie macierzy funkcji bazowych (liczba kolumn o jeden wiecej 
  % niz stopien wielomianu, liczba wierszy - tyle ile niewiadomych X)
  M = ones(length(X), 1+ deg);
  for d = 1 : deg
    M(:, 1+ d) = X'.^d;
  end
  % Obliczenie wspolczynnikow algebraicznego wielomianu aproksymacyjnego
  warning('off');
  A = (M' * M) \ (M' * Y');
  warning('on');

  % Wyliczenie wartosci wielomianu dla zadanego argumentu
  y = A(1);
  for d = 1 : deg
    y = y + A(1+ d) * x^d;
  end
end


% Funkcja interpolujaca odcinkami prostymi (funkcja sklejana 1. stopnia)
function y = Polyline(x, X, Y)
  j = 2;
  % Okreslenie indeksu wezla sasiadujacego po prawo
  % (tj. wezla o wspolrz. x wiekszej niz zadany argument) ...
  while (x > X(j) && j < length(X))
    j = j +1;
  end
  % ... oraz indeksu wezla sasiadujacego po lewo
  i = j;
  if (x ~= X(j))
    i = j -1;
  end
  % UWAGA Jesli podany argument znajduje sie na lewo od pierwszego wezla
  %       lub na prawo od ostatniego wezla, to dwa wyzej wybrane wezly
  %       posluza w dalszych obliczeniach do ekstrapolacji liniowej!

  if (i < j)
    % Gdy wybrano dwa rozne wezly, wyliczenie wartosci interpolowanej
    % (lub ekstrapolowanej) z prostej zaleznosci liniowej, ...
    a = (Y(j) - Y(i)) / (X(j) - X(i));
    y = Y(i) + a * (x - X(i));
  else
   % ... a jesli argument lezy dokladnie w wezle, to po prostu zwrocenie 
   % odpowiedniej wspolrz. y
   y = Y(i);
  end
end


function y = Spline(K, C, x)
  % Wyliczenie wartosci funkcji bazowych dla zadanego argumentu
  % i umieszczenie wynikow w wektorze wierszowym
  k = length(K);
  Phi = zeros(1, k +2);
  for i = 1 : k +2
    Phi(i) = splinePhi(K, i -2, x);
  end
  % Obliczenie wartosci funkcji sklejanej dla zadanego argumentu,
  % jako iloczyn wektorowy wspolczynnikow i wartosci funkcji bazowych
  y = Phi * C;
end

function f = splinePhi(K, i, x)
  % Ustalenie ilosci wezlow i szerokosci przedzialow
  % na podstawie zadanej tablicy rownoodleglych wezlow interpolacji
  k = length(K);
  h = K(1, 2) - K(1, 1);
  % Dozwolony indeks funkcji bazowej i = [-1; k]
  if (i < -1) || (k < i)
    return
  end
  % Pseudowektor, ktory biorac wspolrz. x pierwszego z rownoodleglych
  % wezlow interpolacji wylicza wspolrz. x dla i-tego wezla, przy czym 
  % indeksy zaczynaja sie od 0
  X = @(i) (K(1, 1) + (i * h));

  % Wybor odpowiedniej formuly i wyliczenie wartosci funkcji bazowej
  if (x < X(i -2) || X(i +2) < x)
    f = 0;    
  elseif (X(i -2) <= x && x <= X(i -1))
    f = ((x - X(i -2))^3) / h^3;
  elseif (X(i -1) <= x && x <= X(i))    
    f = ((x - X(i -2))^3 - 4 * (x - X(i -1))^3) / h^3;
  elseif (X(i) <= x && x <= X(i +1))
    f = ((X(i +2) - x)^3 - 4 * (X(i +1) - x)^3) / h^3;
  elseif (X(i +1) <= x && x <= X(i +2))
    f = ((X(i +2) - x)^3) / h^3;
  end
end

function [C] = splineCoeffs(K, alpha, beta)
  % Ustalenie ilosci wezlow i szerokosci przedzialow
  % na podstawie zadanej tablicy rownoodleglych wezlow interpolacji
  k = length(K);
  h = K(1, 2) - K(1, 1);

  % Utworzenie kolumnowego wektora wyrazow wolnych w ukladzie rownan
  W = K(2, :)';
  W(1) = W(1) + alpha * h / 3;
  W(k) = W(k) - beta * h / 3;
  % Utworzenie macierzy wspolczynnikow
  S = eye(k) * 4;
  for i = 2 : k
    S(i -1, i) = 1;
    S(i, i -1) = 1;
  end
  S(1, 1 +1) = 2;
  S(k, k -1) = 2;
  % Rozwiazanie ukladu rownan, tj. obliczenie wektora wspolczynnikow c
  C = S \ W;
  C = [C;  C(k -1) + beta * h / 3];
  C = [    C(1 +1) - alpha * h / 3;  C];
end

function [K] = splineKnots(X, Y, k)
  % Ustalenie ilosci i szerokosci przedzialow na podstawie zadanej liczby k
  % rownoodleglych wezlow interpolacji
  n = k -1;
  h = (X(end) - X(1)) / n;

  % Utworzenie tablicy ze wspolrzednymi rownoodleglych wezlow interpolacji
  % takich, ze leza na krzywej interpolujacej metoda Lagrange'a zadane X,Y
  K = zeros(2, k);
  K(1, :) = X(1) : h : X(end);
  for i = 1 : k
    K(2, i) = LagrangePolynomial(K(1, i), X, Y);
  end
end
