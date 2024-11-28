function facial_login_system
    % Sistema de login con reconocimiento facial en MATLAB

    % Crear carpeta para usuarios registrados si no existe
    folder = 'registered_faces';
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    % Crear carpeta para finanzas si no existe
    financesFolder = 'finances';
    if ~exist(financesFolder, 'dir')
        mkdir(financesFolder);
    end

    % Inicializar la cámara
    cam = webcam;

    % Crear un detector de rostros
    faceDetector = vision.CascadeObjectDetector();

    % Ventana principal
    while true
        choice = menu('Facial Login System', ...
            'Iniciar Sesión', ...
            'Registrar Usuario', ...
            'Salir');

        switch choice
            case 1
                vistaPrevia(cam); % Mostrar vista previa con confirmación por Enter
                recognizedName = iniciarSesion(cam, faceDetector, folder);  % Capturamos recognizedName
                if ~isempty(recognizedName)  % Verificamos que se haya reconocido un usuario
                    mensajeBienvenida(recognizedName);  % Mensaje personalizado con el nombre del usuario
                    close(gcf); % Cerrar la ventana de login al iniciar sesión
                    % Solo abrir ventana de finanzas si no está abierta
                    ventanaFinanzas(cam, recognizedName); % Pasamos recognizedName
                else
                    disp('No se ha reconocido al usuario.');
                end
            case 2
                vistaPrevia(cam); % Mostrar vista previa con confirmación por Enter
                registrarUsuario(cam, faceDetector, folder);
            case 3
                break;
        end
    end

    % Liberar la cámara
    clear cam;
end

%% Función para mostrar un mensaje de bienvenida con el nombre del usuario
function mensajeBienvenida(userName)
    % Mensaje breve antes de abrir la gestión de finanzas
    f = msgbox(['Bienvenido al sistema de Gestión de Finanzas, ', userName, '.'], 'Bienvenida');
    pause(2); % Pausa para mostrar el mensaje durante 2 segundos
    if isvalid(f)
        close(f);
    end
end

%% Función para vista previa en tiempo real con confirmación por Enter
%% Función para vista previa en tiempo real con confirmación por Enter
function vistaPrevia(cam)
    % Mostrar un mensaje informativo antes de iniciar la vista previa
    f = msgbox('Ajuste su posición frente a la cámara y presione Enter para capturar su imagen.', 'Informacion');
    pause(4); % Pausar 2 segundos
    close(f); % Cerrar el cuadro de mensaje

    % Ahora iniciar la vista previa de la cámara
    f = figure('Name', 'Vista Previa - Ajuste su posición', 'NumberTitle', 'off');
    try
        while isvalid(f)
            % Captura una imagen de la cámara
            img = snapshot(cam);
            
            % Muestra la imagen si la figura sigue siendo válida
            if isvalid(f)
                imshow(img);
                title('Ajuste su posición y presione Enter para continuar.');
                drawnow;
            else
                break; % Si la figura ya no es válida, se detiene el ciclo
            end

            % Confirmar con Enter
            k = waitforbuttonpress;
            if k == 1
                break;
            end
        end
    catch ME
        disp('Vista previa cancelada.');
        disp(ME.message);
    end
    
    % Cerrar la figura si es válida
    if isvalid(f)
        close(f);
    end
end



%% Función para registrar un nuevo usuario
function registrarUsuario(cam, faceDetector, folder)
    prompt = {'Ingrese su nombre de usuario:'};
    dlgTitle = 'Registro de Usuario';
    dims = [1 35];
    userName = inputdlg(prompt, dlgTitle, dims);

    if isempty(userName)
        disp('Registro cancelado.');
        return;
    end

    userName = userName{1};
    userFile = fullfile(folder, [userName, '.jpg']);
    
    if exist(userFile, 'file')
        msgbox('El usuario ya está registrado.', 'Error', 'error');
        return;
    end

    % Mostrar advertencia antes de la captura
    f = msgbox('Ajuste su posición frente a la cámara y presione Enter para registrar su rostro.', 'Información');
    pause(4); % Pausar 4 segundos para que el usuario se acomode
    close(f); % Cerrar el cuadro de mensaje

    % Capturar imagen para registrar
    f = figure('Name', 'Registro - Capture su imagen', 'NumberTitle', 'off');
    try
        while isvalid(f)
            img = snapshot(cam);
            imshow(img);
            title('Presione Enter para capturar o cierre la ventana para cancelar.');
            drawnow;

            % Capturar imagen al presionar Enter
            k = waitforbuttonpress;
            if k == 1
                break;
            end
        end
        if ~isvalid(f)
            disp('Registro cancelado.');
            return;
        end
        close(f);

        % Detectar rostro
        bbox = step(faceDetector, img);
        if ~isempty(bbox)
            % Extraer y guardar el rostro
            faceImg = imcrop(img, bbox(1, :));
            faceImg = imresize(faceImg, [150, 150]);
            imwrite(faceImg, userFile);
            msgbox('Usuario registrado con éxito.', 'Éxito');
        else
            msgbox('No se detectó ningún rostro. Intente de nuevo.', 'Error', 'error');
        end
    catch
        disp('Registro cancelado.');
    end
end


