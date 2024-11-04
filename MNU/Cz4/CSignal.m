
classdef CSignal
  properties (SetAccess = private, GetAccess = public)
    sig;      % ksztalt sygnalu (sinusoida, prostokat, ..., albo staly)
    u;        % napiecie [V]
    T;        % okres [s]
    f;        % czestotliwosc [Hz]
    step;     % optymalnie dobrany krok czasowy [s]
    time;     % wektor chwil czasowych
    voltage;  % wektor napiec chwilowych
  end


  methods
    % Konstruktor
    function obj = CSignal(timespan, sig, u, T, density)
      % Utworzenie slownika z nazwami gestosci probkowania
      selected = containers.Map({'dense', 'normal', 'light'}, ...
          [512, 128, 32]);
      % Znormalizowanie gestosci gdy nie podano prawidlowo tego parametru
      if (~isKey(selected, density))
         density = 'normal';
      end

      % Ustawienie zadanych wartosci w polach obiektu
      obj.sig = sig;
      obj.u = u;
      obj.T = T;
      obj.f = 1 / T;
      obj.step = 1 / selected(density);

      % Wygenerowanie szeregu czasowego napiec chwilowych ...
      % ... dla sygnalu sinusoidalnego
      if (strcmp(sig, 'sine'))
        % Utworzenie wektora chwil czasowych z optymalnie dobranym krokiem
        obj.step = T * obj.step;
        obj.time = 0 : obj.step : timespan;
        obj.voltage = u * sin((2*pi / T) * obj.time);  % omega = 2*pi / T
        return;
      end
      % ... dla sygnalu prostokatnego
      if (strcmp(sig, 'sqre'))
        obj.step = T * obj.step;
        obj.time = 0 : obj.step : timespan;
        obj.voltage = u * (1 -round(mod(obj.time, T)/T, 0));
        return;
      end
      % ... dla sygnalu stalego - jako opcja defaultowa
      obj.time = 0 : obj.step : timespan;
      obj.voltage = u * ones(1, length(obj.time));
    end


    function s = caption(obj)
      % Zwrocenie slownego opisu ...
      if (obj.f > 0)
        % ... dla sygnalow periodycznych
        s = compose("%s %d V, T = %.6G s, (f = %.6G Hz)", ...
            obj.sig, obj.u, obj.T, obj.f);
      else
        % ... dla sygnalu stalego
        s = obj.sig + " " + obj.u + " V";
      end
    end
  end % end of methods
end % end of classdef