% Función para iniciar sesión
function recognizedName = iniciarSesion(cam, faceDetector, folder)
    recognizedName = ''; % Inicializar como vacío

    % Leer usuarios registrados
    files = dir(fullfile(folder, '*.jpg'));
    if isempty(files)
        msgbox('No hay usuarios registrados. Regístrese primero.', 'Error', 'error');
        return;
    end

    % Cargar los rostros registrados
    registeredFaces = struct();
    for k = 1:length(files)
        img = imread(fullfile(folder, files(k).name));
        imgGray = rgb2gray(img);
        userName = erase(files(k).name, '.jpg');
        registeredFaces(k).Name = userName;
        registeredFaces(k).Image = imgGray;
    end

    % Capturar imagen para iniciar sesión
    f = figure('Name', 'Iniciar Sesión - Capture su imagen', 'NumberTitle', 'off');
    try
        while isvalid(f)
            img = snapshot(cam);
            imshow(img);
            title('Presione Enter para capturar o cierre la ventana para cancelar.');
            drawnow;

            % Capturar imagen al presionar Enter
            k = waitforbuttonpress;
            if k == 1
                break;
            end
        end
        if ~isvalid(f)
            disp('Inicio de sesión cancelado.');
            return;
        end
        close(f);

        % Detectar rostro
        bbox = step(faceDetector, img);
        if isempty(bbox)
            msgbox('No se detectó ningún rostro. Intente de nuevo.', 'Error', 'error');
            return;
        end

        % Extraer el rostro detectado
        faceImg = imcrop(img, bbox(1, :));
        faceImgGray = rgb2gray(imresize(faceImg, [150, 150]));

        % Reconocer usuario
        recognizedName = recognizeUser(faceImgGray, registeredFaces);

        if isempty(recognizedName)
            msgbox('No se reconoció el rostro. Intente registrarse si es necesario.', 'Error', 'error');
        end
    catch
        disp('Inicio de sesión cancelado.');
    end
end

%% Función para reconocer al usuario
function recognizedName = recognizeUser(faceImgGray, registeredFaces)
    minDistance = inf;
    recognizedName = '';

    % Comparar con cada usuario registrado
    for k = 1:length(registeredFaces)
        registeredImgGray = registeredFaces(k).Image;

        % Extraer características
        points1 = detectSURFFeatures(faceImgGray);
        points2 = detectSURFFeatures(registeredImgGray);
        [features1, validPoints1] = extractFeatures(faceImgGray, points1);
        [features2, validPoints2] = extractFeatures(registeredImgGray, points2);

        % Comparar las características
        indexPairs = matchFeatures(features1, features2);
        matchedPoints1 = validPoints1(indexPairs(:, 1));
        matchedPoints2 = validPoints2(indexPairs(:, 2));

        % Calcular la distancia
        distance = sum(vecnorm(matchedPoints1.Location - matchedPoints2.Location, 2, 2));
        if distance < minDistance
            minDistance = distance;
            recognizedName = registeredFaces(k).Name;
        end
    end

    % Umbral para determinar si hay coincidencia
    if minDistance > 1000
        recognizedName = ''; % No reconocido si la distancia es alta
    end
end

% Función para la ventana de finanzas
function ventanaFinanzas(cam, userName)
    f = figure('Name', 'Gestión de Finanzas', 'NumberTitle', 'off', 'Position', [100, 100, 600, 400]);

    % Crear tabla para mostrar los ingresos y gastos
    uit = uitable('Parent', f, 'Position', [50, 100, 500, 200], ...
        'ColumnName', {'Fecha', 'Descripción', 'Tipo', 'Monto'}, ...
        'ColumnEditable', false(1, 4), ...
        'Data', {}); % Inicialmente vacío

    % Botones de opciones
    uicontrol('Style', 'pushbutton', 'Position', [50, 50, 100, 40], ...
        'String', 'Añadir Ingreso', 'Callback', @(src, event) agregarFinanzas(userName, 'Ingreso', uit));

    uicontrol('Style', 'pushbutton', 'Position', [200, 50, 100, 40], ...
        'String', 'Añadir Gasto', 'Callback', @(src, event) agregarFinanzas(userName, 'Gasto', uit));

    uicontrol('Style', 'pushbutton', 'Position', [350, 50, 100, 40], ...
        'String', 'Cerrar sesión', 'Callback', @(src, event) close(f));
    
    % Cargar los datos de finanzas desde un archivo
    userFile = fullfile('finances', [userName, '.csv']);
    if exist(userFile, 'file')
        data = readtable(userFile);
        uit.Data = table2cell(data); % Actualizar tabla
    end
end

%% Función para agregar un ingreso o gasto
function agregarFinanzas(userName, tipo, uit)
    % Obtener la fecha actual
    fecha = datestr(now, 'dd-mm-yyyy');
    
    % Solicitar los datos del ingreso/gasto
    prompt = {'Descripción', 'Monto'};
    dlgTitle = ['Añadir ', tipo];
    dims = [1 35];
    data = inputdlg(prompt, dlgTitle, dims);
    if isempty(data)
        return; % Si se cancela el diálogo, no hacer nada
    end
    descripcion = data{1};
    monto = str2double(data{2});

    % Guardar en el archivo CSV
    userFile = fullfile('finances', [userName, '.csv']);
    if exist(userFile, 'file')
        t = readtable(userFile);
    else
        t = table();
    end

    % Añadir nueva fila
    nuevaFila = {fecha, descripcion, tipo, monto};
    t = [t; nuevaFila];

    % Guardar los datos actualizados
    writetable(t, userFile);

    % Actualizar la tabla en la interfaz gráfica
    uit.Data = table2cell(t);
end
